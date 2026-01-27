// lib/features/profile/profile_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '/features/profile/edit_profile_page.dart';
import '/features/profile/profile_stores_list.dart';
import '/features/profile/profile_events_list.dart';
import '/core/utils/theme_notifier.dart';

class ProfilePage extends StatefulWidget {
  final String userId;

  const ProfilePage({super.key, required this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

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

  void logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.watch<ThemeNotifier>();
    final isDarkMode = themeNotifier.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.wb_sunny : Icons.nightlight_round),
            onPressed: themeNotifier.toggleTheme,
          ),
          if (isOwner)
            TextButton(
              onPressed: logout,
              child: const Text(
                "LOGOUT",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Info Card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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
                      if (isOwner)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.edit),
                          label: const Text("Edit Profile"),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    EditProfilePage(userId: widget.userId),
                              ),
                            );
                            loadProfile();
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // User Added Stores
              ProfileStoresList(userId: widget.userId),
              const SizedBox(height: 24),

              // User Posted Events
              ProfileEventsList(userId: widget.userId),
            ],
          ),
        ),
      ),
    );
  }
}
