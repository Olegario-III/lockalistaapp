import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/services/firestore_service.dart';
import '../../core/utils/helpers.dart';
import '../../models/store_model.dart';
import '../../models/comment_model.dart' as cm; // ✅ FIX ambiguity

class StoreDetailPage extends StatefulWidget {
  final StoreModel store;
  const StoreDetailPage({super.key, required this.store});

  @override
  State<StoreDetailPage> createState() => _StoreDetailPageState();
}

class _StoreDetailPageState extends State<StoreDetailPage> {
  final TextEditingController _commentController = TextEditingController();
  double _rating = 0;

  bool get isOwnerOrAdmin =>
      widget.store.ownerId == Helpers.currentUserId() || Helpers.isAdmin();

  /* -------------------- STORE ACTIONS -------------------- */

  Future<void> _deleteStore() async {
    await FirestoreService.instance.deleteStore(widget.store.id);
    if (!mounted) return;
    Navigator.pop(context);
  }

  /* -------------------- COMMENT ACTIONS -------------------- */

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty || _rating == 0) return;

    final comment = cm.CommentModel(
      id: FirebaseFirestore.instance.collection('tmp').doc().id,
      userId: Helpers.currentUserId(),
      username: 'Anonymous', // ✅ safe fallback
      userAvatar: '',
      text: _commentController.text.trim(),
      rating: _rating,
      likes: [],
      dislikes: [],
      createdAt: Timestamp.now(),
    );

    await FirestoreService.instance.addStoreComment(
      widget.store.id,
      comment,
    );

    await FirestoreService.instance.rateStore(
      widget.store.id,
      _rating,
    );

    _commentController.clear();
    setState(() => _rating = 0);
  }

  Future<void> _deleteComment(String commentId) async {
    await FirestoreService.instance.deleteStoreComment(
      widget.store.id,
      commentId,
    );
  }

  Future<void> _reportComment(String commentId) async {
    await FirestoreService.instance.reportStoreComment(
      storeId: widget.store.id,
      commentId: commentId,
      reportedBy: Helpers.currentUserId(),
    );
    if (!mounted) return;
    Helpers.showSnackBar(context, 'Comment reported.');
  }

  /* -------------------- UI -------------------- */

  @override
  Widget build(BuildContext context) {
    final store = widget.store;

    return Scaffold(
      appBar: AppBar(
        title: Text(store.name),
        actions: [
          if (isOwnerOrAdmin)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteStore,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Type: ${store.type}'),
          Text('Barangay: ${store.barangay}'),
          Text(
            'Rating: ${store.rating.toStringAsFixed(1)} '
            '(${store.ratingCount} ratings)',
          ),

          const SizedBox(height: 16),

          ElevatedButton.icon(
            icon: const Icon(Icons.map),
            label: const Text('Open in Maps'),
            onPressed: () => Helpers.openMap(
              store.location.latitude,
              store.location.longitude,
            ),
          ),

          const SizedBox(height: 32),

          /* -------------------- COMMENTS -------------------- */
          const Text(
            'Comments',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          StreamBuilder<QuerySnapshot>(
            stream: FirestoreService.instance.storeCommentsStream(store.id),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.data!.docs.isEmpty) {
                return const Text('No comments yet.');
              }

              return Column(
                children: snapshot.data!.docs.map((doc) {
                  final comment = cm.CommentModel.fromFirestore(doc);
                  final canDelete =
                      comment.userId == Helpers.currentUserId() ||
                          Helpers.isAdmin();

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comment.username,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(comment.text),
                          Text('Rating: ${comment.rating}'),

                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.thumb_up, size: 18),
                                onPressed: () =>
                                    FirestoreService.instance
                                        .toggleStoreCommentLike(
                                  storeId: store.id,
                                  commentId: comment.id,
                                  userId: Helpers.currentUserId(),
                                ),
                              ),
                              Text('${comment.likes.length}'),

                              IconButton(
                                icon: const Icon(Icons.thumb_down, size: 18),
                                onPressed: () =>
                                    FirestoreService.instance
                                        .toggleStoreCommentDislike(
                                  storeId: store.id,
                                  commentId: comment.id,
                                  userId: Helpers.currentUserId(),
                                ),
                              ),
                              Text('${comment.dislikes.length}'),

                              const Spacer(),

                              IconButton(
                                icon: const Icon(Icons.report, size: 18),
                                onPressed: () =>
                                    _reportComment(comment.id),
                              ),

                              if (canDelete)
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 18),
                                  onPressed: () =>
                                      _deleteComment(comment.id),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 24),

          /* -------------------- ADD COMMENT -------------------- */
          TextField(
            controller: _commentController,
            decoration: const InputDecoration(
              labelText: 'Add a comment',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              const Text('Rating'),
              Expanded(
                child: Slider(
                  value: _rating,
                  min: 0,
                  max: 5,
                  divisions: 5,
                  label: _rating.toString(),
                  onChanged: (v) => setState(() => _rating = v),
                ),
              ),
            ],
          ),

          ElevatedButton(
            onPressed: _addComment,
            child: const Text('Submit Comment'),
          ),
        ],
      ),
    );
  }
}
