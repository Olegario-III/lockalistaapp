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
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  DateTime? _selectedDate;
  File? _imageFile;
  bool _isSubmitting = false;

  final _picker = ImagePicker();
  final _auth = AuthService();
  final _firestore = FirestoreService.instance;

  @override
  void initState() {
    super.initState();
    _titleCtrl.text = widget.event.title;
    _descCtrl.text = widget.event.description;
    _selectedDate = widget.event.timestamp;
  }

  // ────────────────────────────────
  // Pick image
  // ────────────────────────────────
  Future<void> _pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() => _imageFile = File(file.path));
  }

  // ────────────────────────────────
  // Pick date
  // ────────────────────────────────
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  // ────────────────────────────────
  // Submit edit
  // ────────────────────────────────
  Future<void> _submitEdit() async {
    if (_isSubmitting) return;

    final user = _auth.currentUser;
    if (user == null) {
      _snack('User not logged in');
      return;
    }

    if (user.uid != widget.event.userId) {
      _snack('Only the event owner can edit this');
      return;
    }

    if (_titleCtrl.text.isEmpty ||
        _descCtrl.text.isEmpty ||
        _selectedDate == null) {
      _snack('Please complete all fields');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String? imageUrl = widget.event.imageUrl;

      if (_imageFile != null) {
        imageUrl = await CloudinaryService().uploadFile(
          _imageFile!,
          folder: 'events',
        );
      }

      final updatedData = {
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'imageUrl': imageUrl,
        'eventDate': _selectedDate,
        'status': 'pending', // ⛔ requires admin re-approval
        'updatedAt': DateTime.now(),
      };

      await _firestore.updateEventFields(widget.event.id, updatedData);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Event Updated'),
          content: const Text(
            'Your changes are waiting for admin approval.',
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
      _snack('Failed to update event: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Event')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Event Title'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedDate != null
                          ? 'Event Date: ${_selectedDate!.toLocal().toString().split(' ')[0]}'
                          : 'No date selected',
                    ),
                  ),
                  TextButton(
                    onPressed: _pickDate,
                    child: const Text('Pick Date'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  color: Colors.grey[300],
                  child: _imageFile != null
                      ? Image.file(_imageFile!, fit: BoxFit.cover)
                      : (widget.event.imageUrl != null &&
                              widget.event.imageUrl!.isNotEmpty)
                          ? Image.network(widget.event.imageUrl!,
                              fit: BoxFit.cover)
                          : const Center(child: Text('Tap to pick image')),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitEdit,
                child: Text(
                  _isSubmitting ? 'Submitting...' : 'Submit Changes',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
