// lib/core/services/admin_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Approve event
  Future<void> approveEvent(String eventId) async {
    await _db.collection('events').doc(eventId).update({'approved': true});
  }

  // Approve store
  Future<void> approveStore(String storeId) async {
    await _db.collection('stores').doc(storeId).update({'approved': true});
  }

  // Delete reported account
  Future<void> deleteUser(String uid) async {
    await _db.collection('users').doc(uid).delete();
    // optional: also remove auth account with Firebase Admin SDK (requires backend)
  }

  // Send warning
  Future<void> sendWarning(String uid, String message) async {
    await _db.collection('users').doc(uid).collection('warnings').add({
      'message': message,
      'sentAt': FieldValue.serverTimestamp(),
    });
  }

  // Temporarily ban account
  Future<void> banUser(String uid, DateTime until) async {
    await _db.collection('users').doc(uid).update({
      'bannedUntil': Timestamp.fromDate(until),
    });
  }
}
