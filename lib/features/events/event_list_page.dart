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

    if (doc.exists && (doc.data()?['role'] ?? '') == 'admin') {
      setState(() => isAdmin = true);
    }
  }

  Future<Map<String, dynamic>> _getUserInfo(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!doc.exists) return {'name': 'Unknown', 'image': ''};
    final data = doc.data()!;
    return {
      'name': data['name'] ?? 'Unknown',
      'image': data['image'] ?? '',
    };
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
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              final e = events[index];

              // Show delete button if current user is admin or poster
              final canDelete = isAdmin || e.ownerId == currentUser?.uid;

              return FutureBuilder<Map<String, dynamic>>(
                future: _getUserInfo(e.ownerId),
                builder: (context, userSnapshot) {
                  final posterName = userSnapshot.data?['name'] ?? 'Loading...';
                  final posterImage = userSnapshot.data?['image'] ?? '';

                  final liked = e.likesList.contains(currentUser?.uid);

                  return Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Admin approval info
                        if (e.approvedByName != null && e.approvedByName!.isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12)),
                            ),
                            child: Text(
                              'Approved by: ${e.approvedByName}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ),

                        // Poster info
                        ListTile(
                          leading: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProfilePage(userId: e.ownerId),
                                ),
                              );
                            },
                            child: CircleAvatar(
                              backgroundImage: posterImage.isNotEmpty
                                  ? NetworkImage(posterImage)
                                  : NetworkImage(
                                      'https://i.pravatar.cc/150?u=${e.ownerId}'),
                            ),
                          ),
                          title: Text(
                            posterName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: e.timestamp != null
                              ? Text(
                                  '${e.timestamp!.toLocal()}'.split(' ')[0],
                                  style: const TextStyle(fontSize: 12),
                                )
                              : null,
                          trailing: canDelete
                              ? IconButton(
                                  icon:
                                      const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text('Delete Event'),
                                        content: const Text(
                                            'Are you sure you want to delete this event?'),
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
                                  },
                                )
                              : null,
                        ),

                        // Event image
                        if (e.imageUrl != null && e.imageUrl!.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              e.imageUrl!,
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          ),

                        // Title & description
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.title,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                e.description,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),

                        // Likes & comments
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          child: Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  liked ? Icons.favorite : Icons.favorite_border,
                                  color: Colors.red,
                                ),
                                onPressed: () async {
                                  if (currentUser == null) return;
                                  await _service.likeEvent(e.id, currentUser!.uid);
                                },
                              ),
                              Text('${e.likesCount} ❤️'),
                              const SizedBox(width: 16),
                              Text('${e.comments.length} 💬'),
                              const Spacer(),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EventDetailPage(event: e),
                                    ),
                                  );
                                },
                                child: const Text('View'),
                              )
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
}
