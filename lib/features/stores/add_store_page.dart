import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddStorePage extends StatefulWidget {
  const AddStorePage({super.key});

  @override
  State<AddStorePage> createState() => _AddStorePageState();
}

class _AddStorePageState extends State<AddStorePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  GoogleMapController? _mapController;
  final LatLng _initialPosition = const LatLng(14.5995, 120.9842); // Manila default
  Marker? _selectedMarker;

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _selectedMarker = Marker(
        markerId: const MarkerId('selectedStore'),
        position: position,
      );
    });
  }

  Future<void> _saveStore() async {
    if (_formKey.currentState!.validate() && _selectedMarker != null) {
      await FirebaseFirestore.instance.collection('stores').add({
        'name': _nameController.text,
        'address': _addressController.text,
        'location': GeoPoint(
          _selectedMarker!.position.latitude,
          _selectedMarker!.position.longitude,
        ),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Store added successfully!')),
      );

      _nameController.clear();
      _addressController.clear();
      setState(() {
        _selectedMarker = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Store'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Store Name'),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Enter a name' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'Address'),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Enter an address' : null,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: GoogleMap(
                      onMapCreated: _onMapCreated,
                      initialCameraPosition: CameraPosition(
                        target: _initialPosition,
                        zoom: 14,
                      ),
                      markers: _selectedMarker != null
                          ? {_selectedMarker!}
                          : {},
                      onTap: _onMapTap,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _saveStore,
                    child: const Text('Save Store'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
