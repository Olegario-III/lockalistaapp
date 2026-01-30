// lib/features/events/event_list_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/services/firestore_service.dart';
import '../../models/event_model.dart' as em;
import 'event_card.dart';
import 'event_detail_page.dart';

class EventListPage extends StatefulWidget {
  const EventListPage({super.key});

  @override
  State<EventListPage> createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage>
    with SingleTickerProviderStateMixin {
  final FirestoreService _service = FirestoreService.instance;
  final User? currentUser = FirebaseAuth.instance.currentUser;

  late TabController _tabController;
  bool isAdmin = false;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkAdmin();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  /// ✅ FIXED: use startDate directly
  DateTime _eventDate(em.EventModel e) => e.startDate;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: Column(
        children: [
          /// 🔍 SEARCH
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search events...',
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

                final allEvents = snapshot.data ?? [];

                final filtered = allEvents
                    .where(
                      (e) => e.title.toLowerCase().contains(searchQuery),
                    )
                    .toList();

                final upcoming = filtered
                    .where((e) => !_eventDate(e).isBefore(now))
                    .toList()
                  ..sort(
                    (a, b) => _eventDate(a).compareTo(_eventDate(b)),
                  );

                final past = filtered
                    .where((e) => _eventDate(e).isBefore(now))
                    .toList()
                  ..sort(
                    (a, b) => _eventDate(b).compareTo(_eventDate(a)),
                  );

                return TabBarView(
                  controller: _tabController,
                  children: [
                    /// 🟢 UPCOMING
                    _buildList(upcoming, allowActions: true),

                    /// ⚫ PAST
                    _buildList(past, allowActions: false),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    List<em.EventModel> events, {
    required bool allowActions,
  }) {
    if (events.isEmpty) {
      return const Center(child: Text('No events found.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final e = events[index];

        final liked = e.likesList.contains(currentUser?.uid);
        final canDelete =
            allowActions && (isAdmin || e.ownerId == currentUser?.uid);

        return EventCard(
          event: e,

          /// ✅ REQUIRED FIELDS
          posterName: e.ownerName,
          posterAvatar: e.ownerAvatar,

          liked: liked,
          canDelete: canDelete,

          /// ✅ VoidCallback-safe wrappers
          onLike: () {
            if (!allowActions || currentUser == null) return;
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
            if (!canDelete) return;
            await _service.deleteEvent(e.id);
          },

          onReport: () {
            if (!allowActions) return;
            // TODO: implement report dialog
          },
        );
      },
    );
  }
}
