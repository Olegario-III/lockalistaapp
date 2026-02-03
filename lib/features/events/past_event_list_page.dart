import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/services/firestore_service.dart';
import '../../models/event_model.dart' as em;
import 'event_card.dart';
import 'event_detail_page.dart';

class PastEventListPage extends StatefulWidget {
  const PastEventListPage({super.key});

  @override
  State<PastEventListPage> createState() => _PastEventListPageState();
}

class _PastEventListPageState extends State<PastEventListPage> {
  final FirestoreService _service = FirestoreService.instance;
  final User? currentUser = FirebaseAuth.instance.currentUser;

  String searchQuery = '';
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

  /// ✅ Use startDate for events
  DateTime _eventDate(em.EventModel e) => e.startDate;

  /// 🔹 Returns string like "7 days ago"
  String _timeSinceEvent(em.EventModel e) {
    final diff = DateTime.now().difference(_eventDate(e));

    if (diff.inDays > 0) return '${diff.inDays} days ago';
    if (diff.inHours > 0) return '${diff.inHours} hrs ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes} mins ago';
    return 'Just now';
  }

  Future<void> _confirmDelete(em.EventModel e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete event?'),
        content: const Text(
          'This event has already passed. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _service.deleteEvent(e.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Past Events'),
      ),
      body: Column(
        children: [
          /// 🔍 SEARCH
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search past events...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (v) {
                setState(() {
                  searchQuery = v.trim().toLowerCase();
                });
              },
            ),
          ),

          Expanded(
            child: StreamBuilder<List<em.EventModel>>(
              stream: _service.getEventsStream(status: 'approved'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final events = (snapshot.data ?? [])
                    .where((e) => _eventDate(e).isBefore(now))
                    .where(
                      (e) => e.title.toLowerCase().contains(searchQuery),
                    )
                    .toList()
                  ..sort(
                    (a, b) => _eventDate(b).compareTo(_eventDate(a)),
                  );

                if (events.isEmpty) {
                  return const Center(
                    child: Text('No past events found.'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: events.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final e = events[index];
                    final liked = e.likesList.contains(currentUser?.uid);
                    final canDelete = isAdmin; // 🔐 ADMIN ONLY

                    return EventCard(
                      event: e,
                      posterName: e.ownerName,
                      posterAvatar: e.ownerAvatar,
                      liked: liked,
                      canDelete: canDelete,

                      /// ⏱ Time since event
                      timeText: _timeSinceEvent(e),

                      onLike: () {},
                      onView: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EventDetailPage(event: e),
                          ),
                        );
                      },
                      onDelete: () {
                        if (!canDelete) return;
                        _confirmDelete(e);
                      },
                      onReport: () {},
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
