import 'firestore_service.dart';

class AdminService {
  final _db = FirestoreService.instance;

  Future<void> approveEvent(String id) => _db.approveEvent(id);
  Future<void> rejectEvent(String id) => _db.updateEvent(id, {'status': 'rejected'});
  Stream getPendingEventsStream() => _db.getEventsStream(status: 'pending');
}