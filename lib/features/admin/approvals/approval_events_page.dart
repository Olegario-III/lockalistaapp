import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/services/firestore_service.dart';
import '../../../models/event_model.dart';

class ApprovalEventsPage extends StatelessWidget {
  const ApprovalEventsPage({super.key});

  /// Get user (event owner) name
  Future<String> _getUserName(String userId) async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (!doc.exists) return 'Unknown User';
    final data = doc.data()!;
    return data['name'] ?? data['email'] ?? 'Unknown User';
  }

  /// Get admin name (approver)
  Future<String> _getAdminName(String adminId) async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(adminId).get();

    if (!doc.exists) return 'Admin';
    final data = doc.data()!;
    return data['name'] ?? data['email'] ?? 'Admin';
  }

  /// Check if current user is admin
  Future<bool> _isAdmin(String userId) async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (!doc.exists) return false;
    return doc.data()?['role'] == 'admin';
  }

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService.instance;
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Not authenticated')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Approve Events')),
      body: StreamBuilder<List<EventModel>>(
        stream: firestore.getPendingEventsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No pending events'));
          }

          final events = snapshot.data!;

          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];

              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// EVENT INFO
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: event.imageUrl != null &&
                                event.imageUrl!.isNotEmpty
                            ? Image.network(
                                event.imageUrl!,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.event, size: 60),
                        title: Text(event.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              event.description.isNotEmpty
                                  ? event.description
                                  : 'No description provided',
                            ),
                            const SizedBox(height: 6),
                            FutureBuilder<String>(
                              future: _getUserName(event.userId),
                              builder: (context, snap) {
                                return Text(
                                  'Posted by: ${snap.data ?? 'Loading...'}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      /// ACTION BUTTONS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            label: const Text('Delete'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            onPressed: () async {
                              await firestore.rejectEvent(event.id);
                            },
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.check),
                            label: const Text('Approve'),
                            onPressed: () async {
                              final adminId = currentUser.uid;

                              final isAdmin = await _isAdmin(adminId);
                              if (!isAdmin) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Only admins can approve events'),
                                  ),
                                );
                                return;
                              }

                              final adminName =
                                  await _getAdminName(adminId);

                              await firestore.approveEvent(
                                eventId: event.id,
                                adminId: adminId,
                                adminName: adminName,
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
