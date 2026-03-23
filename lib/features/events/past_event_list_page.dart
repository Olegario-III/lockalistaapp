// lib/features/events/past_event_list_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/services/firestore_service.dart';
import '../../models/event_model.dart' as em;
import '../profile/profile_page.dart';
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

  List<em.EventModel> events = [];
  DocumentSnapshot? lastDoc;
  bool isLoading = false;
  bool hasMore = true;

  final Map<String, String> _avatarCache = {};
  final ScrollController _scrollController = ScrollController();

  static const int pageSize = 5;

  @override
  void initState() {
    super.initState();
    _checkAdmin();
    fetchPastEvents();

    // ✅ FIXED SCROLL PAGINATION
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 50 &&
          !isLoading &&
          hasMore) {
        fetchPastEvents(loadMore: true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
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

  DateTime _eventDate(em.EventModel e) => e.startDate;

  String _timeSinceEvent(em.EventModel e) {
    final diff = DateTime.now().difference(_eventDate(e));

    if (diff.inDays > 0) return '${diff.inDays} days ago';
    if (diff.inHours > 0) return '${diff.inHours} hrs ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes} mins ago';

    return 'Just now';
  }

  Future<void> fetchPastEvents({bool loadMore = false}) async {
    if (isLoading || !hasMore) return;

    setState(() => isLoading = true);

    Query query = FirebaseFirestore.instance
        .collection('events')
        .where('status', isEqualTo: 'approved')
        .where('startDate',
            isLessThan: Timestamp.fromDate(DateTime.now()))
        .orderBy('startDate', descending: true)
        .limit(pageSize);

    if (loadMore && lastDoc != null) {
      query = query.startAfterDocument(lastDoc!);
    }

    final snapshot = await query.get();

    if (!mounted) return;

    if (snapshot.docs.isEmpty) {
      setState(() {
        hasMore = false;
        isLoading = false;
      });
      return;
    }

    lastDoc = snapshot.docs.last;

    final fetched = snapshot.docs
        .map((doc) => em.EventModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ))
        .toList();

    setState(() {
      if (loadMore) {
        events.addAll(fetched);
      } else {
        events = fetched;
      }

      hasMore = snapshot.docs.length == pageSize;
      isLoading = false;
    });
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayedEvents = events
        .where((e) =>
            e.title.toLowerCase().contains(searchQuery))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Past Events')),
      body: Column(
        children: [
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
              onChanged: _onSearch,
            ),
          ),

          Expanded(
            child: displayedEvents.isEmpty && isLoading
                ? const Center(child: CircularProgressIndicator())
                : displayedEvents.isEmpty
                    ? const Center(child: Text('No past events found.'))
                    : ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: displayedEvents.length + 1,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          // ✅ EVENTS
                          if (index < displayedEvents.length) {
                            final e = displayedEvents[index];
                            final liked = e.likesList
                                .contains(currentUser?.uid);
                            final canDelete = isAdmin;

                            return FutureBuilder<String>(
                              future: _getAvatar(e.ownerId),
                              builder: (context, snapshot) {
                                final avatarUrl =
                                    snapshot.data?.trim().isNotEmpty == true
                                        ? snapshot.data
                                        : _avatarCache[e.ownerId];

                                return EventCard(
                                  event: e,
                                  posterName: e.ownerName,
                                  posterAvatar: avatarUrl,
                                  liked: liked,
                                  canDelete: canDelete,
                                  timeText: _timeSinceEvent(e),
                                  onLike: () {},
                                  onView: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          EventDetailPage(event: e),
                                    ),
                                  ),
                                  onDelete: () async {
                                    if (!canDelete) return;
                                    await _service.deleteEvent(e.id);
                                  },
                                  onReport: () {},
                                  onViewProfile: () =>
                                      Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProfilePage(
                                          userId: e.ownerId),
                                    ),
                                  ),
                                );
                              },
                            );
                          }

                          // ✅ VERY VISIBLE PAGINATION UI
                          return Column(
                            children: [
                              const SizedBox(height: 20),

                              Text(
                                'Showing ${events.length} events',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),

                              const SizedBox(height: 10),

                              if (hasMore)
                                ElevatedButton(
                                  onPressed: isLoading
                                      ? null
                                      : () => fetchPastEvents(
                                          loadMore: true),
                                  child: isLoading
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child:
                                              CircularProgressIndicator(
                                                  strokeWidth: 2),
                                        )
                                      : const Text('Load More'),
                                )
                              else
                                const Text('No more events'),

                              const SizedBox(height: 30),
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