import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomerServicePage extends StatefulWidget {
  const CustomerServicePage({super.key});

  @override
  State<CustomerServicePage> createState() => _CustomerServicePageState();
}

class _CustomerServicePageState extends State<CustomerServicePage> {
  final TextEditingController _messageController = TextEditingController();
  bool isSending = false;

  Future<void> sendMessage() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a message")),
      );
      return;
    }

    setState(() => isSending = true);

    await FirebaseFirestore.instance.collection("customer_messages").add({
      "userId": user.uid,
      "userEmail": user.email,
      "message": _messageController.text.trim(),
      "createdAt": FieldValue.serverTimestamp(),
      "status": "unread",
    });

    setState(() => isSending = false);
    _messageController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Message sent successfully")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Customer Service"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              "Send a message to the app creator:",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _messageController,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: "Type your message here...",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isSending ? null : sendMessage,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: isSending
                  ? const CircularProgressIndicator()
                  : const Text("Send Message"),
            ),
          ],
        ),
      ),
    );
  }
}
