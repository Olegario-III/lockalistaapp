// lib/features/stores/add_store_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/services/firestore_service.dart';
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

  String selectedType = 'pharmacy';
  String selectedBarangay = 'Darangan';
  GeoPoint? selectedLocation;

  bool _loading = false;

  // ────────────────
  // Pick location
  // ────────────────
  Future<void> _pickLocation() async {
    final location = await Helpers.pickLocationOnMap();
    if (!mounted) return;

    if (location != null) {
      setState(() => selectedLocation = location);
    }
  }

  // ────────────────
  // Submit store
  // ────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedLocation == null) {
      Helpers.showSnackBar(context, 'Please pick a location');
      return;
    }

    setState(() => _loading = true);

    try {
      final store = StoreModel(
        id: '', // Firestore will generate this
        name: _nameController.text.trim(),
        type: selectedType,
        barangay: selectedBarangay,
        location: selectedLocation!,
        ownerId: Helpers.currentUserId(),
      );

      // 🔥 NO docRef, NO return value
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
      if (mounted) {
        setState(() => _loading = false);
      }
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
                        initialValue: selectedType,
                        decoration:
                            const InputDecoration(labelText: 'Store Type'),
                        items: const [
                          'pharmacy',
                          'resort',
                          'grocery',
                          'sari-sari store',
                          'karenderya',
                          'others',
                        ]
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => selectedType = v!),
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        initialValue: selectedBarangay,
                        decoration:
                            const InputDecoration(labelText: 'Barangay'),
                        items: const [
                          'Darangan',
                          'Barangay2',
                          'Barangay3',
                        ]
                            .map(
                              (b) => DropdownMenuItem(
                                value: b,
                                child: Text(b),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => selectedBarangay = v!),
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
