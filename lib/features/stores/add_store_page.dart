import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/services/firestore_service.dart';
import '../../core/services/cloudinary_service.dart';
import '../../core/utils/helpers.dart';
import '../../models/store_model.dart';

class AddStorePage extends StatefulWidget {
  const AddStorePage({super.key});

  @override
  State<AddStorePage> createState() => _AddStorePageState();
}

class _AddStorePageState extends State<AddStorePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String selectedType = 'resort';
  String? selectedBarangay;

  GeoPoint? selectedLocation;
  File? selectedImage;

  bool _loading = false;

  final List<String> storeTypes = const [
    'pharmacy',
    'resort',
    'grocery',
    'sari-sari store',
    'karenderya',
    'others',
  ];

  final List<String> barangays = const [
    'Batingan',
    'Bilibiran',
    'Ithan',
    'Calumpang',
    'Kalawaan',
    'Kalinawan',
    'Mahabang Parang',
    'Layunan',
    'Libid',
    'Libis',
    'Limbon-limbon',
    'Lunsad',
    'Macamot',
    'Mambog',
    'Pag-asa',
    'Palangoy',
    'Pantok',
    'Pila-pila',
    'Pipindan',
    'San Carlos',
    'Tagpos',
    'Tatala',
    'Tayuman',
  ];

  // ────────────────────────────────
  // 📍 Pick location
  // ────────────────────────────────
  Future<void> _pickLocation() async {
    final location = await Helpers.pickLocationOnMap(context);
    if (!mounted) return;
    if (location != null) setState(() => selectedLocation = location);
  }

  // ────────────────────────────────
  // 🖼 Pick image with preview
  // ────────────────────────────────
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (picked != null) setState(() => selectedImage = File(picked.path));
  }

  // ────────────────────────────────
  // ⏱ Cooldown check (30 mins)
  // ────────────────────────────────
  Future<void> _checkCooldown(String userId) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    final role = userDoc.data()?['role'] ?? '';

    if (role == 'admin') return;

    final snap = await FirebaseFirestore.instance
        .collection('stores')
        .where('ownerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return;

    final lastCreated = (snap.docs.first['createdAt'] as Timestamp).toDate();
    final diff = DateTime.now().difference(lastCreated);

    if (diff.inMinutes < 30) {
      final remaining = 30 - diff.inMinutes;
      throw Exception(
        'Please wait $remaining minute(s) before adding another store.',
      );
    }
  }

  // ────────────────────────────────
  // 🚀 Submit store
  // ────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedBarangay == null) {
      Helpers.showSnackBar(context, 'Please select a barangay');
      return;
    }
    if (selectedLocation == null) {
      Helpers.showSnackBar(context, 'Please pick a location');
      return;
    }
    if (selectedImage == null) {
      Helpers.showSnackBar(context, 'Please pick a store image');
      return;
    }

    setState(() => _loading = true);

    try {
      final userId = Helpers.currentUserId();

      // ⏱ Cooldown enforcement
      await _checkCooldown(userId);

      // 🖼 Upload image
      final imageUrl = await CloudinaryService().uploadFile(
        selectedImage!,
        folder: 'stores',
      );

      if (imageUrl == null) throw Exception('Image upload failed');

      final store = StoreModel(
        id: '',
        name: _nameController.text.trim(),
        type: selectedType,
        barangay: selectedBarangay!,
        location: selectedLocation!,
        ownerId: userId,
        images: [imageUrl],
        approved: false, // all stores start unapproved
        createdAt: Timestamp.now(),
      );

      await FirestoreService.instance.addStore(store);

      if (!mounted) return;

      Helpers.showSnackBar(
        context,
        'Store added! Waiting for admin approval.',
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) Helpers.showSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Store')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration:
                            const InputDecoration(labelText: 'Store Name'),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedType,
                        decoration:
                            const InputDecoration(labelText: 'Store Type'),
                        items: storeTypes
                            .map((t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(t),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => selectedType = v!),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        hint: const Text('Select Barangay'),
                        decoration:
                            const InputDecoration(labelText: 'Barangay'),
                        items: barangays
                            .map((b) => DropdownMenuItem(
                                  value: b,
                                  child: Text(b),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => selectedBarangay = v),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _pickLocation,
                        icon: const Icon(Icons.map),
                        label: Text(
                          selectedLocation == null
                              ? 'Pick Store Location'
                              : 'Location Selected',
                        ),
                      ),
                      const SizedBox(height: 16),
                      /// IMAGE PREVIEW
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                            image: selectedImage != null
                                ? DecorationImage(
                                    image: FileImage(selectedImage!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: selectedImage == null
                              ? const Center(
                                  child: Text('Tap to pick store image'),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _submit,
                        child: const Text('Add Store'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
