// lib/features/events/event_list_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final User? currentUser = FirebaseAuth.instance.currentUser;
  late TabController _tabController;

  bool isAdmin = false;
  String searchQuery = '';

  List<em.EventModel> upcomingEvents = [];
  List<em.EventModel> pastEvents = [];

  DocumentSnapshot? lastUpcomingDoc;
  DocumentSnapshot? lastPastDoc;

  bool isLoadingUpcoming = false;
  bool isLoadingPast = false;

  bool hasMoreUpcoming = true;
  bool hasMorePast = true;

  final Map<String, String> _avatarCache = {};
  final ScrollController _upcomingController = ScrollController();
  final ScrollController _pastController = ScrollController();

  static const int pageSize = 5;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);

    _checkAdmin();
    fetchUpcomingEvents();
    fetchPastEvents();

    // ✅ FIXED SCROLL (UPCOMING)
    _upcomingController.addListener(() {
      if (_upcomingController.position.pixels >=
              _upcomingController.position.maxScrollExtent - 50 &&
          !isLoadingUpcoming &&
          hasMoreUpcoming) {
        fetchUpcomingEvents(loadMore: true);
      }
    });

    // ✅ FIXED SCROLL (PAST)
    _pastController.addListener(() {
      if (_pastController.position.pixels >=
              _pastController.position.maxScrollExtent - 50 &&
          !isLoadingPast &&
          hasMorePast) {
        fetchPastEvents(loadMore: true);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _upcomingController.dispose();
    _pastController.dispose();
    super.dispose();
  }

  Future<void> _checkAdmin() async {
    if (currentUser == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .get();

    if (!mounted) return;

    setState(() => isAdmin = doc.data()?['role'] == 'admin');
  }

  Future<String> _getAvatar(String ownerId) async {
    if (_avatarCache.containsKey(ownerId)) {
      return _avatarCache[ownerId]!;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(ownerId)
          .get();

      final avatar = (doc.data()?['image'] ?? '') as String;
      _avatarCache[ownerId] = avatar;

      return avatar;
    } catch (_) {
      return '';
    }
  }

  void _onSearch(String v) {
    setState(() {
      searchQuery = v.trim().toLowerCase();

      // RESET PAGINATION
      upcomingEvents.clear();
      pastEvents.clear();

      lastUpcomingDoc = null;
      lastPastDoc = null;

      hasMoreUpcoming = true;
      hasMorePast = true;
    });

    fetchUpcomingEvents();
    fetchPastEvents();
  }

  // 🔥 UPCOMING
  Future<void> fetchUpcomingEvents({bool loadMore = false}) async {
    if (isLoadingUpcoming || !hasMoreUpcoming) return;

    setState(() => isLoadingUpcoming = true);

    Query query = FirebaseFirestore.instance
        .collection('events')
        .where('status', isEqualTo: 'approved')
        .where('startDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()))
        .orderBy('startDate')
        .limit(pageSize);

    if (loadMore && lastUpcomingDoc != null) {
      query = query.startAfterDocument(lastUpcomingDoc!);
    }

    final snapshot = await query.get();
    if (!mounted) return;

    if (snapshot.docs.isEmpty) {
      setState(() {
        hasMoreUpcoming = false;
        isLoadingUpcoming = false;
      });
      return;
    }

    lastUpcomingDoc = snapshot.docs.last;

    final fetched = snapshot.docs
        .map((doc) => em.EventModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ))
        .toList();

    setState(() {
      if (loadMore) {
        upcomingEvents.addAll(fetched);
      } else {
        upcomingEvents = fetched;
      }

      hasMoreUpcoming = snapshot.docs.length == pageSize;
      isLoadingUpcoming = false;
    });
  }

  // 🔥 PAST
  Future<void> fetchPastEvents({bool loadMore = false}) async {
    if (isLoadingPast || !hasMorePast) return;

    setState(() => isLoadingPast = true);

    Query query = FirebaseFirestore.instance
        .collection('events')
        .where('status', isEqualTo: 'approved')
        .where('startDate',
            isLessThan: Timestamp.fromDate(DateTime.now()))
        .orderBy('startDate', descending: true)
        .limit(pageSize);

    if (loadMore && lastPastDoc != null) {
      query = query.startAfterDocument(lastPastDoc!);
    }

    final snapshot = await query.get();
    if (!mounted) return;

    if (snapshot.docs.isEmpty) {
      setState(() {
        hasMorePast = false;
        isLoadingPast = false;
      });
      return;
    }

    lastPastDoc = snapshot.docs.last;

    final fetched = snapshot.docs
        .map((doc) => em.EventModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ))
        .toList();

    setState(() {
      if (loadMore) {
        pastEvents.addAll(fetched);
      } else {
        pastEvents = fetched;
      }

      hasMorePast = snapshot.docs.length == pageSize;
      isLoadingPast = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayedUpcoming = upcomingEvents
        .where((e) => e.title.toLowerCase().contains(searchQuery))
        .toList();

    final displayedPast = pastEvents
        .where((e) => e.title.toLowerCase().contains(searchQuery))
        .toList();

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
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search events...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: _onSearch,
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _PaginatedListView(
                  events: displayedUpcoming,
                  isLoading: isLoadingUpcoming,
                  hasMore: hasMoreUpcoming,
                  onLoadMore: () => fetchUpcomingEvents(loadMore: true),
                  allowActions: true,
                  currentUser: currentUser,
                  isAdmin: isAdmin,
                  avatarCache: _avatarCache,
                  getAvatar: _getAvatar,
                  controller: _upcomingController,
                ),
                _PaginatedListView(
                  events: displayedPast,
                  isLoading: isLoadingPast,
                  hasMore: hasMorePast,
                  onLoadMore: () => fetchPastEvents(loadMore: true),
                  allowActions: false,
                  currentUser: currentUser,
                  isAdmin: isAdmin,
                  avatarCache: _avatarCache,
                  getAvatar: _getAvatar,
                  controller: _pastController,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaginatedListView extends StatelessWidget {
  final List<em.EventModel> events;
  final bool isLoading;
  final bool hasMore;
  final VoidCallback onLoadMore;
  final bool allowActions;
  final User? currentUser;
  final bool isAdmin;
  final Map<String, String> avatarCache;
  final Future<String> Function(String) getAvatar;
  final ScrollController controller;

  const _PaginatedListView({
    required this.events,
    required this.isLoading,
    required this.hasMore,
    required this.onLoadMore,
    required this.allowActions,
    required this.currentUser,
    required this.isAdmin,
    required this.avatarCache,
    required this.getAvatar,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty && isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (events.isEmpty) {
      return const Center(child: Text('No events found.'));
    }

    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.all(12),
      itemCount: events.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index < events.length) {
          final e = events[index];
          final liked = e.likesList.contains(currentUser?.uid);
          final canDelete =
              allowActions && (isAdmin || e.ownerId == currentUser?.uid);

          return FutureBuilder<String>(
            future: getAvatar(e.ownerId),
            builder: (context, snapshot) {
              final avatarUrl =
                  snapshot.data?.trim().isNotEmpty == true
                      ? snapshot.data
                      : avatarCache[e.ownerId];

              return EventCard(
                event: e,
                posterName: e.ownerName,
                posterAvatar: avatarUrl,
                liked: liked,
                canDelete: canDelete,
                onLike: () {
                  if (!allowActions || currentUser == null) return;

                  FirebaseFirestore.instance
                      .collection('events')
                      .doc(e.id)
                      .update({
                    'likesList': FieldValue.arrayUnion(
                        [currentUser!.uid])
                  });
                },
                onView: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => EventDetailPage(event: e)),
                ),
                onDelete: () async {
                  if (!canDelete) return;

                  await FirebaseFirestore.instance
                      .collection('events')
                      .doc(e.id)
                      .delete();
                },
                onReport: () {},
                onViewProfile: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          ProfilePage(userId: e.ownerId)),
                ),
              );
            },
          );
        }

        // ✅ VISIBLE PAGINATION UI
        return Column(
          children: [
            const SizedBox(height: 20),

            Text(
              'Showing ${events.length} events',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            if (hasMore)
              ElevatedButton(
                onPressed: isLoading ? null : onLoadMore,
                child: isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child:
                            CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Load More'),
              )
            else
              const Text('No more events'),

            const SizedBox(height: 30),
          ],
        );
      },
    );
  }
}