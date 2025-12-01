// lib/features/admin/approvals/approval_events_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/firestore_service.dart';
import '../../../models/event_model.dart' as em;
import '../../events/event_detail_page.dart';

class ApprovalEventsPage extends StatelessWidget {
  final FirestoreService _service = FirestoreService();

  ApprovalEventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Approve Events')),
      body: StreamBuilder<List<em.EventModel>>(
        stream: _service.getEventsStream(status: 'pending'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final events = snapshot.data!;
          if (events.isEmpty) return const Center(child: Text('No pending events.'));

          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final e = events[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: e.imageUrl != null && e.imageUrl!.isNotEmpty
                      ? Image.network(e.imageUrl!, width: 56, height: 56, fit: BoxFit.cover)
                      : const Icon(Icons.event),
                  title: Text(e.title),
                  subtitle: Text(e.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EventDetailPage(event: e)),
                  ),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () async {
                          await _service.approveEvent(e.id);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event approved')));
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () async {
                          await _service.updateEvent(e.id, {'status': 'rejected'});
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event rejected')));
                        },
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
