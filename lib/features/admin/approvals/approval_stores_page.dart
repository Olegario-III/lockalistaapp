// lib/features/admin/approvals/approval_stores_page.dart
import 'package:flutter/material.dart';
import '../../../core/services/firestore_service.dart';
import '../../../models/store_model.dart';

class ApprovalStoresPage extends StatelessWidget {
  const ApprovalStoresPage({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text("Approve Stores")),
      body: StreamBuilder<List<StoreModel>>(
        stream: firestore.getStoresStream(onlyPending: true),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final stores = snapshot.data!;
          if (stores.isEmpty) return const Center(child: Text("No stores to approve."));

          return ListView.builder(
            itemCount: stores.length,
            itemBuilder: (context, index) {
              final s = stores[index];
              return ListTile(
                title: Text(s.name),
                subtitle: Text(s.address),
                trailing: IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () => firestore.approveStore(s.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
