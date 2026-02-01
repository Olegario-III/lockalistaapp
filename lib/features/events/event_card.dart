import 'package:flutter/material.dart';
import '../../models/event_model.dart' as em;

class EventCard extends StatelessWidget {
  final em.EventModel event;
  final String posterName;
  final String? posterAvatar;
  final bool liked;
  final bool canDelete;
  final VoidCallback onLike;
  final VoidCallback onView;
  final VoidCallback onDelete;
  final VoidCallback onReport;
  final String? timeText;

  const EventCard({
    super.key,
    required this.event,
    required this.posterName,
    required this.posterAvatar,
    required this.liked,
    required this.canDelete,
    required this.onLike,
    required this.onView,
    required this.onDelete,
    required this.onReport,
    this.timeText,
  });

  String _timeUntilEvent() {
    final diff = event.startDate.difference(DateTime.now());
    if (diff.inDays > 0) return '${diff.inDays} days left';
    if (diff.inHours > 0) return '${diff.inHours} hrs left';
    if (diff.inMinutes > 0) return '${diff.inMinutes} mins left';
    return 'Starting soon';
  }

  String _timeSinceEvent() {
    final diff = DateTime.now().difference(event.startDate);
    if (diff.inDays > 0) return '${diff.inDays} days ago';
    if (diff.inHours > 0) return '${diff.inHours} hrs ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes} mins ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final displayTime = timeText ??
        (event.startDate.isBefore(now)
            ? _timeSinceEvent()
            : _timeUntilEvent());

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔹 TITLE (TOP)
            Text(
              event.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            /// 🔹 DESCRIPTION
            Text(
              event.description,
              style: TextStyle(color: Colors.grey[800]),
            ),

            /// 🔹 IMAGE
            if (event.imageUrl?.isNotEmpty == true) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  event.imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],

            const SizedBox(height: 10),

            /// 🔹 INFO CHIPS
            Wrap(
              spacing: 10,
              runSpacing: 6,
              children: [
                _Chip(icon: Icons.timer, text: displayTime),
                if (event.approvedByName != null)
                  _Chip(
                    icon: Icons.verified,
                    text: 'Approved by ${event.approvedByName}',
                  ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(),

            /// 🔹 BOTTOM SECTION (AVATAR + NAME)
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage:
                      posterAvatar != null ? NetworkImage(posterAvatar!) : null,
                  child:
                      posterAvatar == null ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    posterName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                IconButton(
                  icon: Icon(
                    liked ? Icons.favorite : Icons.favorite_border,
                    color: Colors.red,
                  ),
                  onPressed: onLike,
                ),
                Text('${event.likesCount}'),

                PopupMenuButton<String>(
                  onSelected: (v) => v == 'delete' ? onDelete() : onReport(),
                  itemBuilder: (_) => [
                    if (!canDelete)
                      const PopupMenuItem(
                        value: 'report',
                        child: Text('🚩 Report'),
                      ),
                    if (canDelete)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('🗑 Delete'),
                      ),
                  ],
                ),
              ],
            ),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onView,
                child: const Text('View'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Chip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
