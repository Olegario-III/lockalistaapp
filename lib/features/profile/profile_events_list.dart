// lib/features/profile/profile_events_list.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/event_model.dart';
import '../../core/services/firestore_service.dart';
import '../events/event_detail_page.dart';

class ProfileEventsList extends StatelessWidget {
  final String userId;

  const ProfileEventsList({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService.instance.userEventsStream(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        if (snapshot.data!.docs.isEmpty) {
          return const Text('No events posted.');
        }

        final events = snapshot.data!.docs
            .map((doc) => EventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Events',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...events.map((event) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: Text(event.title),
                  subtitle: Text(
                    'Start: ${event.startDate.toLocal().toString().split(' ')[0]}',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventDetailPage(event: event),
                      ),
                    );
                  },
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
