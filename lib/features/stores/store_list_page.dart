import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

import '../../core/services/firestore_service.dart';
import '../../models/store_model.dart' as sm;
import 'store_detail_page.dart';
import 'store_card.dart';
import 'store_filters.dart';

class StoreListPage extends StatefulWidget {
  const StoreListPage({super.key});

  @override
  State<StoreListPage> createState() => _StoreListPageState();
}

class _StoreListPageState extends State<StoreListPage> {
  final FirestoreService _service = FirestoreService.instance;
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
  bool isAdmin = false;

  /// filters
  String? selectedType;
  String? selectedBarangay;
  String searchQuery = '';

  /// location
  Position? userPosition;

  /// store data
  final List<sm.StoreModel> _stores = [];
  bool _isLoading = true;

  final ScrollController _scrollController = ScrollController();

  /// constants
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
    'Batingan','Bilibiran','Ithan','Calumpang','Kalawaan','Kalinawan','Mahabang Parang',
    'Layunan','Libid','Libis','Limbon-limbon','Lunsad','Macamot','Mambog','Pag-asa',
    'Palangoy','Pantok','Pila-pila','Pipindan','San Carlos','Tagpos','Tatala','Tayuman',
  ];

  /// Firestore listener
  StreamSubscription<QuerySnapshot>? _storeSubscription;

  @override
  void initState() {
    super.initState();
    _checkAdmin();
    _getUserLocation();
    _listenToStores();
  }

  @override
  void dispose() {
    _storeSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  /// ---------------- ADMIN ----------------
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

  /// ---------------- LOCATION ----------------
  Future<void> _getUserLocation() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    userPosition = await Geolocator.getCurrentPosition();
    if (!mounted) return;

    if (_stores.isNotEmpty) {
      setState(() {
        _stores.sort((a, b) => _distanceToUser(a).compareTo(_distanceToUser(b)));
      });
    }
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

  /// ---------------- FIRESTORE REAL-TIME ----------------
  void _listenToStores() {
    _storeSubscription = FirebaseFirestore.instance
        .collection('stores')
        .where('approved', isEqualTo: true)
        .snapshots()
        .listen((snap) {
      _stores.clear();
      _stores.addAll(
        snap.docs.map(
          (d) => sm.StoreModel.fromMap(d.data(), d.id),
        ),
      );

      if (userPosition != null) {
        _stores.sort((a, b) => _distanceToUser(a).compareTo(_distanceToUser(b)));
      }

      if (mounted) setState(() => _isLoading = false);
    });
  }

  /// ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    // apply filters locally
    var filteredStores = List<sm.StoreModel>.from(_stores);

    // 🔹 TYPE FILTER
    if (selectedType != null) {
      final filterLower = selectedType!.trim().toLowerCase();
      final normalTypes = storeTypes.map((e) => e.toLowerCase()).toList();

      filteredStores = filteredStores.where((s) {
        final original = s.originalDropdownType?.trim().toLowerCase();
        final type = s.type.trim().toLowerCase();

        if (filterLower == 'others') {
          // include literal "others" + any custom types
          if (original == 'others') return true;
          if (original == null && type != '' && !normalTypes.contains(type)) return true;
          if (original == null && type == 'others') return true;
          return false;
        }

        // Normal types match
        if (original == null) return type == filterLower;
        if (original == filterLower) return true;
        if (original == 'others' && type == filterLower) return true;

        return false;
      }).toList();

      // 🔹 DEBUG
      print('Selected type: $selectedType, filteredStores count: ${filteredStores.length}');
      for (var s in filteredStores) {
        print('Store: ${s.name}, original: ${s.originalDropdownType}, type: ${s.type}');
      }
    }

    // 🔹 BARANGAY FILTER
    if (selectedBarangay != null) {
      filteredStores = filteredStores
          .where((s) => s.barangay == selectedBarangay)
          .toList();
    }

    // 🔹 SEARCH FILTER
    if (searchQuery.isNotEmpty) {
      filteredStores = filteredStores
          .where((s) => s.name.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Stores')),
      body: Column(
        children: [
          /// FILTERS
          StoreFilters(
            storeTypes: storeTypes,
            storeTypeIcons: storeTypeIcons,
            barangays: barangays,
            selectedType: selectedType,
            selectedBarangay: selectedBarangay,
            onTypeChanged: (value) => setState(() => selectedType = value),
            onBarangayChanged: (value) => setState(() => selectedBarangay = value),
            onSearchChanged: (value) => setState(() => searchQuery = value),
          ),

          /// LIST
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredStores.isEmpty
                    ? const Center(child: Text('No stores found.'))
                    : ListView.separated(
                        controller: _scrollController,
                        itemCount: filteredStores.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final s = filteredStores[index];
                          final canDelete = isAdmin || currentUserId == s.ownerId;

                          return StoreCard(
                            store: s,
                            distanceKm: _distanceToUser(s) / 1000,
                            canDelete: canDelete,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StoreDetailPage(store: s),
                              ),
                            ),
                            onDelete: canDelete
                                ? () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text('Delete store?'),
                                        content: const Text(
                                          'This action cannot be undone.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      await _service.deleteStore(s.id);
                                    }
                                  }
                                : null,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
