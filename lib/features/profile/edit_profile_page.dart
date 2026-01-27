// lib/features/profile/edit_profile_page.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '/core/services/cloudinary_service.dart';

class EditProfilePage extends StatefulWidget {
  final String userId;

  const EditProfilePage({super.key, required this.userId});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  bool isUploading = false;

  String imageUrl = "";
  String displayName = "";
  String email = "";

  bool get isOwner => widget.userId == currentUser?.uid;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    if (widget.userId.isEmpty) return;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.userId)
        .get();

    if (!mounted) return;

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        displayName = data["name"] ?? "";
        imageUrl = data["image"] ?? "";
        email = data["email"] ?? currentUser?.email ?? "";
      });
    } else if (isOwner && currentUser != null) {
      final newData = {
        "name": currentUser!.displayName ?? "",
        "email": currentUser!.email ?? "",
        "image": "",
      };
      await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.userId)
          .set(newData);

      if (!mounted) return;

      setState(() {
        displayName = newData["name"]!;
        email = newData["email"]!;
        imageUrl = "";
      });
    }
  }

  Future<void> pickImage() async {
    if (!isOwner || isUploading) return;

    final picker = ImagePicker();
    final XFile? picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);

    if (picked == null) return;

    setState(() => isUploading = true);

    try {
      final file = File(picked.path);
      final url = await CloudinaryService().uploadFile(
        file,
        folder: "profiles",
        preset: "lockalista",
      );

      if (!mounted) return;

      if (url == null) throw Exception("Upload returned null URL");

      await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.userId)
          .set({"image": url}, SetOptions(merge: true));

      setState(() => imageUrl = url);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to upload image")),
      );
    } finally {
      if (mounted) setState(() => isUploading = false);
    }
  }

  Future<void> editName() async {
    if (!isOwner) return;

    final controller = TextEditingController(text: displayName);

    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Name"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text("Save"),
          ),
        ],
      ),
    );

    controller.dispose();

    if (result == null || result.isEmpty) return;

    await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.userId)
        .update({"name": result});

    if (!mounted) return;
    setState(() => displayName = result);
  }

  Future<void> changePassword() async {
    if (!isOwner || currentUser == null) return;

    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
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
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Save"),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      oldCtrl.dispose();
      newCtrl.dispose();
      return;
    }

    try {
      final cred = EmailAuthProvider.credential(
        email: currentUser!.email!,
        password: oldCtrl.text,
      );

      await currentUser!.reauthenticateWithCredential(cred);
      await currentUser!.updatePassword(newCtrl.text);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password updated successfully")),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update password")),
      );
    } finally {
      oldCtrl.dispose();
      newCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
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
                            backgroundImage: imageUrl.isNotEmpty
                                ? CachedNetworkImageProvider(imageUrl)
                                : null,
                            child: imageUrl.isEmpty
                                ? const Icon(Icons.person, size: 60)
                                : null,
                          ),
                          if (isUploading)
                            const CircularProgressIndicator(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      displayName,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: editName,
                      icon: const Icon(Icons.edit),
                      label: const Text("Edit Name"),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: changePassword,
                      icon: const Icon(Icons.lock),
                      label: const Text("Change Password"),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
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
