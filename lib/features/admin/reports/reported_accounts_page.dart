// lib/features/admin/reports/reported_accounts_page.dart
import 'package:flutter/material.dart';
import '../../../core/services/firestore_service.dart';
import '../../../models/user_model.dart';

class ReportedAccountsPage extends StatelessWidget {
  const ReportedAccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService.instance;

    return Scaffold(
      appBar: AppBar(title: const Text("Reported Accounts")),
      body: FutureBuilder<List<UserModel>>(
        future: firestore.getUsers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final users = snapshot.data!
              .where((u) => u.isReported ?? false) // Assuming 'isReported' flag exists
              .toList();
          if (users.isEmpty) return const Center(child: Text("No reported accounts."));

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final u = users[index];
              return ListTile(
                title: Text(u.name),
                subtitle: Text(u.email),
              );
            },
          );
        },
      ),
    );
  }
}
