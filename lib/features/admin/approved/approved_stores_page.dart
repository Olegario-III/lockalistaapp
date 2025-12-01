import 'package:flutter/material.dart';
import '../../../core/services/firestore_service.dart';
import '../../../models/store_model.dart';

class ApprovedStoresPage extends StatelessWidget {
  const ApprovedStoresPage({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService.instance;

    return Scaffold(
      appBar: AppBar(title: const Text("Approved Stores")),
      body: StreamBuilder<List<StoreModel>>(
        stream: firestore.getStoresStream(status: 'approved'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final stores = snapshot.data!;
          if (stores.isEmpty) return const Center(child: Text("No approved stores yet."));

          return ListView.builder(
            itemCount: stores.length,
            itemBuilder: (context, index) {
              final s = stores[index];
              return ListTile(
                title: Text(s.name),
                subtitle: Text(s.address ?? "No address provided"),
                trailing: const Icon(Icons.check, color: Colors.grey),
              );
            },
          );
        },
      ),
    );
  }
}
