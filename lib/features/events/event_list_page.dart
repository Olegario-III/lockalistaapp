// lib/features/events/event_list_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/services/firestore_service.dart';
import '../../models/event_model.dart' as em;
import '../events/event_detail_page.dart';
import '../profile/profile_page.dart';

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

    if (doc.exists && doc.data()?['role'] == 'admin') {
      if (!mounted) return;
      setState(() => isAdmin = true);
    }
  }

  /// 🔁 Fallback ONLY for old events
  Future<Map<String, String?>> _loadOwnerProfile(em.EventModel e) async {
    if (e.ownerName.isNotEmpty) {
      return {
        'name': e.ownerName,
        'avatar': e.ownerAvatar,
      };
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

  /// 🚩 Report event owner
  Future<void> _reportEventOwner(em.EventModel event) async {
    if (currentUser == null) return;

    if (currentUser!.uid == event.ownerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You can't report yourself")),
      );
      return;
    }

    final reasons = [
      'Spam',
      'Harassment',
      'Scam',
      'Inappropriate content',
      'Fake event',
    ];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        String? selectedReason; // move inside builder for proper StatefulBuilder
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return AlertDialog(
              title: const Text('Report Event Owner'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: reasons.map((reason) {
                  return RadioListTile<String>(
                    title: Text(reason),
                    value: reason,
                    groupValue: selectedReason,
                    onChanged: (value) {
                      setStateSB(() {
                        selectedReason = value;
                      });
                    },
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedReason == null
                      ? null
                      : () => Navigator.pop(context, true),
                  child: const Text('Report'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || currentUser == null) return;

    try {
      await _service.reportUser(
        reportedUserId: event.ownerId,
        reportedBy: currentUser!.uid,
        eventId: event.id,
        reason: confirmed ? 'User reported' : '', // optional, can pass selectedReason if needed
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User reported successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
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
            itemCount: events.length,
            padding: const EdgeInsets.all(8),
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final e = events[index];
              final canDelete = isAdmin || e.ownerId == currentUser?.uid;
              final liked = e.likesList.contains(currentUser?.uid);

              return FutureBuilder<Map<String, String?>>(
                future: _loadOwnerProfile(e),
                builder: (context, userSnap) {
                  final posterName = userSnap.data?['name'] ?? 'Unknown';
                  final posterAvatar = userSnap.data?['avatar'];

                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 👤 Poster info
                        ListTile(
                          leading: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ProfilePage(userId: e.ownerId),
                                ),
                              );
                            },
                            child: CircleAvatar(
                              backgroundImage: posterAvatar != null
                                  ? NetworkImage(posterAvatar)
                                  : null,
                              child: posterAvatar == null
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                          ),
                          title: Text(
                            posterName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            _formatDate(e.startDate),
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'report') {
                                await _reportEventOwner(e);
                              }
                              if (value == 'delete') {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Delete Event'),
                                    content: const Text(
                                      'Are you sure you want to delete this event?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  await _service.deleteEvent(e.id);
                                }
                              }
                            },
                            itemBuilder: (context) => [
                              if (!canDelete)
                                const PopupMenuItem(
                                  value: 'report',
                                  child: Text('🚩 Report User'),
                                ),
                              if (canDelete)
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('🗑 Delete Event'),
                                ),
                            ],
                          ),
                        ),

                        // 🖼 Event image
                        if (e.imageUrl != null && e.imageUrl!.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              e.imageUrl!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),

                        // 📝 Title & description
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                e.description,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),

                        // ❤️ Likes & 💬 Comments
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          child: Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  liked
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: Colors.red,
                                ),
                                onPressed: () async {
                                  if (currentUser == null) return;
                                  await _service.likeEvent(
                                      e.id, currentUser!.uid);
                                },
                              ),
                              Text('${e.likesCount}'),
                              const SizedBox(width: 16),
                              Text('${e.comments.length} 💬'),
                              const Spacer(),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          EventDetailPage(event: e),
                                    ),
                                  );
                                },
                                child: const Text('View'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // ✅ Format DateTime
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
