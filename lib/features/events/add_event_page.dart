import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/cloudinary_service.dart';
import '../../models/event_model.dart';

class AddEventPage extends StatefulWidget {
  const AddEventPage({super.key});

  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final TextEditingController titleCtrl = TextEditingController();
  final TextEditingController descCtrl = TextEditingController();
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
  // 📤 Submit Event
  // ────────────────────────────────
  Future<void> submitEvent() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      String? imageUrl;

      // Upload image to Cloudinary if selected
      if (imageFile != null) {
        imageUrl = await CloudinaryService().uploadFile(
          imageFile!,
          folder: 'events', // optional folder for event images
        );
      }

      final newId = FirestoreService.instance.generateId("events");

      final event = EventModel(
        id: newId,
        title: titleCtrl.text,
        description: descCtrl.text,
        imageUrl: imageUrl ?? '',
        createdAt: DateTime.now(),
        status: 'pending',
        userId: '', // TODO: set current user ID
      );

      await FirestoreService.instance.addEvent(event);

      if (!mounted) return;
      Navigator.pop(context);
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
