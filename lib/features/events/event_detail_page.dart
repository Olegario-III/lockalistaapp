import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/event_model.dart';
import '../../core/services/firestore_service.dart';
import 'edit_event_page.dart';

class EventDetailPage extends StatefulWidget {
  final EventModel event;

  const EventDetailPage({
    super.key,
    required this.event,
  });

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  final TextEditingController _commentCtrl = TextEditingController();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  /* ================= CHECK ADMIN ================= */
  Future<void> _checkAdmin() async {
    if (currentUser == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .get();

    if (doc.exists && doc.data()?['role'] == 'admin') {
      setState(() => isAdmin = true);
    }
  }

  bool get isOwner {
    if (currentUser == null) return false;
    return currentUser!.uid == widget.event.ownerId;
  }

  bool get canEdit => isOwner || isAdmin;
  bool get canDelete => isOwner || isAdmin;

  /* ================= ADD COMMENT ================= */
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

    setState(() {
      widget.event.comments.add(comment);
    });

    _commentCtrl.clear();
    FocusScope.of(context).unfocus();
  }

  /* ================= DELETE EVENT ================= */
  Future<void> _deleteEvent() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text(
          'Are you sure you want to permanently delete this event?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await FirebaseFirestore.instance
        .collection('events')
        .doc(widget.event.id)
        .delete();

    if (!mounted) return;

    Navigator.pop(context); // go back after delete
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  /* ================= BUILD ================= */
  @override
  Widget build(BuildContext context) {
    final event = widget.event;

    return Scaffold(
      appBar: AppBar(
        title: Text(event.title),
        actions: [
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Event',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditEventPage(event: event),
                  ),
                );
              },
            ),
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Delete Event',
              onPressed: _deleteEvent,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.imageUrl != null && event.imageUrl!.isNotEmpty)
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
                  Text(
                    event.description,
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Start: ${event.startDate.toLocal().toString().split(' ')[0]}',
                  ),
                  Text(
                    'End: ${event.endDate.toLocal().toString().split(' ')[0]}',
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      const Icon(Icons.favorite, size: 18),
                      const SizedBox(width: 6),
                      Text('${event.likesCount} likes'),
                    ],
                  ),

                  const Divider(height: 32),

                  Text(
                    'Comments',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),

                  const SizedBox(height: 8),

                  if (event.comments.isEmpty)
                    const Text(
                      'No comments yet.',
                      style: TextStyle(color: Colors.grey),
                    )
                  else
                    Column(
                      children: event.comments.map((c) {
                        final canDeleteComment = currentUser != null &&
                            (currentUser!.uid == c.userId ||
                                isOwner ||
                                isAdmin);

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            c.content,
                            style: const TextStyle(fontSize: 14),
                          ),
                          subtitle: Text(
                            c.timestamp.toLocal().toString().split('.')[0],
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: canDeleteComment
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () async {
                                    await FirestoreService.instance
                                        .deleteComment(
                                      eventId: event.id,
                                      commentId: c.id,
                                    );

                                    if (!mounted) return;

                                    setState(() {
                                      widget.event.comments
                                          .removeWhere((e) => e.id == c.id);
                                    });
                                  },
                                )
                              : null,
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 16),

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
