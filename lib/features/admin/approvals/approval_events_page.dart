// lib/features/admin/approvals/approval_events_page.dart

import 'package:flutter/material.dart';
import '../../../core/services/firestore_service.dart';
import '../../../models/event_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ApprovalEventsPage extends StatelessWidget {
  const ApprovalEventsPage({super.key});

  Future<String> _getUserName(String userId) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (!doc.exists) return 'Unknown User';
    final data = doc.data()!;
    return data['name'] ?? data['email'] ?? 'Unknown User';
  }

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Approve Events'),
      ),
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
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(8),
                  leading: event.imageUrl != null && event.imageUrl!.isNotEmpty
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
                      const SizedBox(height: 4),
                      FutureBuilder<String>(
                        future: _getUserName(event.userId),
                        builder: (context, userSnapshot) {
                          final userName = userSnapshot.data ?? 'Loading...';
                          return Text(
                            'Posted by: $userName',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          );
                        },
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        tooltip: 'Reject',
                        onPressed: () => firestore.rejectEvent(event.id),
                      ),
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        tooltip: 'Approve',
                        onPressed: () => firestore.approveEvent(event.id),
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
