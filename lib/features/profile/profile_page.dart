// lib/features/profile/profile_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? user = FirebaseAuth.instance.currentUser;

  bool isDarkMode = true;
  String imageUrl = "";
  String displayName = "";

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .get();

    if (!mounted) return;

    setState(() {
      displayName = doc.data()?["name"] ?? user!.email!.split('@')[0];
      imageUrl = doc.data()?["image"] ?? "";
    });
  }

  // ─────────────────────────────────────────────
  // 🔥 PICK & UPLOAD IMAGE
  // ─────────────────────────────────────────────
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);

    if (file == null) return;

    final ref = FirebaseStorage.instance
        .ref()
        .child("profileImages")
        .child("${user!.uid}.jpg");

    await ref.putFile(File(file.path));
    final newUrl = await ref.getDownloadURL();

    await FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .update({"image": newUrl});

    if (!mounted) return;
    setState(() => imageUrl = newUrl);
  }

  // ─────────────────────────────────────────────
  // ✏️ EDIT PROFILE (name & email)
  // ─────────────────────────────────────────────
  void editProfile() {
    TextEditingController nameCtrl = TextEditingController(text: displayName);
    TextEditingController emailCtrl = TextEditingController(text: user!.email);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text("Edit Profile", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Name",
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: emailCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Email",
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection("users")
                  .doc(user!.uid)
                  .update({"name": nameCtrl.text});

              if (!mounted) return;
              setState(() => displayName = nameCtrl.text);

              // Email update using recommended method
              try {
                await user!.verifyBeforeUpdateEmail(emailCtrl.text);
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Email update failed: $e')));
              }

              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // 🔐 CHANGE PASSWORD
  // ─────────────────────────────────────────────
  void changePassword() {
    TextEditingController passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text("Change Password",
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: passCtrl,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: "New Password",
            labelStyle: TextStyle(color: Colors.white70),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              await user!.updatePassword(passCtrl.text);
              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // 🌓 THEME TOGGLE
  // ─────────────────────────────────────────────
  void toggleTheme() {
    if (!mounted) return;
    setState(() => isDarkMode = !isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey.shade800,
                backgroundImage:
                    imageUrl.isNotEmpty ? CachedNetworkImageProvider(imageUrl) : null,
                child: imageUrl.isEmpty
                    ? const Icon(Icons.person, size: 60, color: Colors.white)
                    : null,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              displayName,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              user?.email ?? "",
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black54,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 30),

            menuItem(Icons.edit, "Edit Profile", editProfile),
            menuItem(Icons.lock, "Change Password", changePassword),
            menuItem(Icons.brightness_6, "Toggle Theme", toggleTheme),
            menuItem(Icons.logout, "Logout", () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              // ignore: use_build_context_synchronously
              Navigator.pushNamedAndRemoveUntil(context, "/login", (_) => false);
            }),

            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget menuItem(IconData icon, String text, VoidCallback onTap) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          leading: Icon(icon, color: isDarkMode ? Colors.white : Colors.black),
          title: Text(
            text,
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          trailing: Icon(Icons.arrow_forward_ios,
              color: isDarkMode ? Colors.white : Colors.black, size: 16),
        ),
        Divider(
            color: isDarkMode ? Colors.white24 : Colors.black12, height: 1)
      ],
    );
  }
}
