// lib/core/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/store_model.dart' as store;
import '../../models/event_model.dart' as event;
import '../../models/user_model.dart';

class FirestoreService {
  // ────────────────────────────────
  // 🔒 Singleton setup
  // ────────────────────────────────
  FirestoreService._privateConstructor();
  static final FirestoreService instance =
      FirestoreService._privateConstructor();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ────────────────────────────────
  // 🆔 Generate Firestore document ID
  // ────────────────────────────────
  String generateId(String collectionPath) {
    return _db.collection(collectionPath).doc().id;
  }

  /// ================================
/// 🏪 STORES
/// ================================

/// Get ALL stores (admin use)
Future<List<store.StoreModel>> getStores() async {
  final snapshot = await _db.collection('stores').get();
  return snapshot.docs
      .map((doc) => store.StoreModel.fromMap(doc.data(), doc.id))
      .toList();
}

/// Get ONLY approved stores (public)
Stream<List<store.StoreModel>> getApprovedStoresStream() {
  return _db
      .collection('stores')
      .where('status', isEqualTo: 'approved')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) =>
                store.StoreModel.fromMap(doc.data(), doc.id))
            .toList(),
      );
}

/// Get ONLY pending stores (admin dashboard)
Stream<List<store.StoreModel>> getPendingStoresStream() {
  return _db
      .collection('stores')
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) =>
                store.StoreModel.fromMap(doc.data(), doc.id))
            .toList(),
      );
}

/// Get store by ID
Future<store.StoreModel?> getStoreById(String id) async {
  final doc = await _db.collection('stores').doc(id).get();
  if (!doc.exists) return null;
  return store.StoreModel.fromMap(doc.data()!, doc.id);
}

/// Add store (AUTO pending)
Future<void> addStore(store.StoreModel store) async {
  await _db.collection('stores').add({
    ...store.toMap(),
    'status': 'pending',
    'createdAt': FieldValue.serverTimestamp(),
  });
}

/// Update store (edit)
Future<void> updateStore(String id, store.StoreModel store) async {
  await _db.collection('stores').doc(id).update(store.toMap());
}

/// Delete store
Future<void> deleteStore(String id) async {
  await _db.collection('stores').doc(id).delete();
}

/// ✅ Admin approves store
Future<void> approveStore(String id) async {
  await _db.collection('stores').doc(id).update({
    'status': 'approved',
    'approvedAt': FieldValue.serverTimestamp(),
  });
}

/// ❌ Admin rejects store
Future<void> rejectStore(String id) async {
  await _db.collection('stores').doc(id).update({
    'status': 'rejected',
  });
}

/// 💬 Add comment to store
Future<void> addStoreComment(
  String storeId,
  store.CommentModel comment,
) async {
  await _db.collection('stores').doc(storeId).update({
    'comments': FieldValue.arrayUnion([comment.toMap()]),
  });
}

/// ⭐ Rate store (average rating logic)
Future<void> rateStore(String storeId, double rating) async {
  final ref = _db.collection('stores').doc(storeId);

  await _db.runTransaction((tx) async {
    final snap = await tx.get(ref);
    if (!snap.exists) return;

    final data = snap.data()!;
    final double currentRating =
        (data['rating'] ?? 0).toDouble();
    final int count = (data['ratingCount'] ?? 0);

    final newCount = count + 1;
    final newRating =
        ((currentRating * count) + rating) / newCount;

    tx.update(ref, {
      'rating': newRating,
      'ratingCount': newCount,
    });
  });
}

/// 🚨 Report store
Future<void> reportStore(String storeId, String userId) async {
  await _db.collection('reports').add({
    'storeId': storeId,
    'reportedBy': userId,
    'type': 'store',
    'createdAt': FieldValue.serverTimestamp(),
  });
}

 /// ================================
/// 📅 EVENTS
/// ================================

/// Stream of a single event (live updates)
Stream<event.EventModel> getEventStream(String eventId) {
  return _db.collection('events').doc(eventId).snapshots().map(
        (doc) => event.EventModel.fromMap(doc.data()!, doc.id),
      );
}

