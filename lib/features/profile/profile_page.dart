import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '/core/services/cloudinary_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? user = FirebaseAuth.instance.currentUser;

  bool isDarkMode = true;
  bool isUploading = false;

  String imageUrl = "";
  String displayName = "";
  String email = "";

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection("users").doc(user!.uid).get();

    if (!mounted) return;

    if (doc.exists) {
      setState(() {
        displayName = doc.data()?["name"] ?? "";
        imageUrl = doc.data()?["image"] ?? "";
        email = doc.data()?["email"] ?? user!.email ?? "";
      });
    } else {
      await FirebaseFirestore.instance.collection("users").doc(user!.uid).set({
        "name": user!.displayName ?? "",
        "email": user!.email ?? "",
        "image": "",
      });
      setState(() {
        displayName = user!.displayName ?? "";
        email = user!.email ?? "";
        imageUrl = "";
      });
    }
  }

  Future<void> pickImage() async {
    if (isUploading || user == null) return;

    final picker = ImagePicker();
    final XFile? picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);

    if (picked == null) return;

    setState(() => isUploading = true);
    final file = File(picked.path);

    final url = await CloudinaryService().uploadFile(
      file,
      folder: "profiles",
      preset: "lockalista",
    );

    if (url == null) {
      if (!mounted) return;
      setState(() => isUploading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Image upload failed")));
      return;
    }

    await FirebaseFirestore.instance.collection("users").doc(user!.uid).set({
      "name": displayName,
      "email": email,
      "image": url,
    }, SetOptions(merge: true));

    if (!mounted) return;
    setState(() {
      imageUrl = url;
      isUploading = false;
    });
  }

  void toggleDarkMode() => setState(() => isDarkMode = !isDarkMode);

  void logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> editName() async {
    final controller = TextEditingController(text: displayName);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Name"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Name"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text("Save")),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user!.uid)
          .update({"name": result.trim()});
      setState(() => displayName = result.trim());
    }
  }

  Future<void> changePassword() async {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Change Password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Current Password"),
            ),
            TextField(
              controller: newCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: "New Password"),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true), child: const Text("Save")),
        ],
      ),
    );

    if (result != true) return;

    try {
      final cred = EmailAuthProvider.credential(
          email: user!.email!, password: oldCtrl.text);
      await user!.reauthenticateWithCredential(cred);
      await user!.updatePassword(newCtrl.text);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Password updated")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update password: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.grey[100],
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
              icon: Icon(isDarkMode ? Icons.wb_sunny : Icons.nightlight_round),
              onPressed: toggleDarkMode),
          TextButton(
            onPressed: logout,
            child: Text(
              "LOGOUT",
              style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Card(
              color: isDarkMode ? Colors.grey[900] : Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: pickImage,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey.shade800,
                            backgroundImage: imageUrl.isNotEmpty
                                ? CachedNetworkImageProvider(imageUrl)
                                : null,
                            child: imageUrl.isEmpty
                                ? const Icon(Icons.person,
                                    size: 60, color: Colors.white)
                                : null,
                          ),
                          if (isUploading)
                            const CircularProgressIndicator(color: Colors.white),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      displayName,
                      style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.black54),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                        onPressed: editName,
                        icon: const Icon(Icons.edit),
                        label: const Text("Edit Name"),
                        style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48))),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                        onPressed: changePassword,
                        icon: const Icon(Icons.lock),
                        label: const Text("Change Password"),
                        style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48))),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
