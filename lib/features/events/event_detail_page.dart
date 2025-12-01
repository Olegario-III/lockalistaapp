// lib/features/events/event_detail_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/firestore_service.dart';
import '../../models/event_model.dart' as em;

class EventDetailPage extends StatefulWidget {
  final em.EventModel event;
  const EventDetailPage({super.key, required this.event});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  final FirestoreService _service = const FirestoreService();
  final TextEditingController _commentCtrl = TextEditingController();
  bool _processingLike = false;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final e = widget.event;

    return Scaffold(
      appBar: AppBar(title: Text(e.title)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (e.imageUrl != null && e.imageUrl!.isNotEmpty)
              AspectRatio(aspectRatio: 16 / 9, child: Image.network(e.imageUrl!, fit: BoxFit.cover)),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(e.description),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(e.likesList.contains(user?.uid) ? Icons.favorite : Icons.favorite_border,
                        color: Colors.red),
                    onPressed: _processingLike
                        ? null
                        : () async {
                            if (user == null) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login first')));
                              return;
                            }
                            setState(() => _processingLike = true);
                            await _service.likeEvent(e.id, user.uid);
                            setState(() => _processingLike = false);
                          },
                  ),
                  Text('${e.likesCount}'),
                  const SizedBox(width: 16),
                  Text('${e.comments.length} comments'),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Text('Comments', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            ...e.comments.map((c) {
              // em.CommentModel shape: id, uid, content/text, timestamp, likes, dislikes
              final likes = c.likes.length;
              final dislikes = c.dislikes.length;
              return ListTile(
                title: Text(c.uid), // show uid or you may map to username
                subtitle: Text(c.content),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('$likes'),
                  IconButton(
                    icon: const Icon(Icons.thumb_up_alt_outlined),
                    onPressed: () async {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) return;
                      await _service.toggleCommentLike(
                          eventId: e.id, commentIdOrKey: c.id ?? '${c.uid}_${c.timestamp}', userId: user.uid);
                      setState(() {});
                    },
                  ),
                  Text('$dislikes'),
                  IconButton(
                    icon: const Icon(Icons.thumb_down_alt_outlined),
                    onPressed: () async {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) return;
                      await _service.toggleCommentDislike(
                          eventId: e.id, commentIdOrKey: c.id ?? '${c.uid}_${c.timestamp}', userId: user.uid);
                      setState(() {});
                    },
                  ),
                ]),
              );
            }),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                Expanded(
                  child: TextField(controller: _commentCtrl, decoration: const InputDecoration(hintText: 'Write a comment')),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login first')));
                      return;
                    }
                    final comment = em.CommentModel(
                      id: null,
                      uid: user.uid,
                      content: _commentCtrl.text,
                      timestamp: DateTime.now(),
                      likes: [],
                      dislikes: [],
                    );
                    await _service.addCommentToEvent(e.id, comment);
                    _commentCtrl.clear();
                    setState(() {}); // re-read doc on next render (stream will also update)
                  },
                ),
              ]),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