/// Get username by Firebase UID
Future<String> getUserName(String userId) async {
  final doc = await _db.collection('users').doc(userId).get();
  if (!doc.exists) return 'Unknown';
  return (doc.data()?['name'] ?? 'No Name') as String;
}

/// Get all events (optional filter by status)
Future<List<event.EventModel>> getEvents({String? status}) async {
  Query query = _db.collection('events');
  if (status != null) query = query.where('status', isEqualTo: status);

  final snapshot = await query.orderBy('startDate').get();
  return snapshot.docs
      .map((doc) => event.EventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
      .toList();
}

/// Get single event
Future<event.EventModel?> getEventById(String id) async {
  final doc = await _db.collection('events').doc(id).get();
  if (!doc.exists) return null;
  return event.EventModel.fromMap(doc.data()!, doc.id);
}

/// Add event → always pending
Future<DocumentReference> addEvent(event.EventModel eventModel, String ownerId, {String? ownerAvatarUrl}) async {
  return await _db.collection('events').add({
    ...eventModel.toMap(),
    'ownerId': ownerId,
    'ownerAvatarUrl': ownerAvatarUrl ?? '',
    'status': 'pending',
    'createdAt': FieldValue.serverTimestamp(),
  });
}

/// Add event with pre-generated ID
Future<void> addEventWithId(event.EventModel eventModel, String ownerId, {String? ownerAvatarUrl}) async {
  await _db.collection('events').doc(eventModel.id).set({
    ...eventModel.toMap(),
    'ownerId': ownerId,
    'ownerAvatarUrl': ownerAvatarUrl ?? '',
    'status': 'pending',
    'createdAt': FieldValue.serverTimestamp(),
  });
}

/// Update full event
Future<void> updateEvent(String id, event.EventModel eventModel) async {
  await _db.collection('events').doc(id).update(eventModel.toMap());
}

/// Partial update
Future<void> updateEventFields(String eventId, Map<String, dynamic> data) async {
  await _db.collection('events').doc(eventId).update(data);
}

/// Delete event
Future<void> deleteEvent(String id) async {
  await _db.collection('events').doc(id).delete();
}

/// Approved events (public)
Stream<List<event.EventModel>> getApprovedEventsStream() {
  return _db
      .collection('events')
      .where('status', isEqualTo: 'approved')
      .orderBy('startDate')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => event.EventModel.fromMap(doc.data(), doc.id))
          .toList());
}

/// Pending events (admin)
Stream<List<event.EventModel>> getPendingEventsStream() {
  return _db
      .collection('events')
      .where('status', isEqualTo: 'pending')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => event.EventModel.fromMap(doc.data(), doc.id))
          .toList());
}

/// Generic status stream
Stream<List<event.EventModel>> getEventsStream({required String status}) {
  return _db
      .collection('events')
      .where('status', isEqualTo: status)
      .orderBy('startDate')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => event.EventModel.fromMap(doc.data(), doc.id))
          .toList());
}

/// ✅ ADMIN ACTIONS
Future<void> approveEvent(String id, {String? adminName, String? adminId}) async {
  await _db.collection('events').doc(id).update({
    'status': 'approved',
    'approvedAt': FieldValue.serverTimestamp(),
    'approvedBy': adminId ?? '',
    'approvedByName': adminName ?? '',
  });
}

Future<void> rejectEvent(String id, {String? adminName, String? adminId}) async {
  await _db.collection('events').doc(id).update({
    'status': 'rejected',
    'rejectedAt': FieldValue.serverTimestamp(),
    'approvedBy': adminId ?? '',
    'approvedByName': adminName ?? '',
  });
}

/// ❤️ LIKES
Future<void> likeEvent(String eventId, String userId) async {
  final ref = _db.collection('events').doc(eventId);
  await _db.runTransaction((tx) async {
    final snap = await tx.get(ref);
    if (!snap.exists) return;

    final data = snap.data()!;
    final List likes = List.from(data['likesList'] ?? []);
    int likesCount = data['likesCount'] ?? 0;

    if (likes.contains(userId)) {
      likes.remove(userId);
      likesCount--;
    } else {
      likes.add(userId);
      likesCount++;
    }

    tx.update(ref, {'likesList': likes, 'likesCount': likesCount});
  });
}

