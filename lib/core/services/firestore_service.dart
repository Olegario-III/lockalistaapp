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

  Future<List<store.StoreModel>> getStores() async {
    final snapshot = await _db.collection('stores').get();
    return snapshot.docs
        .map((doc) => store.StoreModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<store.StoreModel?> getStoreById(String id) async {
    final doc = await _db.collection('stores').doc(id).get();
    if (!doc.exists) return null;
    return store.StoreModel.fromMap(doc.data()!, doc.id);
  }

  Future<void> addStore(store.StoreModel store) async {
    await _db.collection('stores').add(store.toMap());
  }

  Future<void> updateStore(String id, store.StoreModel store) async {
    await _db.collection('stores').doc(id).update(store.toMap());
  }

  Future<void> deleteStore(String id) async {
    await _db.collection('stores').doc(id).delete();
  }

  Stream<List<store.StoreModel>> getStoresStream({required String status}) {
    return _db
        .collection('stores')
        .where('approved', isEqualTo: status == 'approved')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => store.StoreModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> approveStore(String id) async {
    await _db.collection('stores').doc(id).update({'approved': true});
  }

  Future<void> addStoreComment(
  String storeId,
  store.CommentModel comment,
) async {
  await _db.collection('stores').doc(storeId).update({
    'comments': FieldValue.arrayUnion([comment.toMap()]),
  });
}

  Future<void> rateStore(String storeId, double rating) async {
  final ref = _db.collection('stores').doc(storeId);

  await _db.runTransaction((tx) async {
    final snap = await tx.get(ref);
    if (!snap.exists) return;

    final data = snap.data()!;
    final double currentRating = (data['rating'] ?? 0).toDouble();
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

Future<void> reportStore(String storeId, String userId) async {
  await _db.collection('reports').add({
    'storeId': storeId,
    'reportedBy': userId,
    'createdAt': FieldValue.serverTimestamp(),
    'type': 'store',
  });
}

  /// ================================
  /// 📅 EVENTS
  /// ================================

  Future<List<event.EventModel>> getEvents() async {
    final snapshot = await _db.collection('events').get();
    return snapshot.docs
        .map((doc) => event.EventModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<event.EventModel?> getEventById(String id) async {
    final doc = await _db.collection('events').doc(id).get();
    if (!doc.exists) return null;
    return event.EventModel.fromMap(doc.data()!, doc.id);
  }

  /// 🔹 Used when ID is NOT important
  Future<void> addEvent(event.EventModel event) async {
    await _db.collection('events').add(event.toMap());
  }

  /// 🔹 Used when ID is pre-generated (recommended)
  Future<void> addEventWithId(event.EventModel event) async {
    await _db.collection('events').doc(event.id).set(event.toMap());
  }

  Future<void> updateEvent(String id, event.EventModel event) async {
    await _db.collection('events').doc(id).update(event.toMap());
  }

  Future<void> deleteEvent(String id) async {
    await _db.collection('events').doc(id).delete();
  }

  Stream<List<event.EventModel>> getEventsStream({required String status}) {
    return _db
        .collection('events')
        .where('approved', isEqualTo: status == 'approved')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => event.EventModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> approveEvent(String id) async {
    await _db.collection('events').doc(id).update({'approved': true});
  }

  /// 🔄 Partial update (used for editing)
Future<void> updateEventFields(
  String eventId,
  Map<String, dynamic> data,
) async {
  await _db.collection('events').doc(eventId).update(data);
}

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

    tx.update(ref, {
      'likesList': likes,
      'likesCount': likesCount,
    });
  });
}

  Future<void> addCommentToEvent(
  String eventId,
  event.CommentModel comment,
) async {
  final ref = _db.collection('events').doc(eventId);

  await ref.update({
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
}
