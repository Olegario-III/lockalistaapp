// lib/features/stores/store_list_page.dart
import 'package:flutter/material.dart';
import '../../core/services/firestore_service.dart';
import '../../models/store_model.dart' as sm;
import 'store_detail_page.dart';

class StoreListPage extends StatelessWidget {
  StoreListPage({super.key});
  final FirestoreService _service = FirestoreService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stores')),
      body: StreamBuilder<List<sm.StoreModel>>(
        stream: _service.getApprovedStoresStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final stores = snapshot.data ?? [];
          if (stores.isEmpty) {
            return const Center(child: Text('No stores yet.'));
          }
          return ListView.separated(
            itemCount: stores.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final s = stores[index];
              final preview = s.images.isNotEmpty ? s.images.first : null;
              return ListTile(
                leading: preview != null ? Image.network(preview, width: 64, height: 64, fit: BoxFit.cover) : const Icon(Icons.store),
                title: Text(s.name),
                subtitle: Text('${s.averageRating.toStringAsFixed(1)} ★ • ${s.comments.length} comments'),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StoreDetailPage(store: s))),
              );
            },
          );
        },
      ),
    );
  }
}
