// lib/features/events/event_detail_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/event_model.dart';
import '../../core/services/firestore_service.dart';

class EventDetailPage extends StatefulWidget {
  final EventModel event;

  const EventDetailPage({super.key, required this.event});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  final TextEditingController _commentCtrl = TextEditingController();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  /// Load event owner profile
  Future<Map<String, String?>> _loadOwnerProfile() async {
    if (widget.event.ownerName.isNotEmpty) {
      return {
        'name': widget.event.ownerName,
        'avatar': widget.event.ownerAvatar,
      };
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.event.ownerId)
        .get();

    final data = doc.data();

    return {
      'name': data?['name'] ?? 'Unknown',
      'avatar': data?['image'],
    };
  }

  /// Load comment user's name & avatar
  Future<Map<String, String?>> _loadCommentUser(String userId) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    final data = doc.data();
    return {
      'name': data?['name'] ?? 'Unknown',
      'avatar': data?['image'],
    };
  }

  /// Add comment
  Future<void> _addComment() async {
    if (_commentCtrl.text.trim().isEmpty || currentUser == null) return;

    final commentId = DateTime.now().millisecondsSinceEpoch.toString();

    final comment = CommentModel(
      id: commentId,
      userId: currentUser!.uid,
      content: _commentCtrl.text.trim(),
      timestamp: DateTime.now(),
    );

    await FirestoreService.instance.addCommentToEvent(
      widget.event.id,
      comment,
    );

    if (!mounted) return;
    _commentCtrl.clear();
    FocusScope.of(context).unfocus();

    setState(() {
      widget.event.comments.add(comment);
    });
  }

  /// Report comment (placeholder)
  void _reportComment(CommentModel comment) {
    // You can implement report logic here (e.g., add to Firestore 'reports' collection)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reported comment: ${comment.content}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;

    return Scaffold(
      appBar: AppBar(title: Text(event.title)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.imageUrl != null)
              Image.network(
                event.imageUrl!,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 👤 Owner info
                  FutureBuilder<Map<String, String?>>(
                    future: _loadOwnerProfile(),
                    builder: (context, snapshot) {
                      final name = snapshot.data?['name'] ?? 'Unknown';
                      final avatar = snapshot.data?['avatar'];

                      return Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage:
                                avatar != null && avatar.isNotEmpty
                                    ? NetworkImage(avatar)
                                    : null,
                            child: avatar == null || avatar.isEmpty
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // 📝 Description
                  Text(event.description, style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 16),

                  // 📅 Dates
                  Text(
                      'Start: ${event.startDate.toLocal().toString().split(' ')[0]}'),
                  Text(
                      'End: ${event.endDate.toLocal().toString().split(' ')[0]}'),
                  const SizedBox(height: 16),

                  // ❤️ Likes
                  Row(
                    children: [
                      const Icon(Icons.favorite, size: 18),
                      const SizedBox(width: 6),
                      Text('${event.likesCount} likes'),
                    ],
                  ),
                  const Divider(height: 32),

                  // 💬 Comments header
                  Text(
                    'Comments',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),

                  // 💬 Comment list
                  if (event.comments.isEmpty)
                    const Text(
                      'No comments yet.',
                      style: TextStyle(color: Colors.grey),
                    )
                  else
                    Column(
                      children: event.comments.map((c) {
                        return FutureBuilder<Map<String, String?>>(
                          future: _loadCommentUser(c.userId),
                          builder: (context, snapshot) {
                            final name = snapshot.data?['name'] ?? 'Unknown';
                            final avatar = snapshot.data?['avatar'];

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundImage: avatar != null && avatar.isNotEmpty
                                    ? NetworkImage(avatar)
                                    : null,
                                child: avatar == null || avatar.isEmpty
                                    ? const Icon(Icons.person, size: 16)
                                    : null,
                              ),
                              title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.content, style: const TextStyle(fontSize: 14)),
                                  Text(c.timestamp.toLocal().toString().split('.')[0],
                                      style: const TextStyle(fontSize: 11)),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.report, size: 18, color: Colors.redAccent),
                                onPressed: () => _reportComment(c),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 16),

                  // ✍️ Add comment
                  if (currentUser != null)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentCtrl,
                            decoration: const InputDecoration(
                              hintText: 'Write a comment...',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: _addComment,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
