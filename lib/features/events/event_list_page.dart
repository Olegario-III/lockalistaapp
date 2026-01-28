// lib/features/events/event_list_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/services/firestore_service.dart';
import '../../models/event_model.dart' as em;
import '../events/event_detail_page.dart';
import 'event_card.dart';

class EventListPage extends StatefulWidget {
  const EventListPage({super.key});

  @override
  State<EventListPage> createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  final FirestoreService _service = FirestoreService.instance;
  final User? currentUser = FirebaseAuth.instance.currentUser;

  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    if (currentUser == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .get();

    if (!mounted) return;

    setState(() {
      isAdmin = doc.data()?['role'] == 'admin';
    });
  }

  Future<Map<String, String?>> _loadOwnerProfile(em.EventModel e) async {
    if (e.ownerName.isNotEmpty) {
      return {'name': e.ownerName, 'avatar': e.ownerAvatar};
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(e.ownerId)
        .get();

    final data = doc.data();

    return {
      'name': data?['name'] ?? 'Unknown',
      'avatar': data?['image'],
    };
  }

  Future<void> _reportEventOwner(em.EventModel event) async {
    if (currentUser == null) return;
    if (currentUser!.uid == event.ownerId) return;

    final reasons = [
      'Spam',
      'Harassment',
      'Scam',
      'Inappropriate content',
      'Fake event',
    ];

    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        String? selected;
        return AlertDialog(
          title: const Text('Report Event Owner'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: reasons
                .map((r) => RadioListTile<String>(
                      title: Text(r),
                      value: r,
                      groupValue: selected,
                      onChanged: (v) =>
                          (context as Element).markNeedsBuild(),
                    ))
                .toList(),
          ),
        );
      },
    );

    if (reason == null) return;

    await _service.reportUser(
      reportedUserId: event.ownerId,
      reportedBy: currentUser!.uid,
      eventId: event.id,
      reason: reason,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Events Feed')),
      body: StreamBuilder<List<em.EventModel>>(
        stream: _service.getEventsStream(status: 'approved'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final events = snapshot.data ?? [];
          if (events.isEmpty) {
            return const Center(child: Text('No events yet.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: events.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final e = events[index];
              final liked = e.likesList.contains(currentUser?.uid);
              final canDelete = isAdmin || e.ownerId == currentUser?.uid;

              return FutureBuilder<Map<String, String?>>(
                future: _loadOwnerProfile(e),
                builder: (context, snap) {
                  return EventCard(
                    event: e,
                    posterName: snap.data?['name'] ?? 'Unknown',
                    posterAvatar: snap.data?['avatar'],
                    liked: liked,
                    canDelete: canDelete,
                    onLike: () {
                      if (currentUser == null) return;
                      _service.likeEvent(e.id, currentUser!.uid);
                    },
                    onView: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EventDetailPage(event: e),
                        ),
                      );
                    },
                    onDelete: () async {
                      await _service.deleteEvent(e.id);
                    },
                    onReport: () => _reportEventOwner(e),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
