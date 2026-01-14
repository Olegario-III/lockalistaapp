// lib/core/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/store_model.dart';
import '../../models/event_model.dart';
import '../../models/user_model.dart';

class FirestoreService {
  // Private constructor for singleton
  FirestoreService._privateConstructor();

  // Singleton instance
  static final FirestoreService instance = FirestoreService._privateConstructor();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// ---------------- Stores ----------------

  Future<List<StoreModel>> getStores() async {
    final snapshot = await _db.collection('stores').get();
    return snapshot.docs
        .map((doc) => StoreModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<StoreModel?> getStoreById(String id) async {
    final doc = await _db.collection('stores').doc(id).get();
    if (!doc.exists) return null;
    return StoreModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Future<void> addStore(StoreModel store) async {
    await _db.collection('stores').add(store.toMap());
  }

  Future<void> updateStore(String id, StoreModel store) async {
    await _db.collection('stores').doc(id).update(store.toMap());
  }

  Future<void> deleteStore(String id) async {
    await _db.collection('stores').doc(id).delete();
  }

  Stream<List<StoreModel>> getStoresStream({required String status}) {
    return _db
        .collection('stores')
        .where('approved', isEqualTo: status == 'approved')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StoreModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> approveStore(String id) async {
    await _db.collection('stores').doc(id).update({'approved': true});
  }

  /// ---------------- Events ----------------

  Future<List<EventModel>> getEvents() async {
    final snapshot = await _db.collection('events').get();
    return snapshot.docs
        .map((doc) => EventModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<EventModel?> getEventById(String id) async {
    final doc = await _db.collection('events').doc(id).get();
    if (!doc.exists) return null;
    return EventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Future<void> addEvent(EventModel event) async {
    await _db.collection('events').add(event.toMap());
  }

  Future<void> updateEvent(String id, EventModel event) async {
    await _db.collection('events').doc(id).update(event.toMap());
  }

  Future<void> deleteEvent(String id) async {
    await _db.collection('events').doc(id).delete();
  }

  Stream<List<EventModel>> getEventsStream({required String status}) {
    return _db
        .collection('events')
        .where('approved', isEqualTo: status == 'approved')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EventModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> approveEvent(String id) async {
    await _db.collection('events').doc(id).update({'approved': true});
  }

  /// ---------------- Users ----------------

  Future<List<UserModel>> getUsers() async {
    final snapshot = await _db.collection('users').get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<UserModel?> getUserById(String id) async {
    final doc = await _db.collection('users').doc(id).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Future<void> updateUser(String id, UserModel user) async {
    await _db.collection('users').doc(id).update(user.toMap());
  }

  Future<void> deleteUser(String id) async {
    await _db.collection('users').doc(id).delete();
  }
}
