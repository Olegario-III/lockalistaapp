import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/firestore_service.dart';
import '../../../models/store_model.dart';

class ApprovalStoresPage extends StatefulWidget {
  const ApprovalStoresPage({super.key});

  @override
  State<ApprovalStoresPage> createState() => _ApprovalStoresPageState();
}

class _ApprovalStoresPageState extends State<ApprovalStoresPage> {
  final firestore = FirestoreService.instance;
  final currentUser = FirebaseAuth.instance.currentUser;

  String? adminName;

  @override
  void initState() {
    super.initState();
    _loadAdminName();
  }

  Future<void> _loadAdminName() async {
    if (currentUser == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .get();

    if (!mounted) return;

    setState(() {
      adminName = doc.data()?['name'] ?? 'Admin';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null || adminName == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Approve Stores')),
      body: StreamBuilder<List<StoreModel>>(
        stream: firestore.getPendingStoresStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
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
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: store.images.isNotEmpty
                              ? Image.network(
                                  store.images.first,
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
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
                      ),

                      const SizedBox(height: 12),

                      /// 🔘 ACTION BUTTONS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          /// 🗑 DELETE (Reject)
                          OutlinedButton.icon(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            label: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Delete Store'),
                                  content: const Text(
                                    'Are you sure you want to delete this store?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                await firestore.rejectStore(store.id);
                              }
                            },
                          ),

                          const SizedBox(width: 12),

                          /// ✅ APPROVE
                          ElevatedButton.icon(
                            icon: const Icon(Icons.check),
                            label: const Text('Approve'),
                            onPressed: () async {
                              await firestore.approveStore(
                                storeId: store.id,
                                adminId: currentUser!.uid,
                                adminName: adminName!,
                              );
                            },
                          ),
                        ],
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
