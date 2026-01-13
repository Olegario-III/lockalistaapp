// lib/features/events/event_list_page.dart
import 'package:flutter/material.dart';
import '../../core/services/firestore_service.dart';
import '../../models/event_model.dart' as em;
import 'event_detail_page.dart';

class EventListWidget extends StatelessWidget {
  EventListWidget({super.key}); // just a widget, not a Scaffold
  final _service = FirestoreService.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<em.EventModel>>(
      stream: _service.getEventsStream(status: 'approved'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final events = snapshot.data ?? [];
        if (events.isEmpty) {
          return const Center(child: Text('No events yet.'));
        }
        return ListView.separated(
          itemCount: events.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final e = events[index];
            return ListTile(
              leading: (e.imageUrl != null && e.imageUrl!.isNotEmpty)
                  ? Image.network(e.imageUrl!, width: 64, height: 64, fit: BoxFit.cover)
                  : const Icon(Icons.event, size: 40),
              title: Text(e.title),
              subtitle: Text(e.description,
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${e.likesCount} ❤️'),
                  const SizedBox(height: 4),
                  Text('${e.comments.length} 💬')
                ],
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EventDetailPage(event: e)),
              ),
            );
          },
        );
      },
    );
  }
}
