// lib/features/stores/store_detail_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/firestore_service.dart';
import '../../models/store_model.dart' as sm;

class StoreDetailPage extends StatefulWidget {
  final sm.StoreModel store;
  const StoreDetailPage({super.key, required this.store});

  @override
  State<StoreDetailPage> createState() => _StoreDetailPageState();
}

class _StoreDetailPageState extends State<StoreDetailPage> {
  final FirestoreService _service = FirestoreService.instance;
  final TextEditingController _commentCtrl = TextEditingController();
  num _selectedRating = 0;

  @override
  Widget build(BuildContext context) {
    final s = widget.store;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text(s.name)),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (s.images.isNotEmpty) AspectRatio(aspectRatio: 16/9, child: Image.network(s.images.first, fit: BoxFit.cover)),
            Padding(padding: const EdgeInsets.all(16.0), child: Text(s.description ?? '')),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text('Rating: ${s.averageRating.toStringAsFixed(1)}'),
                  const SizedBox(width: 12),
                  for (var i = 1; i <= 5; i++)
                    IconButton(
                      icon: Icon(Icons.star, color: (_selectedRating >= i) ? Colors.amber : Colors.grey),
                      onPressed: () async {
                        if (user == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login first')));
                          return;
                        }
                        await _service.rateStore(s.id, user.uid, i);
                        setState(() => _selectedRating = i);
                      },
                    ),
                ],
              ),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Comments', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            ...s.comments.map((c) {
              final likes = c.likes.length;
              final dislikes = c.dislikes.length;
              return ListTile(
                title: Text(c.uid),
                subtitle: Text(c.content),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('$likes'),
                  IconButton(
                    icon: const Icon(Icons.thumb_up_alt_outlined),
                    onPressed: () async {
                      if (user == null) return;
                      await _service.toggleCommentLikeForStore(storeId: s.id, commentIdOrKey: c.id ?? '${c.uid}_${c.timestamp}', userId: user.uid);
                      setState(() {});
                    },
                  ),
                  Text('$dislikes'),
                  IconButton(
                    icon: const Icon(Icons.thumb_down_alt_outlined),
                    onPressed: () async {
                      if (user == null) return;
                      await _service.toggleCommentDislikeForStore(storeId: s.id, commentIdOrKey: c.id ?? '${c.uid}_${c.timestamp}', userId: user.uid);
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
                Expanded(child: TextField(controller: _commentCtrl, decoration: const InputDecoration(hintText: 'Write a comment'))),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () async {
                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login first')));
                      return;
                    }
                    final comment = sm.CommentModel(
                      id: null,
                      uid: user.uid,
                      content: _commentCtrl.text,
                      timestamp: DateTime.now(),
                      likes: [],
                      dislikes: [],
                    );
                    await _service.addCommentToStore(s.id, comment);
                    _commentCtrl.clear();
                    setState(() {});
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
