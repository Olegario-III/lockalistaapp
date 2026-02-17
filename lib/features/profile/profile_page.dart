import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '/features/profile/customer_service_page.dart';
import '/features/profile/edit_profile_page.dart';
import '/features/profile/profile_stores_list.dart';
import '/features/profile/profile_events_list.dart';
import '/features/profile/verification_form_page.dart';
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
  String role = "";

  bool hasPendingVerification = false;
  bool hasStore = false;
  Timestamp? rejectedAt;

  bool get isOwner => widget.userId == currentUser?.uid;
  bool get isVerifiedOwner => role == "owner";

  bool get isOnCooldown {
    if (rejectedAt == null) return false;
    final rejectedDate = rejectedAt!.toDate();
    return DateTime.now()
        .isBefore(rejectedDate.add(const Duration(days: 7)));
  }

  Duration get cooldownRemaining {
    final rejectedDate = rejectedAt!.toDate();
    return rejectedDate
        .add(const Duration(days: 7))
        .difference(DateTime.now());
  }

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    if (widget.userId.isEmpty) return;

    /// ---------- USER ----------
    final userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.userId)
        .get();

    if (!mounted) return;

    if (userDoc.exists) {
      final data = userDoc.data()!;
      displayName = data["name"] ?? "";
      imageUrl = data["image"] ?? "";
      email = data["email"] ?? currentUser?.email ?? "";
      role = data["role"] ?? "";
      rejectedAt = data["rejectedAt"];
    } else if (isOwner && currentUser != null) {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.userId)
          .set({
        "name": currentUser!.displayName ?? "",
        "email": currentUser!.email ?? "",
        "image": "",
        "role": "",
      });

      displayName = currentUser!.displayName ?? "";
      email = currentUser!.email ?? "";
      imageUrl = "";
      role = "";
    }

    /// ---------- STORE CHECK ----------
    final storeSnap = await FirebaseFirestore.instance
        .collection("stores")
        .where("ownerId", isEqualTo: widget.userId)
        .limit(1)
        .get();

    hasStore = storeSnap.docs.isNotEmpty;

    /// ---------- VERIFICATION REQUEST ----------
    final verSnap = await FirebaseFirestore.instance
        .collection("verification_requests")
        .where("userId", isEqualTo: widget.userId)
        .where("status", isEqualTo: "pending")
        .limit(1)
        .get();

    hasPendingVerification = verSnap.docs.isNotEmpty;

    if (!mounted) return;
    setState(() {});
  }

  String _formatDuration(Duration d) {
    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;

    if (days > 0) return '${days}d ${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  /// ---------------- LOGOUT ----------------
  void logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.watch<ThemeNotifier>();
    final isDarkMode = themeNotifier.isDarkMode;

    final bool canVerify = isOwner &&
        role != 'admin' &&
        !isVerifiedOwner &&
        hasStore &&
        !hasPendingVerification &&
        !isOnCooldown;

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
            children: [
              /// ---------------- PROFILE CARD ----------------
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
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
                      Text(email),
                      const SizedBox(height: 24),

                      if (isOwner) ...[
                        /// EDIT PROFILE
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

                        const SizedBox(height: 12),

                        /// VERIFY BUTTON
                        ElevatedButton.icon(
                          icon: const Icon(Icons.verified),
                          label: Text(
                            isVerifiedOwner
                                ? "Verified Owner"
                                : hasPendingVerification
                                    ? "Pending Verification"
                                    : !hasStore
                                        ? "Add a Store to Verify"
                                        : isOnCooldown
                                            ? "Cooldown Active"
                                            : "Verify Account",
                          ),
                          onPressed: canVerify
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => VerificationFormPage(
                                        userId: widget.userId,
                                      ),
                                    ),
                                  ).then((_) => loadProfile());
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                            backgroundColor:
                                isVerifiedOwner ? Colors.green : null,
                          ),
                        ),

                        if (isOnCooldown)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'You can request again in ${_formatDuration(cooldownRemaining)}',
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 13,
                              ),
                            ),
                          ),

                        const SizedBox(height: 12),

                        /// ✅ CUSTOMER SERVICE BUTTON
                        ElevatedButton.icon(
                          icon: const Icon(Icons.support_agent),
                          label: const Text("Customer Service"),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const CustomerServicePage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize:
                                const Size(double.infinity, 48),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              /// ---------------- STORES ----------------
              ProfileStoresList(userId: widget.userId),

              const SizedBox(height: 24),

              /// ---------------- EVENTS ----------------
              ProfileEventsList(userId: widget.userId),
            ],
          ),
        ),
      ),
    );
  }
}
