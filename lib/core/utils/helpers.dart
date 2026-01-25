import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lockalista/features/stores/pick_location_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Helpers {
  /* ================= LOCATION ================= */

  static Future<Position> getCurrentLocation() async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  static Future<GeoPoint?> pickLocationOnMap(BuildContext context) async {
    return await Navigator.push<GeoPoint>(
      context,
      MaterialPageRoute(builder: (_) => const PickLocationPage()),
    );
  }

  static void openMap(double lat, double lng) {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    launchUrl(url, mode: LaunchMode.externalApplication);
  }

  /* ================= AUTH ================= */

  static String currentUserId() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    return user.uid;
  }

  /// ✅ ALWAYS RETURNS A SAFE NAME
  static String currentUserName() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!
        : 'Anonymous';
  }

  /// ✅ SAFE AVATAR (prevents file:/// crash)
  static String? currentUserAvatar() {
    final photo = FirebaseAuth.instance.currentUser?.photoURL;

    if (photo == null || photo.isEmpty) return null;
    if (!photo.startsWith('http')) return null;

    return photo;
  }

  /* ================= ROLES ================= */

  static bool isAdmin() {
    // 🔒 Placeholder (keep logic in Firestore rules)
    // users/{uid} { role: 'admin' }
    return false;
  }

  /* ================= UI ================= */

  static void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
