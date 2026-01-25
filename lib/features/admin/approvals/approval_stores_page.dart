// lib/features/admin/approvals/approval_stores_page.dart
import 'package:flutter/material.dart';
import '../../../core/services/firestore_service.dart';
import '../../../models/store_model.dart';

class ApprovalStoresPage extends StatelessWidget {
  const ApprovalStoresPage({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Approve Stores')),
      body: StreamBuilder<List<StoreModel>>(
        stream: firestore.getPendingStoresStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final stores = snapshot.data ?? [];

          if (stores.isEmpty) {
            return const Center(
              child: Text('No stores waiting for approval.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: stores.length,
            itemBuilder: (context, index) {
              final store = stores[index];

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(8),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: store.images.isNotEmpty
                        ? Image.network(
                            store.images.first,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.store, size: 64),
                          )
                        : const Icon(Icons.store, size: 64),
                  ),
                  title: Text(
                    store.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Type: ${store.type}'),
                      Text('Barangay: ${store.barangay}'),
                      if (store.address != null)
                        Text('Address: ${store.address}'),
                    ],
                  ),
                  isThreeLine: store.address != null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Reject
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        tooltip: 'Reject Store',
                        onPressed: () {
                          firestore.rejectStore(store.id);
                        },
                      ),

                      // Approve
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        tooltip: 'Approve Store',
                        onPressed: () {
                          firestore.approveStore(store.id);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
