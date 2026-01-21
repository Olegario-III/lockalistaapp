// lib/features/events/event_detail_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/event_model.dart';
import '../../core/services/firestore_service.dart';
import 'edit_event_page.dart';

class EventDetailPage extends StatefulWidget {
  final EventModel event;

  const EventDetailPage({super.key, required this.event});

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

  Future<void> _reportComment(CommentModel comment) async {
    if (currentUser == null) return;

    if (currentUser!.uid == comment.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You can't report your own comment")),
      );
      return;
    }

    const reasons = [
      'Spam',
      'Harassment',
      'Hate speech',
      'Inappropriate content',
      'Scam',
    ];

    String? selectedReason;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Report Comment'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: reasons.map((reason) {
                return RadioListTile<String>(
                  title: Text(reason),
                  value: reason,
                  groupValue: selectedReason,
                  onChanged: (value) {
                    setState(() => selectedReason = value);
                  },
                );
              }).toList(),
            );
          },
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
      ),
    );

    if (confirmed != true || selectedReason == null) return;

    try {
      await FirestoreService.instance.reportComment(
        eventId: widget.event.id,
        commentId: comment.id,
        reportedUserId: comment.userId,
        reportedBy: currentUser!.uid,
        reason: selectedReason!,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment reported successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _toggleLike(CommentModel comment) async {
    if (currentUser == null) return;

    await FirestoreService.instance.toggleCommentLike(
      eventId: widget.event.id,
      commentId: comment.id,
      userId: currentUser!.uid,
    );

    setState(() {
      final idx =
          widget.event.comments.indexWhere((element) => element.id == comment.id);
      if (idx != -1) {
        final likes = widget.event.comments[idx].likes;
        final dislikes = widget.event.comments[idx].dislikes;

        if (likes.contains(currentUser!.uid)) {
          likes.remove(currentUser!.uid);
        } else {
          likes.add(currentUser!.uid);
          dislikes.remove(currentUser!.uid);
        }
      }
    });
  }

  Future<void> _toggleDislike(CommentModel comment) async {
    if (currentUser == null) return;

    await FirestoreService.instance.toggleCommentDislike(
      eventId: widget.event.id,
      commentId: comment.id,
      userId: currentUser!.uid,
    );

    setState(() {
      final idx =
          widget.event.comments.indexWhere((element) => element.id == comment.id);
      if (idx != -1) {
        final likes = widget.event.comments[idx].likes;
        final dislikes = widget.event.comments[idx].dislikes;

        if (dislikes.contains(currentUser!.uid)) {
          dislikes.remove(currentUser!.uid);
        } else {
          dislikes.add(currentUser!.uid);
          likes.remove(currentUser!.uid);
        }
      }
    });
  }

  Future<void> _deleteComment(CommentModel comment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirestoreService.instance.deleteComment(
        eventId: widget.event.id,
        commentId: comment.id,
      );
      if (!mounted) return;
      setState(() {
        widget.event.comments.removeWhere((e) => e.id == comment.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;

    return Scaffold(
      appBar: AppBar(
        title: Text(event.title),
        actions: [
          if (currentUser != null && currentUser!.uid == event.ownerId)
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
        ],
      ),
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

                            final canDelete = currentUser != null &&
                                (currentUser!.uid == c.userId ||
                                    currentUser!.uid == event.ownerId ||
                                    isAdmin);

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
                              title: Text(name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.content, style: const TextStyle(fontSize: 14)),
                                  Text(
                                      c.timestamp.toLocal().toString().split('.')[0],
                                      style: const TextStyle(fontSize: 11)),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.thumb_up,
                                          size: 18,
                                          color: c.likes.contains(currentUser?.uid)
                                              ? Colors.blue
                                              : Colors.grey,
                                        ),
                                        onPressed: () => _toggleLike(c),
                                      ),
                                      Text('${c.likes.length}'),
                                      const SizedBox(width: 12),
                                      IconButton(
                                        icon: Icon(
                                          Icons.thumb_down,
                                          size: 18,
                                          color: c.dislikes.contains(currentUser?.uid)
                                              ? Colors.red
                                              : Colors.grey,
                                        ),
                                        onPressed: () => _toggleDislike(c),
                                      ),
                                      Text('${c.dislikes.length}'),
                                      const SizedBox(width: 12),
                                      IconButton(
                                        icon: const Icon(Icons.report,
                                            size: 18, color: Colors.redAccent),
                                        onPressed: () => _reportComment(c),
                                      ),
                                      if (canDelete)
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              size: 18, color: Colors.red),
                                          onPressed: () => _deleteComment(c),
                                        ),
                                    ],
                                  )
                                ],
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
