// lib/features/events/event_list_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/services/firestore_service.dart';
import '../../models/event_model.dart' as em;
import '../profile/profile_page.dart';
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

  /// Cache for owner avatars to reduce repeated reads
  final Map<String, String> _avatarCache = {};

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

  DateTime _eventDate(em.EventModel e) => e.startDate;

  /// Fetch avatar from Firestore or cache
  Future<String> _getAvatar(String ownerId) async {
    if (_avatarCache.containsKey(ownerId)) return _avatarCache[ownerId]!;

    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(ownerId).get();
      final avatar = (doc.data()?['image'] ?? '') as String;
      _avatarCache[ownerId] = avatar;
      return avatar;
    } catch (_) {
      return '';
    }
  }

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
                    .where((e) => e.title.toLowerCase().contains(searchQuery))
                    .toList();

                final upcoming = filtered
                    .where((e) => !_eventDate(e).isBefore(now))
                    .toList()
                      ..sort((a, b) => _eventDate(a).compareTo(_eventDate(b)));

                final past = filtered
                    .where((e) => _eventDate(e).isBefore(now))
                    .toList()
                      ..sort((a, b) => _eventDate(b).compareTo(_eventDate(a)));

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _EventListView(
                      events: upcoming,
                      allowActions: true,
                      currentUser: currentUser,
                      isAdmin: isAdmin,
                      avatarCache: _avatarCache,
                      getAvatar: _getAvatar,
                    ),
                    _EventListView(
                      events: past,
                      allowActions: false,
                      currentUser: currentUser,
                      isAdmin: isAdmin,
                      avatarCache: _avatarCache,
                      getAvatar: _getAvatar,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 💡 Separate widget to prevent FutureBuilder from rebuilding the whole list
class _EventListView extends StatelessWidget {
  final List<em.EventModel> events;
  final bool allowActions;
  final User? currentUser;
  final bool isAdmin;
  final Map<String, String> avatarCache;
  final Future<String> Function(String ownerId) getAvatar;

  const _EventListView({
    required this.events,
    required this.allowActions,
    required this.currentUser,
    required this.isAdmin,
    required this.avatarCache,
    required this.getAvatar,
  });

  @override
  Widget build(BuildContext context) {
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
        final canDelete = allowActions && (isAdmin || e.ownerId == currentUser?.uid);

        return FutureBuilder<String>(
          future: getAvatar(e.ownerId),
          builder: (context, snapshot) {
            // Use cached or empty string to avoid blinking
            final avatarUrl = snapshot.data?.trim() ?? avatarCache[e.ownerId] ?? '';

            return EventCard(
              event: e,
              posterName: e.ownerName,
              posterAvatar: avatarUrl.isNotEmpty ? avatarUrl : null,
              liked: liked,
              canDelete: canDelete,
              onLike: () {
                if (!allowActions || currentUser == null) return;
                FirestoreService.instance.likeEvent(e.id, currentUser!.uid);
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
                await FirestoreService.instance.deleteEvent(e.id);
              },
              onReport: () {},
              onViewProfile: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfilePage(userId: e.ownerId),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
