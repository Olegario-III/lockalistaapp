import 'package:flutter/material.dart'; // for BuildContext, ScaffoldMessenger, SnackBar, Text
import 'package:geolocator/geolocator.dart';
import 'package:lockalista/features/stores/pick_location_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // for GeoPoint

class Helpers {
  static Future<Position> getCurrentLocation() async {
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  static Future<GeoPoint?> pickLocationOnMap(BuildContext context) async {
  return await Navigator.push<GeoPoint>(
    context,
    MaterialPageRoute(builder: (_) => const PickLocationPage()),
  );
}

  static void openMap(double lat, double lng) {
    final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    launchUrl(url);
  }

  static String currentUserId() => FirebaseAuth.instance.currentUser!.uid;

  static bool isAdmin() {
    // TODO: check if current user is admin
    return false;
  }

  static void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
