// lib/features/trending/trending_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/event_model.dart';
import '../../models/store_model.dart';
import '../events/event_card.dart';
import '../events/event_detail_page.dart';
import '../stores/store_detail_page.dart';

class TrendingPage extends StatelessWidget {
  const TrendingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trending'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: const [
          _TrendingEventsSection(),
          SizedBox(height: 24),
          _TrendingStoresSection(),
        ],
      ),
    );
  }
}

/// 🔥 TOP 10 UPCOMING EVENTS (BY LIKES)
class _TrendingEventsSection extends StatelessWidget {
  const _TrendingEventsSection();

  @override
  Widget build(BuildContext context) {
    final now = Timestamp.fromDate(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🔥 Top Upcoming Events',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('events')
              .where('status', isEqualTo: 'approved')
              .where('endDate', isGreaterThan: now) // ✅ still upcoming
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final events = snapshot.data!.docs
                .map(
                  (d) => EventModel.fromMap(
                    d.data() as Map<String, dynamic>,
                    d.id,
                  ),
                )
                .toList();

            if (events.isEmpty) {
              return const Text('No upcoming events yet.');
            }

            /// ✅ SORT BY LIKES FIRST, THEN SOONER DATE
            events.sort((a, b) {
              final likesCompare = (b.likesCount ?? 0).compareTo(
                a.likesCount ?? 0,
              );
              if (likesCompare != 0) return likesCompare;

              return a.startDate.compareTo(b.startDate);
            });

            final topEvents = events.take(10).toList();

            return Column(
              children: List.generate(topEvents.length, (index) {
                final event = topEvents[index];

                return Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: EventCard(
                        event: event,
                        posterName: event.ownerName ?? 'Unknown',
                        posterAvatar: event.ownerAvatar,
                        liked: false,
                        canDelete: false,

                        /// ❤️ optional
                        onLike: () {},

                        /// 👁️ FIXED VIEW BUTTON
                        onView: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EventDetailPage(event: event),
                            ),
                          );
                        },

                        onDelete: () {},
                        onReport: () {},
                      ),
                    ),
                    Positioned(
                      top: 6,
                      left: 6,
                      child: _RankBadge(rank: index + 1),
                    ),
                  ],
                );
              }),
            );
          },
        ),
      ],
    );
  }
}

/// ⭐ TOP 10 STORES (BY AVERAGE RATING)
class _TrendingStoresSection extends StatelessWidget {
  const _TrendingStoresSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '⭐ Top Rated Stores',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('stores')
              .where('approved', isEqualTo: true) // ✅ corrected field
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final stores = snapshot.data!.docs
                .map(
                  (d) => StoreModel.fromMap(
                    d.data() as Map<String, dynamic>,
                    d.id,
                  ),
                )
                .toList();

            if (stores.isEmpty) {
              return const Text('No stores available.');
            }

            /// ✅ sort by averageRating
            stores.sort((a, b) => b.averageRating.compareTo(a.averageRating));

            final topStores = stores.take(10).toList();

            return Column(
              children: List.generate(topStores.length, (index) {
                final store = topStores[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: store.imageUrl.isNotEmpty
                              ? Image.network(
                                  store.imageUrl,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(Icons.store, size: 40),
                        ),
                        Positioned(
                          top: -4,
                          left: -4,
                          child: _RankBadge(rank: index + 1, small: true),
                        ),
                      ],
                    ),
                    title: Text(
                      store.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${store.averageRating.toStringAsFixed(1)} ★',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StoreDetailPage(store: store),
                        ),
                      );
                    },
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }
}

/// 🏆 RANK BADGE
class _RankBadge extends StatelessWidget {
  final int rank;
  final bool small;

  const _RankBadge({required this.rank, this.small = false});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (rank) {
      case 1:
        color = Colors.amber;
        break;
      case 2:
        color = Colors.grey;
        break;
      case 3:
        color = Colors.brown;
        break;
      default:
        color = Colors.black87;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 8,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '#$rank',
        style: TextStyle(
          color: Colors.white,
          fontSize: small ? 10 : 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
