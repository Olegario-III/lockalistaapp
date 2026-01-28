// lib/features/events/event_card.dart
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
  });

  String _timeUntilEvent() {
    final diff = event.startDate.difference(DateTime.now());
    if (diff.isNegative) return 'Started';
    if (diff.inDays > 0) return '${diff.inDays} days left';
    if (diff.inHours > 0) return '${diff.inHours} hrs left';
    return '${diff.inMinutes} mins left';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔥 HEADER (Avatar + Name ONLY)
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage:
                      posterAvatar != null ? NetworkImage(posterAvatar!) : null,
                  child:
                      posterAvatar == null ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    posterName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) =>
                      v == 'delete' ? onDelete() : onReport(),
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

            /// ✅ FIXED: BELOW header, HORIZONTAL, NO OVERLAP
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _Chip(
                  icon: Icons.timer,
                  text: _timeUntilEvent(),
                ),
                if (event.approvedByName != null)
                  _Chip(
                    icon: Icons.verified,
                    text: 'Approved by ${event.approvedByName}',
                  ),
              ],
            ),

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
            Text(
              event.title,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(event.description),

            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    liked ? Icons.favorite : Icons.favorite_border,
                    color: Colors.red,
                  ),
                  onPressed: onLike,
                ),
                Text('${event.likesCount}'),
                const Spacer(),
                TextButton(
                  onPressed: onView,
                  child: const Text('View'),
                ),
              ],
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

  const _Chip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
