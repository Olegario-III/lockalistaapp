import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/services/firestore_service.dart';
import '../../core/utils/helpers.dart';
import '../../models/store_model.dart';
import '../../models/comment_model.dart' as cm;
import '../profile/profile_page.dart';
import 'edit_store_page.dart';

class StoreDetailPage extends StatefulWidget {
  final StoreModel store;

  const StoreDetailPage({super.key, required this.store});

  @override
  State<StoreDetailPage> createState() => _StoreDetailPageState();
}

class _StoreDetailPageState extends State<StoreDetailPage> {
  final TextEditingController _commentController = TextEditingController();
  double _rating = 0;

  /// Avatar cache for both owner and comment authors
  final Map<String, String> _avatarCache = {};

  /// Get avatar from cache or Firestore
  Future<String?> _getAvatar(String userId, String? currentUrl) async {
    if (currentUrl != null && currentUrl.trim().isNotEmpty) {
      _avatarCache[userId] = currentUrl;
      return currentUrl;
    }
    if (_avatarCache.containsKey(userId)) return _avatarCache[userId];

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final avatar = (doc.data()?['image'] ?? '') as String;
      _avatarCache[userId] = avatar;
      return avatar.isNotEmpty ? avatar : null;
    } catch (_) {
      return null;
    }
  }

  bool get isOwnerOrAdmin =>
      widget.store.ownerId == Helpers.currentUserId() || Helpers.isAdmin();

  /* ================= STORE ACTIONS ================= */
  Future<void> _deleteStore() async {
    await FirestoreService.instance.deleteStore(widget.store.id);
    if (!mounted) return;
    Navigator.pop(context);
  }

  /* ================= COMMENT ACTIONS ================= */
  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty || _rating == 0) return;

    final comment = cm.CommentModel(
      id: FirebaseFirestore.instance.collection('tmp').doc().id,
      userId: Helpers.currentUserId(),
      userName: Helpers.currentUserName(),
      userAvatar: Helpers.currentUserAvatar(),
      text: _commentController.text.trim(),
      rating: _rating,
      createdAt: Timestamp.now(),
      likes: [],
      dislikes: [],
    );

    await FirestoreService.instance.addStoreComment(widget.store.id, comment);
    await FirestoreService.instance.rateStore(widget.store.id, _rating);

    _commentController.clear();
    setState(() => _rating = 0);
  }

  Future<void> _deleteComment(String commentId) async {
    await FirestoreService.instance.deleteStoreComment(widget.store.id, commentId);
  }

  Future<void> _reportComment(cm.CommentModel comment) async {
    final currentUserId = Helpers.currentUserId();
    final currentUserName = Helpers.currentUserName();

    if (comment.userId == currentUserId) {
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
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Report Comment'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: reasons.map((reason) {
                  return RadioListTile<String>(
                    title: Text(reason),
                    value: reason,
                    groupValue: selectedReason,
                    onChanged: (value) => setState(() => selectedReason = value),
                  );
                }).toList(),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: selectedReason == null ? null : () => Navigator.pop(context, true),
                  child: const Text('Report'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || selectedReason == null) return;

    try {
      await FirestoreService.instance.reportStoreComment(
        storeId: widget.store.id,
        storeName: widget.store.name,
        commentId: comment.id,
        reportedUserId: comment.userId,
        reportedUserName: comment.userName ?? '',
        reportedBy: currentUserId,
        reportedByName: currentUserName,
        reason: selectedReason!,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment reported successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Widget _buildStarRating(double value, {void Function(double)? onChanged}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        return IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: Icon(starValue <= value ? Icons.star : Icons.star_border, color: Colors.amber),
          onPressed: onChanged == null ? null : () => onChanged(starValue.toDouble()),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;

    return Scaffold(
      appBar: AppBar(
        title: Text(store.name),
        actions: [
          if (isOwnerOrAdmin) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditStorePage(store: store))),
            ),
            IconButton(icon: const Icon(Icons.delete), onPressed: _deleteStore),
          ],
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (store.images.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(store.images.first, height: 220, width: double.infinity, fit: BoxFit.cover),
            ),
          const SizedBox(height: 16),
          // Store Owner Avatar
          FutureBuilder<String?>(
            future: _getAvatar(store.ownerId, null),
            builder: (context, snapshot) {
              final avatarUrl = snapshot.data;
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProfilePage(userId: store.ownerId)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                      child: avatarUrl == null ? const Icon(Icons.person) : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Owner', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text('Type: ${store.type}'),
          Text('Barangay: ${store.barangay}'),
          if (store.address != null && store.address!.isNotEmpty) Text('Address: ${store.address}'),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildStarRating(store.averageRating),
              const SizedBox(width: 8),
              Text('(${store.ratingCount})'),
            ],
          ),
          if (store.description != null && store.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(store.description!),
          ],
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.map),
            label: const Text('Open in Maps'),
            onPressed: () => Helpers.openMap(store.location.latitude, store.location.longitude),
          ),
          const SizedBox(height: 32),
          const Text('Comments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirestoreService.instance.storeCommentsStream(store.id),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              if (snapshot.data!.docs.isEmpty) return const Text('No comments yet.');

              final comments = snapshot.data!.docs
                  .map((doc) => cm.CommentModel.fromMap(doc.data() as Map<String, dynamic>))
                  .toList();

              return Column(
                children: comments.map((comment) {
                  final canDelete = comment.userId == Helpers.currentUserId() || Helpers.isAdmin();
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Commenter Avatar
                              FutureBuilder<String?>(
                                future: _getAvatar(comment.userId, comment.userAvatar),
                                builder: (context, snapshot) {
                                  final avatarUrl = snapshot.data;
                                  return GestureDetector(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => ProfilePage(userId: comment.userId)),
                                    ),
                                    child: CircleAvatar(
                                      radius: 18,
                                      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                                      child: avatarUrl == null ? const Icon(Icons.person, size: 18) : null,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  comment.userName ?? 'Anonymous',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Text(comment.createdAt.toDate().toString(), style: const TextStyle(fontSize: 11)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildStarRating(comment.rating),
                          const SizedBox(height: 6),
                          Text(comment.text),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.thumb_up, size: 18),
                                onPressed: () => FirestoreService.instance.toggleStoreCommentLike(
                                  storeId: store.id,
                                  commentId: comment.id,
                                  userId: Helpers.currentUserId(),
                                ),
                              ),
                              Text('${comment.likes.length}'),
                              IconButton(
                                icon: const Icon(Icons.thumb_down, size: 18),
                                onPressed: () => FirestoreService.instance.toggleStoreCommentDislike(
                                  storeId: store.id,
                                  commentId: comment.id,
                                  userId: Helpers.currentUserId(),
                                ),
                              ),
                              Text('${comment.dislikes.length}'),
                              const Spacer(),
                              IconButton(icon: const Icon(Icons.report, size: 18), onPressed: () => _reportComment(comment)),
                              if (canDelete) IconButton(icon: const Icon(Icons.delete, size: 18), onPressed: () => _deleteComment(comment.id)),
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
              const Text('Your rating'),
              const SizedBox(width: 8),
              _buildStarRating(_rating, onChanged: (v) => setState(() => _rating = v)),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: _addComment, child: const Text('Submit Comment')),
        ],
      ),
    );
  }
}
