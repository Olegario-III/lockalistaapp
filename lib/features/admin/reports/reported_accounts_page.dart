// lib/features/admin/reports/reported_accounts_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/firestore_service.dart';

class ReportedAccountsPage extends StatelessWidget {
  const ReportedAccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reported Accounts'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore.reportedUsersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No reported users 🎉'),
            );
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final doc = users[index];
              final data = doc.data() as Map<String, dynamic>;

              final userId = doc.id;
              final email = data['email'] ?? 'No email';
              final reports = data['reportCount'] ?? 0;
              final warnings = data['warningCount'] ?? 0;
              final isBanned = data['isBanned'] ?? false;

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        isBanned ? Colors.red : Colors.orange,
                    child: Text(reports.toString()),
                  ),
                  title: Text(email),
                  subtitle: Text(
                    'Reports: $reports | Warnings: $warnings | '
                    '${isBanned ? "BANNED" : "Active"}',
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      switch (value) {
                        case 'warn':
                          await firestore.warnUser(userId);
                          break;

                        case 'ban':
                          await firestore.tempBanUser(userId, 7);
                          break;

                        case 'delete':
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Delete User'),
                              content: const Text(
                                'This will permanently delete the user and all reports. Continue?',
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
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await firestore.deleteUserCompletely(userId);
                          }
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'warn',
                        child: Text('⚠ Warn User'),
                      ),
                      const PopupMenuItem(
                        value: 'ban',
                        child: Text('⛔ Temp Ban (7 days)'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('🗑 Delete User'),
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
