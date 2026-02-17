import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminCustomerMessagesPage extends StatelessWidget {
  const AdminCustomerMessagesPage({super.key});

  void _deleteMessage(BuildContext context, String docId) async {
    await FirebaseFirestore.instance
        .collection("customer_messages")
        .doc(docId)
        .delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Message deleted")),
    );
  }

  void _showMessageDialog(
      BuildContext context, String email, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("From: $email"),
        content: SingleChildScrollView(
          child: Text(message),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("customer_messages")
          .orderBy("createdAt", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No customer messages"));
        }

        final messages = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final doc = messages[index];
            final data = doc.data() as Map<String, dynamic>;

            final email = data["userEmail"] ?? "Unknown";
            final message = data["message"] ?? "";

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(email),
                subtitle: Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () =>
                    _showMessageDialog(context, email, message),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () =>
                      _deleteMessage(context, doc.id),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
