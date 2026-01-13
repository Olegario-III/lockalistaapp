// lib\features\admin\approvals\approval_events_page.dart
import 'package:flutter/material.dart';
import '../../../core/services/admin_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ApprovalEventsPage extends StatelessWidget {
  ApprovalEventsPage({super.key});
  final AdminService _adminService = AdminService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('events')
          .where('approved', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) return const Center(child: Text('No pending events'));

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final event = docs[index];
            return ListTile(
              title: Text(event['title']),
              subtitle: Text(event['description']),
              trailing: IconButton(
                icon: const Icon(Icons.check),
                onPressed: () => _adminService.approveEvent(event.id),
              ),
            );
          },
        );
      },
    );
  }
}
