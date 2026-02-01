import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/services/cloudinary_service.dart';

class VerificationFormPage extends StatefulWidget {
  final String userId;

  const VerificationFormPage({super.key, required this.userId});

  @override
  State<VerificationFormPage> createState() => _VerificationFormPageState();
}

class _VerificationFormPageState extends State<VerificationFormPage> {
  File? storeImage;
  File? permitImage;
  File? selfieImage;

  bool isSubmitting = false;

  final ImagePicker picker = ImagePicker();
  final cloudinary = CloudinaryService(); // ✅ instance

  Future<void> pickImage(String type) async {
    final XFile? picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return;

    setState(() {
      if (type == 'store') storeImage = File(picked.path);
      if (type == 'permit') permitImage = File(picked.path);
      if (type == 'selfie') selfieImage = File(picked.path);
    });
  }

  Future<void> submitVerification() async {
    if (storeImage == null || permitImage == null || selfieImage == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please upload all required images')));
      return;
    }

    setState(() => isSubmitting = true);

    try {
      // ✅ upload using Cloudinary instance
      final storeUrl = await cloudinary.uploadFile(storeImage!);
      final permitUrl = await cloudinary.uploadFile(permitImage!);
      final selfieUrl = await cloudinary.uploadFile(selfieImage!);

      // Save verification request
      await FirebaseFirestore.instance
          .collection('verification_requests')
          .doc(widget.userId)
          .set({
        'userId': widget.userId,
        'storeImage': storeUrl,
        'permitImage': permitUrl,
        'selfieImage': selfieUrl,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification request submitted')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  Widget imagePickerCard(String label, File? image, String type) {
    return GestureDetector(
      onTap: () => pickImage(type),
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(12),
        ),
        child: image != null
            ? Image.file(image, fit: BoxFit.cover)
            : Center(child: Text('Upload $label')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            imagePickerCard('Store Image', storeImage, 'store'),
            const SizedBox(height: 16),
            imagePickerCard('Barangay Permit', permitImage, 'permit'),
            const SizedBox(height: 16),
            imagePickerCard('Selfie', selfieImage, 'selfie'),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: isSubmitting ? null : submitVerification,
              child: isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Submit Verification'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
