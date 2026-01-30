// lib/features/events/past_event_list_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  /// ✅ Use startDate for events
  DateTime _eventDate(em.EventModel e) => e.startDate;

  /// 🔹 Returns string like "7 days ago", "3 hours ago"
  String _timeSinceEvent(em.EventModel e) {
    final diff = DateTime.now().difference(_eventDate(e));

    if (diff.inDays > 0) return '${diff.inDays} days ago';
    if (diff.inHours > 0) return '${diff.inHours} hrs ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes} mins ago';
    return 'Just now';
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
                    // ⚫ Only past events
                    .where((e) => _eventDate(e).isBefore(now))
                    // 🔍 Filter by search
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

                    return EventCard(
                      event: e,
                      posterName: e.ownerName,
                      posterAvatar: e.ownerAvatar,
                      liked: liked,
                      canDelete: false, // Past events = read-only

                      /// ✅ Inject the "time since event" text
                      timeText: _timeSinceEvent(e),

                      // Safe no-op callbacks
                      onLike: () {},
                      onView: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EventDetailPage(event: e),
                          ),
                        );
                      },
                      onDelete: () {},
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
