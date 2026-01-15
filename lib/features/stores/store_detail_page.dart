// lib\features\stores\store_detail_page.dart
import 'package:flutter/material.dart';
import '../../core/services/firestore_service.dart';
import '../../core/utils/helpers.dart';
import '../../models/store_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StoreDetailPage extends StatefulWidget {
  final StoreModel store;
  const StoreDetailPage({super.key, required this.store});

  @override
  State<StoreDetailPage> createState() => _StoreDetailPageState();
}

class _StoreDetailPageState extends State<StoreDetailPage> {
  final _commentController = TextEditingController();
  double _rating = 0;

  bool get isOwnerOrAdmin =>
      widget.store.ownerId == Helpers.currentUserId() || Helpers.isAdmin();

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final comment = CommentModel(
      id: FirebaseFirestore.instance.collection('tmp').doc().id,
      userId: Helpers.currentUserId(),
      text: _commentController.text.trim(),
      rating: _rating,
      createdAt: Timestamp.now(),
    );

    await FirestoreService.instance.addStoreComment(widget.store.id, comment);
    if (_rating > 0) await FirestoreService.instance.rateStore(widget.store.id, _rating);

    _commentController.clear();
    setState(() => _rating = 0);
  }

  Future<void> _reportStore() async {
    await FirestoreService.instance.reportStore(widget.store.id, Helpers.currentUserId());
    Helpers.showSnackBar(context, 'Store reported.');
  }

  Future<void> _deleteStore() async {
    await FirestoreService.instance.deleteStore(widget.store.id);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return Scaffold(
      appBar: AppBar(
        title: Text(store.name),
        actions: [
          if (isOwnerOrAdmin)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: _deleteStore,
            ),
          IconButton(icon: Icon(Icons.report), onPressed: _reportStore),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text('Type: ${store.type}'),
            Text('Barangay: ${store.barangay}'),
            Text('Rating: ${store.rating.toStringAsFixed(1)} (${store.ratingCount} ratings)'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.map),
              label: Text('Open in Maps'),
              onPressed: () => Helpers.openMap(store.location.latitude, store.location.longitude),
            ),
            const SizedBox(height: 32),
            Text('Comments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            ...store.comments.map((c) => ListTile(
                  title: Text(c.text),
                  subtitle: Text('Rating: ${c.rating}'),
                )),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              decoration: InputDecoration(labelText: 'Add a comment'),
            ),
            Row(
              children: [
                Text('Rating:'),
                Slider(
                  value: _rating,
                  onChanged: (v) => setState(() => _rating = v),
                  min: 0,
                  max: 5,
                  divisions: 5,
                  label: _rating.toString(),
                ),
              ],
            ),
            ElevatedButton(onPressed: _addComment, child: Text('Submit')),
          ],
        ),
      ),
    );
  }
}
