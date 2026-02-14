import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/services/firestore_service.dart';
import '../../core/services/cloudinary_service.dart';
import '../../core/services/auth_service.dart';
import '../../models/event_model.dart';

class EditEventPage extends StatefulWidget {
  final EventModel event;

  const EditEventPage({
    super.key,
    required this.event,
  });

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
    _selectedDate = widget.event.startDate;
  }

  /* ────────────────────────────────
     PICK IMAGE
  ──────────────────────────────── */
  Future<void> _pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() => _imageFile = File(file.path));
  }

  /* ────────────────────────────────
     PICK DATE
  ──────────────────────────────── */
  Future<void> _pickDate() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );

    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  /* ────────────────────────────────
     SUBMIT EDIT
  ──────────────────────────────── */
  Future<void> _submitEdit() async {
    if (_isSubmitting) return;

    final user = _auth.currentUser;
    if (user == null) {
      _snack('User not logged in');
      return;
    }

    final isOwner = user.uid == widget.event.ownerId;

    // 🔥 Check admin from Firestore
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final isAdmin = userDoc.exists && userDoc.data()?['role'] == 'admin';

    if (!isOwner && !isAdmin) {
      _snack('You do not have permission to edit this event');
      return;
    }

    if (_titleCtrl.text.trim().isEmpty ||
        _descCtrl.text.trim().isEmpty ||
        _selectedDate == null) {
      _snack('Please complete all fields');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String? imageUrl = widget.event.imageUrl;

      // Upload new image if selected
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
        'startDate': Timestamp.fromDate(_selectedDate!),
        'status': isAdmin ? 'approved' : 'pending',
        'updatedAt': Timestamp.now(),
      };

      await _firestore.updateEventFields(
        widget.event.id,
        updatedData,
      );

      if (!mounted) return;

      // Go back to detail page
      Navigator.pop(context);
      Navigator.pop(context);
    } catch (e) {
      _snack('Failed to update event: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  /* ────────────────────────────────
     UI
  ──────────────────────────────── */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Event'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Event Title',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                ),
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
                          ? Image.network(
                              widget.event.imageUrl!,
                              fit: BoxFit.cover,
                            )
                          : const Center(
                              child: Text('Tap to pick image'),
                            ),
                ),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitEdit,
                child: Text(
                  _isSubmitting
                      ? 'Submitting...'
                      : 'Submit Changes',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
