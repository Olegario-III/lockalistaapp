import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VerificationRequestsPage extends StatelessWidget {
  const VerificationRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('verification_requests')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No verification requests'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return _VerificationCard(
              requestId: doc.id,
              userId: data['userId'],
              ownerName: data['ownerName'] ?? 'Unknown',
              storeImage: data['storeImage'],
              permitImage: data['permitImage'],
              selfieImage: data['selfieImage'],
            );
          },
        );
      },
    );
  }
}

class _VerificationCard extends StatelessWidget {
  final String requestId;
  final String userId;
  final String ownerName;
  final String storeImage;
  final String permitImage;
  final String selfieImage;

  const _VerificationCard({
    required this.requestId,
    required this.userId,
    required this.ownerName,
    required this.storeImage,
    required this.permitImage,
    required this.selfieImage,
  });

  /// ✅ APPROVE → role becomes "owner"
  Future<void> _approve(BuildContext context) async {
    final batch = FirebaseFirestore.instance.batch();

    final requestRef = FirebaseFirestore.instance
        .collection('verification_requests')
        .doc(requestId);

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(userId);

    batch.update(requestRef, {
      'status': 'approved',
      'reviewedAt': FieldValue.serverTimestamp(),
    });

    batch.update(userRef, {
      'role': 'owner',
      'rejectedAt': FieldValue.delete(),
    });

    await batch.commit();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification approved')),
      );
    }
  }

  /// ❌ REJECT → role unchanged, cooldown enforced
  Future<void> _reject(BuildContext context) async {
    final batch = FirebaseFirestore.instance.batch();

    final requestRef = FirebaseFirestore.instance
        .collection('verification_requests')
        .doc(requestId);

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(userId);

    batch.update(requestRef, {
      'status': 'rejected',
      'reviewedAt': FieldValue.serverTimestamp(),
    });

    batch.update(userRef, {
      'rejectedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification rejected')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Owner Name
            Text(
              ownerName,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _ImagePreview(title: 'Store Photo', url: storeImage),
            _ImagePreview(title: 'Barangay Permit', url: permitImage),
            _ImagePreview(title: 'Owner Selfie', url: selfieImage),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                    onPressed: () => _approve(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                    onPressed: () => _reject(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final String title;
  final String url;

  const _ImagePreview({
    required this.title,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            url,
            height: 160,
            width: double.infinity,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator()),
              );
            },
            errorBuilder: (_, __, ___) => const SizedBox(
              height: 160,
              child: Center(child: Icon(Icons.broken_image)),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
