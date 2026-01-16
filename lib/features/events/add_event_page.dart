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
  final _authService = AuthService();

  final TextEditingController titleCtrl = TextEditingController();
  final TextEditingController descCtrl = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;

  File? imageFile;
  final picker = ImagePicker();
  bool _isSubmitting = false;

  // ────────────────────────────────
  // 🖼 Pick image
  // ────────────────────────────────
  Future<void> pickImage() async {
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() => imageFile = File(file.path));
  }

  // ────────────────────────────────
  // 📅 Pick start date
  // ────────────────────────────────
  Future<void> pickStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date != null) setState(() => _startDate = date);
  }

  // ────────────────────────────────
  // 📅 Pick end date
  // ────────────────────────────────
  Future<void> pickEndDate() async {
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a start date first')),
      );
      return;
    }
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate!,
      firstDate: _startDate!,
      lastDate: DateTime(2100),
    );
    if (date != null) setState(() => _endDate = date);
  }

  // ────────────────────────────────
  // 📤 Submit Event
  // ────────────────────────────────
  Future<void> submitEvent() async {
    if (_isSubmitting) return;

    if (titleCtrl.text.trim().isEmpty ||
        descCtrl.text.trim().isEmpty ||
        _startDate == null ||
        _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields including dates are required')),
      );
      return;
    }

    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    setState(() => _isSubmitting = true);

    try {
      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await CloudinaryService().uploadFile(
          imageFile!,
          folder: 'events',
        );
      }

      final eventId = FirestoreService.instance.generateId('events');

      final event = EventModel(
        id: eventId,
        title: titleCtrl.text.trim(),
        description: descCtrl.text.trim(),
        userId: currentUser.uid,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
        status: 'pending', // 🔒 admin approval required
        likesList: [],
        likesCount: 0,
        comments: [],
        startDate: _startDate!,
        endDate: _endDate!,
      );

      await FirestoreService.instance.addEvent(event);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Event Submitted'),
          content: const Text(
            'Your event is waiting for admin approval before it appears publicly.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
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
      appBar: AppBar(title: const Text('Add Event')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Event Title'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descCtrl,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: pickStartDate,
                      child: Text(_startDate == null
                          ? 'Pick Start Date'
                          : 'Start: ${_startDate!.toLocal().toString().split(' ')[0]}'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: pickEndDate,
                      child: Text(_endDate == null
                          ? 'Pick End Date'
                          : 'End: ${_endDate!.toLocal().toString().split(' ')[0]}'),
                    ),
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
                      : const Center(child: Text('Tap to pick an image')),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : submitEvent,
                child: Text(_isSubmitting ? 'Submitting...' : 'Submit Event'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
