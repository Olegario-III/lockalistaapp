// lib\features\stores\edit_store_page.dart
// lib/features/stores/edit_store_page.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/utils/helpers.dart';
import '../../core/services/cloudinary_service.dart';
import '../../models/store_model.dart';

class EditStorePage extends StatefulWidget {
  final StoreModel store;

  const EditStorePage({super.key, required this.store});

  @override
  State<EditStorePage> createState() => _EditStorePageState();
}

class _EditStorePageState extends State<EditStorePage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _otherTypeController;

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

  @override
  void initState() {
    super.initState();

    final store = widget.store;

    _nameController = TextEditingController(text: store.name);
    _addressController =
        TextEditingController(text: store.address ?? '');
    _otherTypeController = TextEditingController();

    selectedBarangay = store.barangay;
    selectedLocation = store.location;

    if (storeTypes.contains(store.type)) {
      selectedType = store.type;
    } else {
      selectedType = 'others';
      _otherTypeController.text = store.type;
    }
  }

  Future<void> _pickLocation() async {
    final location = await Helpers.pickLocationOnMap(context);
    if (!mounted) return;
    if (location != null) {
      setState(() => selectedLocation = location);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (picked != null) {
      setState(() => selectedImage = File(picked.path));
    }
  }

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

    setState(() => _loading = true);

    try {
      final currentUserId = Helpers.currentUserId();
      final isAdmin = Helpers.isAdmin();

      String imageUrl = widget.store.images.isNotEmpty
          ? widget.store.images.first
          : '';

      // Upload new image if changed
      if (selectedImage != null) {
        final uploaded = await CloudinaryService().uploadFile(
          selectedImage!,
          folder: 'stores',
        );

        if (uploaded == null) {
          throw Exception('Image upload failed');
        }

        imageUrl = uploaded;
      }

      /// 🔥 APPROVAL LOGIC
      bool approved = widget.store.approved;
      String status = widget.store.approved ? "approved" : "pending";
      String? approvedById = widget.store.approvedById;
      String? approvedByName = widget.store.approvedByName;
      Timestamp? approvedAt = widget.store.approvedAt;

      if (!isAdmin) {
        // Owner editing → reset approval
        approved = false;
        status = "pending";
        approvedById = null;
        approvedByName = null;
        approvedAt = null;
      }

      await FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.store.id)
          .update({
        'name': _nameController.text.trim(),
        'type': selectedType == 'others'
            ? _otherTypeController.text.trim()
            : selectedType,
        'barangay': selectedBarangay!,
        'address': _addressController.text.trim(),
        'location': selectedLocation!,
        'images': [imageUrl],

        // Keep rating data
        'rating': widget.store.rating,
        'ratingCount': widget.store.ratingCount,

        // Approval handling
        'approved': approved,
        'status': status,
        'approvedById': approvedById,
        'approvedByName': approvedByName,
        'approvedAt': approvedAt,
      });

      if (!mounted) return;

      Helpers.showSnackBar(
        context,
        isAdmin
            ? 'Store updated successfully.'
            : 'Store updated. Awaiting re-approval.',
      );

      Navigator.pop(context);
    } catch (e) {
      Helpers.showSnackBar(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _otherTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Store'),
      ),
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
                      /// IMAGE PREVIEW
                      if (selectedImage != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            selectedImage!,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        )
                      else if (store.images.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            store.images.first,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),

                      const SizedBox(height: 12),

                      ElevatedButton(
                        onPressed: _pickImage,
                        child: const Text('Change Image'),
                      ),

                      const SizedBox(height: 16),

                      /// STORE NAME
                      TextFormField(
                        controller: _nameController,
                        decoration:
                            const InputDecoration(labelText: 'Store Name'),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),

                      const SizedBox(height: 16),

                      /// STORE TYPE
                      DropdownButtonFormField<String>(
                        value: selectedType,
                        decoration:
                            const InputDecoration(labelText: 'Store Type'),
                        items: storeTypes
                            .map((t) =>
                                DropdownMenuItem(value: t, child: Text(t)))
                            .toList(),
                        onChanged: (v) {
                          setState(() {
                            selectedType = v!;
                            if (v != 'others') {
                              _otherTypeController.clear();
                            }
                          });
                        },
                      ),

                      if (selectedType == 'others') ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _otherTypeController,
                          decoration: const InputDecoration(
                            labelText: 'Specify store type',
                          ),
                          validator: (v) {
                            if (selectedType == 'others' &&
                                (v == null || v.trim().isEmpty)) {
                              return 'Please specify the store type';
                            }
                            return null;
                          },
                        ),
                      ],

                      const SizedBox(height: 16),

                      /// BARANGAY
                      DropdownButtonFormField<String>(
                        value: selectedBarangay,
                        decoration:
                            const InputDecoration(labelText: 'Barangay'),
                        items: barangays
                            .map((b) =>
                                DropdownMenuItem(value: b, child: Text(b)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => selectedBarangay = v),
                      ),

                      const SizedBox(height: 16),

                      /// ADDRESS
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Street / Detailed Address',
                        ),
                      ),

                      const SizedBox(height: 16),

                      /// LOCATION
                      ElevatedButton.icon(
                        onPressed: _pickLocation,
                        icon: const Icon(Icons.map),
                        label: const Text('Change Location'),
                      ),

                      const SizedBox(height: 24),

                      /// SAVE BUTTON
                      ElevatedButton(
                        onPressed: _submit,
                        child: const Text('Save Changes'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
