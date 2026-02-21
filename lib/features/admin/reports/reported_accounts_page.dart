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
class ReportedUsersList extends StatefulWidget {
  const ReportedUsersList({super.key});

  @override
  State<ReportedUsersList> createState() => _ReportedUsersListState();
}

class _ReportedUsersListState extends State<ReportedUsersList> {
  final firestore = FirestoreService.instance;
  final Set<String> _processing = {}; // track users being processed

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore.reportedUsersStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data?.docs ?? [];

        if (users.isEmpty) {
          return const Center(child: Text('No reported users 🎉'));
        }

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
            final isProcessing = _processing.contains(userId);

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
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (isProcessing) return;
                    setState(() => _processing.add(userId));

                    try {
                      switch (value) {
                        case 'warn':
                          await firestore.warnUser(userId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('User warned ⚠')),
                          );
                          break;
                        case 'ban':
                          await firestore.tempBanUser(userId, 7);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('User banned ⛔')),
                          );
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('User deleted 🗑')),
                            );
                          }
                          break;
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    } finally {
                      setState(() => _processing.remove(userId));
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'warn', child: Text('⚠ Warn User')),
                    PopupMenuItem(value: 'ban', child: Text('⛔ Temp Ban (7 days)')),
                    PopupMenuItem(value: 'delete', child: Text('🗑 Delete User')),
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
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No reported store comments 🎉'));
        }

        final reports = snapshot.data!.docs;

        return ListView.builder(
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final doc = reports[index];
            final data = doc.data() as Map<String, dynamic>;

            final storeName = data['storeName'] ?? 'Unknown Store';
            final reportedUserName = data['reportedUserName'] ?? 'Unknown User';
            final reportedByName = data['reportedByName'] ?? 'Unknown Reporter';
            final reason = data['reason'] ?? 'No reason';
            final createdAt = data['createdAt'] is Timestamp
                ? (data['createdAt'] as Timestamp).toDate()
                : null;

            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                title: Text('Store: $storeName'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Commenter: $reportedUserName'),
                    Text('Reported by: $reportedByName'),
                    Text('Reason: $reason'),
                    Text('Date: ${createdAt ?? "Unknown"}'),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    try {
                      await firestore.deleteReport(doc.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Report deleted 🗑')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
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
