import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/firestore_service.dart';
import '../../core/utils/helpers.dart';
import '../../models/store_model.dart';
import 'package:uuid/uuid.dart';

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

  Future<void> _pickLocation() async {
    final location = await Helpers.pickLocationOnMap(); // Implement with Google Maps picker
    if (location != null) {
      setState(() => selectedLocation = location);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || selectedLocation == null) return;

    setState(() => _loading = true);

    final id = const Uuid().v4();
    final store = StoreModel(
      id: id,
      name: _nameController.text.trim(),
      type: selectedType,
      barangay: selectedBarangay,
      location: selectedLocation!,
      ownerId: Helpers.currentUserId(), // implement this
    );

    await FirestoreService.instance.addStore(store);

    setState(() => _loading = false);
    Helpers.showSnackBar(context, 'Store added! Waiting for admin approval.');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Store')),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: 'Store Name'),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      items: ['pharmacy', 'resort', 'grocery', 'sari-sari store', 'karenderya', 'others']
                          .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                          .toList(),
                      onChanged: (v) => setState(() => selectedType = v!),
                      decoration: InputDecoration(labelText: 'Store Type'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedBarangay,
                      items: ['Darangan', 'Barangay2', 'Barangay3']
                          .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                          .toList(),
                      onChanged: (v) => setState(() => selectedBarangay = v!),
                      decoration: InputDecoration(labelText: 'Barangay'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _pickLocation,
                      icon: Icon(Icons.map),
                      label: Text(selectedLocation == null
                          ? 'Pick Store Location'
                          : 'Location Selected'),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _submit,
                      child: Text('Add Store'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
