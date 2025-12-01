// lib/features/admin/approved/approved_events_page.dart
import 'package:flutter/material.dart';
import '../../../core/services/firestore_service.dart';
import '../../../models/event_model.dart';

class ApprovedEventsPage extends StatelessWidget {
  const ApprovedEventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text("Approved Events")),
      body: StreamBuilder<List<EventModel>>(
        stream: firestore.getEventsStream(onlyPending: false),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final events = snapshot.data!;
          if (events.isEmpty) return const Center(child: Text("No approved events yet."));

          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final e = events[index];
              return ListTile(
                title: Text(e.title),
                subtitle: Text(e.description),
                trailing: const Icon(Icons.check, color: Colors.grey),
              );
            },
          );
        },
      ),
    );
  }
}
