// lib/features/stores/store_list_page.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/services/firestore_service.dart';
import '../../models/store_model.dart' as sm;
import 'store_detail_page.dart';

class StoreListPage extends StatefulWidget {
  const StoreListPage({super.key});

  @override
  State<StoreListPage> createState() => _StoreListPageState();
}

class _StoreListPageState extends State<StoreListPage> {
  final FirestoreService _service = FirestoreService.instance;

  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
  bool isAdmin = false;

  String? selectedType;
  String? selectedBarangay;
  Position? userPosition;

  final List<String> storeTypes = [
    'pharmacy',
    'resort',
    'grocery',
    'sari-sari store',
    'karenderya',
    'others',
  ];

  final List<String> barangays = [
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
    'Tayuman'
  ];

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _checkAdmin();
  }

  // 🔐 Check admin role from Firestore
  Future<void> _checkAdmin() async {
    if (currentUserId == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('admins')
        .doc(currentUserId)
        .get();

    if (mounted) {
      setState(() {
        isAdmin = doc.exists;
      });
    }
  }

  // 📍 Get user location
  Future<void> _getUserLocation() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    userPosition = await Geolocator.getCurrentPosition();
    setState(() {});
  }

  // 📏 Distance calculation
  double _distanceToUser(sm.StoreModel store) {
    if (userPosition == null) return double.infinity;

    return Geolocator.distanceBetween(
      userPosition!.latitude,
      userPosition!.longitude,
      store.location.latitude,
      store.location.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stores')),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: StreamBuilder<List<sm.StoreModel>>(
              stream: _service.getApprovedStoresStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var stores = snapshot.data!;

                // 🔍 Apply filters
                if (selectedType != null) {
                  stores = stores
                      .where((s) => s.type == selectedType)
                      .toList();
                }

                if (selectedBarangay != null) {
                  stores = stores
                      .where((s) => s.barangay == selectedBarangay)
                      .toList();
                }

                // 📍 Sort by distance
                stores.sort(
                  (a, b) =>
                      _distanceToUser(a).compareTo(_distanceToUser(b)),
                );

                if (stores.isEmpty) {
                  return const Center(child: Text('No stores found.'));
                }

                return ListView.separated(
                  itemCount: stores.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final s = stores[index];

                    final canDelete =
                        isAdmin || currentUserId == s.ownerId;

                    return ListTile(
                      leading: s.imageUrl.isNotEmpty
                          ? Image.network(
                              s.imageUrl,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.store),
                      title: Text(s.name),
                      subtitle: Text(
                        '${s.averageRating.toStringAsFixed(1)} ★ • '
                        '${(_distanceToUser(s) / 1000).toStringAsFixed(2)} km',
                      ),
                      trailing: canDelete
                          ? IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                              onPressed: () async {
                                final confirm =
                                    await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title:
                                        const Text('Delete store?'),
                                    content: const Text(
                                      'This action cannot be undone.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(
                                                context, false),
                                        child:
                                            const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(
                                                context, true),
                                        child:
                                            const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  await _service.deleteStore(s.id);
                                }
                              },
                            )
                          : null,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              StoreDetailPage(store: s),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 🔘 Filters UI
  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: storeTypes.map((type) {
              final selected = selectedType == type;
              return ChoiceChip(
                label: Text(type),
                selected: selected,
                onSelected: (_) {
                  setState(() {
                    selectedType = selected ? null : type;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: selectedBarangay,
            hint: const Text('Filter by Barangay'),
            items: barangays
                .map(
                  (b) => DropdownMenuItem(
                    value: b,
                    child: Text(b),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() => selectedBarangay = value);
            },
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }
}
