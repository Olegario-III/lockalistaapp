import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final AuthService _authService = AuthService();

  final TextEditingController titleCtrl = TextEditingController();
  final TextEditingController descCtrl = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  bool _isSubmitting = false;

  // ────────────────────────────────
  // 🖼 Pick image (with preview)
  // ────────────────────────────────
  Future<void> pickImage() async {
    final XFile? file =
        await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() => _imageFile = File(file.path));
  }

  // ────────────────────────────────
  // 📅 Pick dates
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

  Future<void> pickEndDate() async {
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick start date first')),
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
  // ⏱ Cooldown check (30 mins)
  // ────────────────────────────────
  Future<void> checkCooldown(String userId, String role) async {
    if (role == 'admin') return;

    final snap = await FirebaseFirestore.instance
        .collection('events')
        .where('ownerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return;

    final lastCreated =
        (snap.docs.first['createdAt'] as Timestamp).toDate();

    final diff = DateTime.now().difference(lastCreated);

    if (diff.inMinutes < 30) {
      final remaining = 30 - diff.inMinutes;
      throw Exception(
        'Please wait $remaining minute(s) before posting another event.',
      );
    }
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
        const SnackBar(content: Text('All fields are required')),
      );
      return;
    }

    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    setState(() => _isSubmitting = true);

    try {
      // ────────────────────────────────
      // 👤 Load user
      // ────────────────────────────────
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final userData = userDoc.data() ?? {};
      final role = userData['role'] ?? '';
      final ownerName = userData['name'] ?? 'Unknown';
      final ownerAvatar = userData['image'];

      // ────────────────────────────────
      // ⏱ Cooldown enforcement
      // ────────────────────────────────
      await checkCooldown(currentUser.uid, role);

      // ────────────────────────────────
      // 🖼 Upload image
      // ────────────────────────────────
      String? imageUrl;
      if (_imageFile != null) {
        imageUrl = await CloudinaryService().uploadFile(
          _imageFile!,
          folder: 'events',
        );
      }

      // ────────────────────────────────
      // ✅ Auto-approval logic
      // ────────────────────────────────
      final status =
          (role == 'admin' || role == 'owner') ? 'approved' : 'pending';

      final firestore = FirestoreService.instance;
      final eventId = firestore.generateId('events');

      final event = EventModel(
        id: eventId,
        title: titleCtrl.text.trim(),
        description: descCtrl.text.trim(),
        ownerId: currentUser.uid,
        ownerName: ownerName,
        ownerAvatar: ownerAvatar,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
        startDate: _startDate!,
        endDate: _endDate!,
        status: status,
        likesList: const [],
        likesCount: 0,
        comments: const [],
      );

      await firestore.addEvent(event, currentUser.uid);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Event Posted'),
          content: Text(
            status == 'approved'
                ? 'Your event is now live.'
                : 'Your event is waiting for admin approval.',
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
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  // ────────────────────────────────
  // 🧱 UI
  // ────────────────────────────────
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
                      child: Text(
                        _startDate == null
                            ? 'Pick Start Date'
                            : 'Start: ${_startDate!.toLocal().toString().split(' ')[0]}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: pickEndDate,
                      child: Text(
                        _endDate == null
                            ? 'Pick End Date'
                            : 'End: ${_endDate!.toLocal().toString().split(' ')[0]}',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              /// 🖼 IMAGE PREVIEW
              GestureDetector(
                onTap: pickImage,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                    image: _imageFile != null
                        ? DecorationImage(
                            image: FileImage(_imageFile!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _imageFile == null
                      ? const Center(child: Text('Tap to pick image'))
                      : null,
                ),
              ),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : submitEvent,
                child: Text(
                  _isSubmitting ? 'Submitting...' : 'Submit Event',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
