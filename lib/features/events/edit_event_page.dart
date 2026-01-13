// lib/features/events/edit_event_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/cloudinary_service.dart';
import '../../core/services/auth_service.dart';
import '../../models/event_model.dart';

class EditEventPage extends StatefulWidget {
  final EventModel event;

  const EditEventPage({super.key, required this.event});

  @override
  State<EditEventPage> createState() => _EditEventPageState();
}

class _EditEventPageState extends State<EditEventPage> {
  final TextEditingController titleCtrl = TextEditingController();
  final TextEditingController descCtrl = TextEditingController();
  DateTime? selectedDate;
  File? imageFile;
  final picker = ImagePicker();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill existing data
    titleCtrl.text = widget.event.title;
    descCtrl.text = widget.event.description;
    selectedDate = widget.event.date;
  }

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
      initialDate: selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (date != null) setState(() => selectedDate = date);
  }

  // ────────────────────────────────
  // 📤 Submit Edited Event
  // ────────────────────────────────
  Future<void> submitEdit() async {
    if (_isSubmitting) return;

    final currentUser = AuthService.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    if (currentUser.uid != widget.event.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only the poster can edit this event')),
      );
      return;
    }

    if (titleCtrl.text.isEmpty || descCtrl.text.isEmpty || selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and select a date')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String imageUrl = widget.event.imageUrl;

      // Upload new image if selected
      if (imageFile != null) {
        imageUrl = await CloudinaryService().uploadFile(
          imageFile!,
          folder: 'events',
        );
      }

      final updatedEvent = EventModel(
        id: widget.event.id,
        title: titleCtrl.text.trim(),
        description: descCtrl.text.trim(),
        imageUrl: imageUrl,
        date: selectedDate!,
        createdAt: widget.event.createdAt,
        userId: widget.event.userId,
        approved: false, // reset approval
        likes: widget.event.likes,
      );

      await FirestoreService.instance.updateEvent(updatedEvent);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Event Updated'),
          content: const Text(
              'Your changes are waiting for admin approval before appearing publicly.'),
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
        SnackBar(content: Text('Failed to update event: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Event")),
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
                      : widget.event.imageUrl.isNotEmpty
                          ? Image.network(widget.event.imageUrl, fit: BoxFit.cover)
                          : const Center(child: Text("Tap to pick an image")),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isSubmitting ? null : submitEdit,
                child: Text(_isSubmitting ? "Submitting..." : "Submit Changes"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
