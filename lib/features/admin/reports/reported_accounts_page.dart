// lib/features/admin/reports/reported_accounts_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/firestore_service.dart';

class ReportedAccountsPage extends StatelessWidget {
  const ReportedAccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reports'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Users'),
              Tab(text: 'Store Comments'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ReportedUsersList(),
            ReportedStoreCommentsList(),
          ],
        ),
      ),
    );
  }
}

/// =====================
/// Tab 1: Reported Users
/// =====================
class ReportedUsersList extends StatelessWidget {
  const ReportedUsersList({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService.instance;

    return StreamBuilder<QuerySnapshot>(
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
                  backgroundColor: isBanned ? Colors.red : Colors.orange,
                  child: Text(reports.toString()),
                ),
                title: Text(email),
                subtitle: Text(
                  'Reports: $reports | Warnings: $warnings | ${isBanned ? "BANNED" : "Active"}',
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
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
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
    );
  }
}

/// ===============================
/// Tab 2: Reported Store Comments
/// ===============================
class ReportedStoreCommentsList extends StatelessWidget {
  const ReportedStoreCommentsList({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService.instance;

    return StreamBuilder<QuerySnapshot>(
      stream: firestore.reportedStoreCommentsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final reports = snapshot.data!.docs;

        if (reports.isEmpty) {
          return const Center(child: Text('No reported store comments 🎉'));
        }

        return ListView.builder(
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final doc = reports[index];
            final data = doc.data() as Map<String, dynamic>;

            final storeName = data['storeName'] ?? 'Unknown Store';
            final reportedUserName =
                data['reportedUserName'] ?? 'Unknown User';
            final reportedByName =
                data['reportedByName'] ?? 'Unknown Reporter';
            final reason = data['reason'] ?? 'No reason';
            final createdAt = data['createdAt'] as Timestamp?;

            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                title: Text('Store: $storeName'),
                subtitle: Text(
                  'Commenter: $reportedUserName\n'
                  'Reported by: $reportedByName\n'
                  'Reason: $reason\n'
                  'Date: ${createdAt != null ? createdAt.toDate() : "Unknown"}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await firestore.deleteReport(doc.id);
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
