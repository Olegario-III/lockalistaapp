// lib/features/events/add_event_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/cloudinary_service.dart';
import '../../core/services/auth_service.dart';
import '../../models/event_model.dart';

class AddEventPage extends StatefulWidget {
  const AddEventPage({super.key});

  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final TextEditingController titleCtrl = TextEditingController();
  final TextEditingController descCtrl = TextEditingController();
  DateTime? selectedDate;
  File? imageFile;
  final picker = ImagePicker();
  bool _isSubmitting = false;

  // ────────────────────────────────
  // 🖼 Pick image from gallery
  // ────────────────────────────────
  Future<void> pickImage() async {
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() => imageFile = File(file.path));
  }

  // ────────────────────────────────
  // 📅 Pick event date
  // ────────────────────────────────
  Future<void> pickDate() async {
    final now = DateTime.now();
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (date != null) setState(() => selectedDate = date);
  }

  // ────────────────────────────────
  // 📤 Submit Event
  // ────────────────────────────────
  Future<void> submitEvent() async {
    if (_isSubmitting) return;

    if (titleCtrl.text.isEmpty || descCtrl.text.isEmpty || selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and select a date')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final currentUser = AuthService.instance.currentUser;
      if (currentUser == null) throw 'User not logged in';

      String? imageUrl;

      // Upload image to Cloudinary if selected
      if (imageFile != null) {
        imageUrl = await CloudinaryService().uploadFile(
          imageFile!,
          folder: 'events',
        );
      }

      final newId = FirestoreService.instance.generateId('events');

      final event = EventModel(
        id: newId,
        title: titleCtrl.text.trim(),
        description: descCtrl.text.trim(),
        imageUrl: imageUrl ?? '',
        date: selectedDate!,
        createdAt: DateTime.now(),
        userId: currentUser.uid,
        approved: false, // pending by default
      );

      await FirestoreService.instance.addEvent(event);

      if (!mounted) return;

      // Show alert: waiting for approval
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Event Submitted'),
          content: const Text(
              'Your event is waiting for admin approval before it appears publicly.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // go back
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add event: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Event")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: "Event Title"),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descCtrl,
                maxLines: 4,
                decoration: const InputDecoration(labelText: "Description"),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(selectedDate != null
                        ? 'Event Date: ${selectedDate!.toLocal().toString().split(' ')[0]}'
                        : 'No date selected'),
                  ),
                  TextButton(
                    onPressed: pickDate,
                    child: const Text('Pick Date'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  color: Colors.grey[300],
                  child: imageFile != null
                      ? Image.file(imageFile!, fit: BoxFit.cover)
                      : const Center(child: Text("Tap to pick an image")),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isSubmitting ? null : submitEvent,
                child: Text(_isSubmitting ? "Submitting..." : "Submit Event"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
