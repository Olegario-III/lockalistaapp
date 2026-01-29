// lib/features/stores/add_store_page.dart
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

  /// ✅ SAFE DEFAULT
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

  // ────────────────
  // 📍 Pick location
  // ────────────────
  Future<void> _pickLocation() async {
    final location = await Helpers.pickLocationOnMap(context);
    if (!mounted) return;
    if (location != null) {
      setState(() => selectedLocation = location);
    }
  }

  // ────────────────
  // 🖼 Pick image
  // ────────────────
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (picked != null) {
      setState(() => selectedImage = File(picked.path));
    }
  }

  // ────────────────
  // 🚀 Submit store
  // ────────────────
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
      final imageUrl = await CloudinaryService().uploadFile(
        selectedImage!,
        folder: 'stores',
      );

      if (imageUrl == null) {
        Helpers.showSnackBar(context, 'Image upload failed');
        return;
      }

      final store = StoreModel(
        id: '',
        name: _nameController.text.trim(),
        type: selectedType,
        barangay: selectedBarangay!,
        location: selectedLocation!,
        ownerId: Helpers.currentUserId(),
        images: [imageUrl],
      );

      await FirestoreService.instance.addStore(store);

      if (!mounted) return;

      Helpers.showSnackBar(
        context,
        'Store added! Waiting for admin approval.',
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Failed to add store: $e');
      }
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
                      // Store Name
                      TextFormField(
                        controller: _nameController,
                        decoration:
                            const InputDecoration(labelText: 'Store Name'),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Store Type
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
                        onChanged: (v) =>
                            setState(() => selectedType = v!),
                      ),
                      const SizedBox(height: 16),

                      // Barangay (NO initialValue = NO crash)
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
                        onChanged: (v) =>
                            setState(() => selectedBarangay = v),
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

                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.image),
                        label: Text(
                          selectedImage == null
                              ? 'Pick Store Image'
                              : 'Image Selected',
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
