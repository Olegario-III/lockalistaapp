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
  String searchQuery = '';

  Position? userPosition;

  final List<String> storeTypes = [
    'pharmacy',
    'resort',
    'grocery',
    'sari-sari store',
    'karenderya',
    'others',
  ];

  final Map<String, IconData> storeTypeIcons = {
    'pharmacy': Icons.local_pharmacy,
    'resort': Icons.beach_access,
    'grocery': Icons.shopping_cart,
    'sari-sari store': Icons.storefront,
    'karenderya': Icons.restaurant,
    'others': Icons.more_horiz,
  };

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
    'Tayuman',
  ];

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    if (currentUserId == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();

    if (!mounted) return;

    setState(() {
      isAdmin = doc.data()?['role'] == 'admin';
    });
  }

  Future<void> _getUserLocation() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    userPosition = await Geolocator.getCurrentPosition();
    if (mounted) setState(() {});
  }

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

                /// 🔍 TYPE FILTER
                if (selectedType != null) {
                  stores =
                      stores.where((s) => s.type == selectedType).toList();
                }

                /// 📍 BARANGAY FILTER
                if (selectedBarangay != null) {
                  stores = stores
                      .where((s) => s.barangay == selectedBarangay)
                      .toList();
                }

                /// 🔎 SEARCH FILTER
                if (searchQuery.isNotEmpty) {
                  stores = stores
                      .where((s) => s.name
                          .toLowerCase()
                          .contains(searchQuery.toLowerCase()))
                      .toList();
                }

                /// 📏 SORT BY DISTANCE
                stores.sort(
                  (a, b) =>
                      _distanceToUser(a).compareTo(_distanceToUser(b)),
                );

                if (stores.isEmpty) {
                  return const Center(child: Text('No stores found.'));
                }

                return ListView.separated(
                  itemCount: stores.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final s = stores[index];
                    final canDelete =
                        isAdmin || currentUserId == s.ownerId;

                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: s.imageUrl.isNotEmpty
                            ? Image.network(
                                s.imageUrl,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.store, size: 40),
                      ),
                      title: Text(
                        s.name,
                        style:
                            const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${s.averageRating.toStringAsFixed(1)} ★ • '
                        '${(_distanceToUser(s) / 1000).toStringAsFixed(2)} km',
                      ),
                      trailing: canDelete
                          ? IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.red),
                              onPressed: () async {
                                final confirm =
                                    await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title:
                                        const Text('Delete store?'),
                                    content: const Text(
                                        'This action cannot be undone.'),
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

  /// 🔘 FILTER UI (ICON + DROPDOWN + SEARCH)
  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          /// 🔹 ICON TYPE FILTER (HORIZONTAL)
          SizedBox(
            height: 70,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: storeTypes.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final type = storeTypes[index];
                final selected = selectedType == type;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedType = selected ? null : type;
                    });
                  },
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: selected
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                            : Colors.grey[300],
                        child: Icon(
                          storeTypeIcons[type],
                          color:
                              selected ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        type,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          /// 🔹 BARANGAY DROPDOWN
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

          const SizedBox(height: 8),

          /// 🔹 SEARCH BOX
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search store name...',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (value) {
              setState(() => searchQuery = value.trim());
            },
          ),
        ],
      ),
    );
  }
}
