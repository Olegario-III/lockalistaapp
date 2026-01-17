import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/firestore_service.dart';
import '../../models/event_model.dart' as em;
import '../profile/profile_page.dart';

class EventDetailPage extends StatefulWidget {
  final em.EventModel event;

  const EventDetailPage({super.key, required this.event});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  final _service = FirestoreService.instance;
  final TextEditingController _commentCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final e = widget.event;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(title: Text(e.title)),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ─── Top Info: Poster + Approved by ───
            ListTile(
              leading: GestureDetector(
                onTap: () {
                  if (e.ownerId.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfilePage(userId: e.ownerId),
                      ),
                    );
                  }
                },
                child: CircleAvatar(
                  backgroundImage: NetworkImage(
                    e.ownerAvatarUrl ??
                        'https://i.pravatar.cc/150?u=${e.ownerId}',
                  ),
                ),
              ),
              title: Text(e.ownerId),
              subtitle: Text(
                e.approvedByName != null && e.approvedByName!.isNotEmpty
                    ? 'Approved by: ${e.approvedByName}'
                    : 'Pending approval',
              ),
              trailing: Text(
                e.timestamp != null
                    ? '${e.timestamp!.toLocal()}'.split(' ')[0]
                    : '',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),

            // ─── Event Image ───
            if (e.imageUrl != null && e.imageUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Image.network(
                  e.imageUrl!,
                  width: screenWidth * 0.9,
                  fit: BoxFit.cover,
                ),
              ),

            // ─── Description ───
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(e.description),
            ),

            // ─── Likes & Comments ───
            StreamBuilder<em.EventModel>(
              stream: _service.getEventStream(e.id),
              builder: (context, snap) {
                if (!snap.hasData) return const SizedBox();
                final liveEvent = snap.data!;
                final liked = liveEvent.likesList.contains(user?.uid);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          liked ? Icons.favorite : Icons.favorite_border,
                          color: Colors.red,
                        ),
                        onPressed: () async {
                          if (user == null) return;
                          await _service.likeEvent(e.id, user.uid);
                        },
                      ),
                      Text('${liveEvent.likesCount}'),
                      const SizedBox(width: 16),
                      Text('${liveEvent.comments.length} comments'),
                    ],
                  ),
                );
              },
            ),

            const Divider(),

            // ─── Comments ───
            StreamBuilder<em.EventModel>(
              stream: _service.getEventStream(e.id),
              builder: (context, snap) {
                if (!snap.hasData) return const SizedBox();
                final liveEvent = snap.data!;

                return Column(
                  children: liveEvent.comments.map((c) {
                    return FutureBuilder<String>(
                      future: _service.getUserName(c.userId),
                      builder: (context, userSnap) {
                        final commenterName = userSnap.data ?? 'Loading...';
                        return ListTile(
                          leading: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProfilePage(userId: c.userId),
                                ),
                              );
                            },
                            child: CircleAvatar(
                              backgroundImage: NetworkImage(
                                'https://i.pravatar.cc/150?u=${c.userId}',
                              ),
                            ),
                          ),
                          title: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProfilePage(uid: c.userId),
                                ),
                              );
                            },
                            child: Text(commenterName),
                          ),
                          subtitle: Text(c.content),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${c.likes.length}'),
                              IconButton(
                                icon: const Icon(Icons.thumb_up_alt_outlined),
                                onPressed: () async {
                                  if (user == null) return;
                                  await _service.toggleCommentLike(
                                    eventId: e.id,
                                    commentId: c.id,
                                    userId: user.uid,
                                  );
                                },
                              ),
                              Text('${c.dislikes.length}'),
                              IconButton(
                                icon: const Icon(Icons.thumb_down_alt_outlined),
                                onPressed: () async {
                                  if (user == null) return;
                                  await _service.toggleCommentDislike(
                                    eventId: e.id,
                                    commentId: c.id,
                                    userId: user.uid,
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),

            // ─── Add comment ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentCtrl,
                      decoration:
                          const InputDecoration(hintText: 'Write a comment'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () async {
                      if (user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Login first')),
                        );
                        return;
                      }

                      final comment = em.CommentModel(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        userId: user.uid,
                        content: _commentCtrl.text,
                        timestamp: DateTime.now(),
                      );

                      await _service.addCommentToEvent(e.id, comment);
                      _commentCtrl.clear();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
