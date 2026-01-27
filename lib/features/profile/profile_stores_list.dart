// lib/features/profile/profile_stores_list.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/store_model.dart';
import '../../core/services/firestore_service.dart';
import '../stores/store_detail_page.dart';

class ProfileStoresList extends StatelessWidget {
  final String userId;

  const ProfileStoresList({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService.instance.userStoresStream(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        if (snapshot.data!.docs.isEmpty) {
          return const Text('No stores added.');
        }

        final stores = snapshot.data!.docs
            .map((doc) => StoreModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Stores',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...stores.map((store) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: Text(store.name),
                  subtitle: Text(store.type),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StoreDetailPage(store: store),
                      ),
                    );
                  },
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }
}