/// 💬 COMMENTS
Future<void> addCommentToEvent(String eventId, event.CommentModel comment) async {
  await _db.collection('events').doc(eventId).update({
    'comments': FieldValue.arrayUnion([comment.toMap()]),
  });
}

Future<void> toggleCommentLike({
  required String eventId,
  required String commentId,
  required String userId,
}) async {
  final ref = _db.collection('events').doc(eventId);
  await _db.runTransaction((tx) async {
    final snap = await tx.get(ref);
    if (!snap.exists) return;

    final data = snap.data()!;
    final List comments = List.from(data['comments'] ?? []);

    for (final c in comments) {
      if (c['id'] == commentId) {
        final likes = List<String>.from(c['likes'] ?? []);
        final dislikes = List<String>.from(c['dislikes'] ?? []);

        if (likes.contains(userId)) {
          likes.remove(userId);
        } else {
          likes.add(userId);
          dislikes.remove(userId);
        }

        c['likes'] = likes;
        c['dislikes'] = dislikes;
        break;
      }
    }

    tx.update(ref, {'comments': comments});
  });
}

Future<void> toggleCommentDislike({
  required String eventId,
  required String commentId,
  required String userId,
}) async {
  final ref = _db.collection('events').doc(eventId);
  await _db.runTransaction((tx) async {
    final snap = await tx.get(ref);
    if (!snap.exists) return;

    final data = snap.data()!;
    final List comments = List.from(data['comments'] ?? []);

    for (final c in comments) {
      if (c['id'] == commentId) {
        final likes = List<String>.from(c['likes'] ?? []);
        final dislikes = List<String>.from(c['dislikes'] ?? []);

        if (dislikes.contains(userId)) {
          dislikes.remove(userId);
        } else {
          dislikes.add(userId);
          likes.remove(userId);
        }

        c['likes'] = likes;
        c['dislikes'] = dislikes;
        break;
      }
    }

    tx.update(ref, {'comments': comments});
  });
}

/// 💬 Delete comment
Future<void> deleteComment({
  required String eventId,
  required String commentId,
}) async {
  final ref = _db.collection('events').doc(eventId);
  await _db.runTransaction((tx) async {
    final snap = await tx.get(ref);
    if (!snap.exists) return;

    final data = snap.data()!;
    final List comments = List.from(data['comments'] ?? []);

    comments.removeWhere((c) => c['id'] == commentId);

    tx.update(ref, {'comments': comments});
  });
}


  /// ================================
  /// 👤 USERS
  /// ================================

  Future<List<UserModel>> getUsers() async {
    final snapshot = await _db.collection('users').get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<UserModel?> getUserById(String id) async {
    final doc = await _db.collection('users').doc(id).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  Future<void> updateUser(String id, UserModel user) async {
    await _db.collection('users').doc(id).update(user.toMap());
  }

  Future<void> deleteUser(String id) async {
    await _db.collection('users').doc(id).delete();
  }

    /// ================================
  /// 🔍 SEARCH
  /// ================================

  Future<List<event.EventModel>> searchEvents(String query) async {
    final q = query.toLowerCase();

    final snap = await _db
        .collection('events')
        .where('approved', isEqualTo: true)
        .get();

    return snap.docs
        .map((d) => event.EventModel.fromMap(d.data(), d.id))
        .where((e) =>
            e.title.toLowerCase().contains(q) ||
            e.description.toLowerCase().contains(q))
        .toList();
  }

  Future<List<store.StoreModel>> searchStores(String query) async {
    final q = query.toLowerCase();

    final snap = await _db
        .collection('stores')
        .where('approved', isEqualTo: true)
        .get();

    return snap.docs
        .map((d) => store.StoreModel.fromMap(d.data(), d.id))
        .where((s) =>
            s.name.toLowerCase().contains(q) ||
            (s.description ?? '').toLowerCase().contains(q))
        .toList();
  }
}

