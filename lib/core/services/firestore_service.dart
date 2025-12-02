// lib/core/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/event_model.dart' as em;
import '../../models/store_model.dart' as sm;
import '../../models/user_model.dart' as um;

/// FirestoreService — uses aliased model imports to avoid duplicate symbol names
class FirestoreService {
  FirestoreService._internal();
  static final FirestoreService instance = FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Generate a Firestore document ID without writing anything yet
  String generateId(String collectionName) {
    return _db.collection(collectionName).doc().id;
  }

  // ===== EVENTS =====

  Future<List<em.EventModel>> getEvents() async {
    final snapshot =
        await _db.collection('events').orderBy('createdAt', descending: true).get();
    return snapshot.docs
        .map((doc) => em.EventModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<List<em.EventModel>> getApprovedEvents() async {
    final snapshot = await _db
        .collection('events')
        .where('status', isEqualTo: 'approved')
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((d) => em.EventModel.fromMap(d.data(), d.id))
        .toList();
  }

  Future<void> addEvent(em.EventModel event) async {
    await _db.collection('events').add(event.toMap());
  }

  Future<void> updateEvent(String id, Map<String, dynamic> data) async {
    await _db.collection('events').doc(id).update(data);
  }

  Stream<List<em.EventModel>> getEventsStream({String? status}) {
    Query query = _db.collection('events').orderBy('createdAt', descending: true);
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    return query.snapshots().map((snap) => snap.docs
        .map((doc) => em.EventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  Future<void> approveEvent(String id) async {
    await _db.collection('events').doc(id).update({'status': 'approved'});
  }

  /// Toggle like for an event by userId. Uses transaction to keep likesCount consistent.
  Future<void> likeEvent(String eventId, String userId) async {
    final ref = _db.collection('events').doc(eventId);

    await _db.runTransaction((tx) async {
      final snapshot = await tx.get(ref);
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final List<dynamic> likesListRaw = data['likesList'] ?? [];
      final likesList = List<String>.from(likesListRaw.map((e) => e.toString()));
      final bool already = likesList.contains(userId);

      if (already) {
        likesList.remove(userId);
        tx.update(ref, {
          'likesList': likesList,
          'likesCount': FieldValue.increment(-1),
        });
      } else {
        likesList.add(userId);
        tx.update(ref, {
          'likesList': likesList,
          'likesCount': FieldValue.increment(1),
        });
      }
    });
  }

  /// Add a comment to an event (stored inside event document as array)
  Future<void> addCommentToEvent(String eventId, em.CommentModel comment) async {
    final ref = _db.collection('events').doc(eventId);
    await ref.update({
      'comments': FieldValue.arrayUnion([comment.toMap()]),
    });
  }

  /// Get comments (reads the event document and parses comments)
  Future<List<em.CommentModel>> getCommentsForEvent(String eventId) async {
    final doc = await _db.collection('events').doc(eventId).get();
    if (!doc.exists) return [];
    final data = doc.data() as Map<String, dynamic>;
    final commentsRaw = data['comments'] as List<dynamic>? ?? [];
    final comments = <em.CommentModel>[];
    for (final c in commentsRaw) {
      if (c is Map<String, dynamic>) {
        comments.add(em.CommentModel.fromMap(c));
      }
    }
    return comments;
  }

  /// Toggle like on a specific comment in event (comment identified by 'id' field if present, otherwise by content+timestamp)
  Future<void> toggleCommentLike({
    required String eventId,
    required String commentIdOrKey,
    required String userId,
  }) async {
    final ref = _db.collection('events').doc(eventId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      final List<dynamic> commentsRaw = data['comments'] ?? [];
      final List<Map<String, dynamic>> comments = commentsRaw
          .map((e) => Map<String, dynamic>.from(e as Map<String, dynamic>))
          .toList();

      bool updated = false;
      for (var i = 0; i < comments.length; i++) {
        final c = comments[i];
        final cid = c['id']?.toString() ?? '${c['uid']}_${c['timestamp']?.toString()}';
        if (cid == commentIdOrKey) {
          final likes = (c['likes'] != null) ? List<String>.from(c['likes'] as List<dynamic>) : <String>[];
          final dislikes = (c['dislikes'] != null)
              ? List<String>.from(c['dislikes'] as List<dynamic>)
              : <String>[];
          if (likes.contains(userId)) {
            likes.remove(userId);
          } else {
            likes.add(userId);
            // remove from dislikes if present
            dislikes.remove(userId);
          }
          c['likes'] = likes;
          c['dislikes'] = dislikes;
          comments[i] = c;
          updated = true;
          break;
        }
      }

      if (updated) {
        tx.update(ref, {'comments': comments});
      }
    });
  }

  Future<void> toggleCommentDislike({
    required String eventId,
    required String commentIdOrKey,
    required String userId,
  }) async {
    final ref = _db.collection('events').doc(eventId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      final List<dynamic> commentsRaw = data['comments'] ?? [];
      final List<Map<String, dynamic>> comments = commentsRaw
          .map((e) => Map<String, dynamic>.from(e as Map<String, dynamic>))
          .toList();

      bool updated = false;
      for (var i = 0; i < comments.length; i++) {
        final c = comments[i];
        final cid = c['id']?.toString() ?? '${c['uid']}_${c['timestamp']?.toString()}';
        if (cid == commentIdOrKey) {
          final likes = (c['likes'] != null) ? List<String>.from(c['likes'] as List<dynamic>) : <String>[];
          final dislikes = (c['dislikes'] != null)
              ? List<String>.from(c['dislikes'] as List<dynamic>)
              : <String>[];
          if (dislikes.contains(userId)) {
            dislikes.remove(userId);
          } else {
            dislikes.add(userId);
            likes.remove(userId);
          }
          c['likes'] = likes;
          c['dislikes'] = dislikes;
          comments[i] = c;
          updated = true;
          break;
        }
      }

      if (updated) {
        tx.update(ref, {'comments': comments});
      }
    });
  }

  // ===== USERS =====
  Future<List<um.UserModel>> getUsers() async {
    final snapshot = await _db.collection('users').get();
    return snapshot.docs
        .map((doc) => um.UserModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // ===== STORES =====

  Future<List<sm.StoreModel>> getStores() async {
    final snapshot =
        await _db.collection('stores').orderBy('createdAt', descending: true).get();
    return snapshot.docs
        .map((doc) => sm.StoreModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Stream<List<sm.StoreModel>> getStoresStream({String? status}) {
    Query query = _db.collection('stores').orderBy('createdAt', descending: true);
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    return query.snapshots().map((snap) => snap.docs
        .map((doc) => sm.StoreModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  Future<void> addStore(sm.StoreModel store) async {
    await _db.collection('stores').add(store.toMap());
  }

  Future<void> updateStore(String id, Map<String, dynamic> data) async {
    await _db.collection('stores').doc(id).update(data);
  }

  Future<void> approveStore(String id) async {
    await _db.collection('stores').doc(id).update({'status': 'approved'});
  }

  /// Rate a store: will add or update a user's rating in a transaction
  /// ratingValue expected to be 1..5
  Future<void> rateStore(String storeId, String userId, num ratingValue) async {
    final ref = _db.collection('stores').doc(storeId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final data = snap.data() as Map<String, dynamic>;
      final Map<String, dynamic> ratingsMapRaw =
          data['ratings'] != null ? Map<String, dynamic>.from(data['ratings'] as Map) : {};
      final Map<String, num> ratings = ratingsMapRaw
          .map((k, v) => MapEntry(k, (v is num) ? v : num.tryParse(v.toString()) ?? 0));

      final int currentCount = (data['ratingsCount'] is int) ? data['ratingsCount'] as int : 0;
      final num currentSum = (data['ratingSum'] is num) ? data['ratingSum'] as num : 0;

      final bool hadRating = ratings.containsKey(userId);
      final num previousRating = hadRating ? ratings[userId]! : 0;
      // update map
      ratings[userId] = ratingValue;

      final int newCount = hadRating ? currentCount : currentCount + 1;
      final num newSum = hadRating ? (currentSum - previousRating + ratingValue) : (currentSum + ratingValue);

      tx.update(ref, {
        'ratings': ratings,
        'ratingsCount': newCount,
        'ratingSum': newSum,
      });
    });
  }

  /// Add comment to store (array in the document)
  Future<void> addCommentToStore(String storeId, sm.CommentModel comment) async {
    final ref = _db.collection('stores').doc(storeId);
    await ref.update({
      'comments': FieldValue.arrayUnion([comment.toMap()]),
    });
  }

  /// Toggle like/dislike for store comment
  Future<void> toggleCommentLikeForStore({
    required String storeId,
    required String commentIdOrKey,
    required String userId,
  }) async {
    final ref = _db.collection('stores').doc(storeId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      final List<dynamic> commentsRaw = data['comments'] ?? [];
      final List<Map<String, dynamic>> comments = commentsRaw
          .map((e) => Map<String, dynamic>.from(e as Map<String, dynamic>))
          .toList();

      bool updated = false;
      for (var i = 0; i < comments.length; i++) {
        final c = comments[i];
        final cid = c['id']?.toString() ?? '${c['uid']}_${c['timestamp']?.toString()}';
        if (cid == commentIdOrKey) {
          final likes = (c['likes'] != null) ? List<String>.from(c['likes'] as List<dynamic>) : <String>[];
          final dislikes = (c['dislikes'] != null)
              ? List<String>.from(c['dislikes'] as List<dynamic>)
              : <String>[];
          if (likes.contains(userId)) {
            likes.remove(userId);
          } else {
            likes.add(userId);
            dislikes.remove(userId);
          }
          c['likes'] = likes;
          c['dislikes'] = dislikes;
          comments[i] = c;
          updated = true;
          break;
        }
      }

      if (updated) {
        tx.update(ref, {'comments': comments});
      }
    });
  }

  Future<void> toggleCommentDislikeForStore({
    required String storeId,
    required String commentIdOrKey,
    required String userId,
  }) async {
    final ref = _db.collection('stores').doc(storeId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      final List<dynamic> commentsRaw = data['comments'] ?? [];
      final List<Map<String, dynamic>> comments = commentsRaw
          .map((e) => Map<String, dynamic>.from(e as Map<String, dynamic>))
          .toList();

      bool updated = false;
      for (var i = 0; i < comments.length; i++) {
        final c = comments[i];
        final cid = c['id']?.toString() ?? '${c['uid']}_${c['timestamp']?.toString()}';
        if (cid == commentIdOrKey) {
          final likes = (c['likes'] != null) ? List<String>.from(c['likes'] as List<dynamic>) : <String>[];
          final dislikes = (c['dislikes'] != null)
              ? List<String>.from(c['dislikes'] as List<dynamic>)
              : <String>[];
          if (dislikes.contains(userId)) {
            dislikes.remove(userId);
          } else {
            dislikes.add(userId);
            likes.remove(userId);
          }
          c['likes'] = likes;
          c['dislikes'] = dislikes;
          comments[i] = c;
          updated = true;
          break;
        }
      }

      if (updated) {
        tx.update(ref, {'comments': comments});
      }
    });
  }

    /// ===== SEARCH =====

  Future<List<em.EventModel>> searchEvents(String query) async {
    final qLower = query.toLowerCase();

    final snap = await _db
        .collection('events')
        .where('status', isEqualTo: 'approved')
        .get();

    return snap.docs
        .map((d) => em.EventModel.fromMap(d.data(), d.id))
        .where((e) =>
            e.title.toLowerCase().contains(qLower) ||
            e.description.toLowerCase().contains(qLower))
        .toList();
  }

  Future<List<sm.StoreModel>> searchStores(String query) async {
    final qLower = query.toLowerCase();

    final snap = await _db
        .collection('stores')
        .where('status', isEqualTo: 'approved')
        .get();

    return snap.docs
        .map((d) => sm.StoreModel.fromMap(d.data(), d.id))
        .where((s) =>
            s.name.toLowerCase().contains(qLower) ||
            (s.description ?? '').toLowerCase().contains(qLower))
        .toList();
  }

}
