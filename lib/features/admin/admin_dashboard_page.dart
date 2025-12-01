import 'package:flutter/material.dart';
import '../../core/services/firestore_service.dart';
import '../../models/event_model.dart' as em;
import 'approvals/approval_events_page.dart';
import 'approvals/approval_stores_page.dart';

class AdminDashboardPage extends StatelessWidget {
  final _service = FirestoreService.instance;

  AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: ListTile(
                title: const Text('Pending Approvals'),
                subtitle: const Text('Events and Stores waiting for review'),
                trailing: ElevatedButton(
                  child: const Text('Review'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ApprovalEventsPage()),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: ListTile(
                      title: const Text('Approved Events'),
                      trailing: ElevatedButton(
                        child: const Text('Open'),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ApprovalEventsPage()),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Card(
                    child: ListTile(
                      title: const Text('Approved Stores'),
                      trailing: ElevatedButton(
                        child: const Text('Open'),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ApprovalStoresPage()),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<em.EventModel>>(
                stream: _service.getEventsStream(status: 'pending'),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final pendingEvents = snapshot.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Recent pending events', style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(
                        child: ListView.builder(
                          itemCount: pendingEvents.length,
                          itemBuilder: (_, idx) {
                            final e = pendingEvents[idx];
                            return ListTile(
                              leading: e.imageUrl != null && e.imageUrl!.isNotEmpty
                                  ? Image.network(e.imageUrl!, width: 50, height: 50, fit: BoxFit.cover)
                                  : const Icon(Icons.event),
                              title: Text(e.title),
                              subtitle: Text(e.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                            );
                          },
                        ),
                      )
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
