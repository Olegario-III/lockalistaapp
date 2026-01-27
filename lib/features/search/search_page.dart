// lib/features/search/search_page.dart
import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/services/firestore_service.dart';
import '../../models/event_model.dart' as em;
import '../../models/store_model.dart' as sm;

import '../events/event_detail_page.dart';
import '../stores/store_detail_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final FirestoreService _service = FirestoreService.instance;
  final TextEditingController _controller = TextEditingController();

  Timer? _debounce;
  bool _loading = false;

  List<em.EventModel> _events = [];
  List<sm.StoreModel> _stores = [];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _doSearch(q.trim());
    });
  }

  Future<void> _doSearch(String q) async {
    if (q.isEmpty) {
      setState(() {
        _events.clear();
        _stores.clear();
        _loading = false;
      });
      return;
    }

    setState(() => _loading = true);

    final events = await _service.searchEvents(q); // title
    final stores = await _service.searchStores(q); // name

    setState(() {
      _events = events;
      _stores = stores;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _controller,
              onChanged: _onSearchChanged,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search events or stores',
                border: OutlineInputBorder(),
              ),
            ),
          ),

          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                // ================= EVENTS FIRST =================
                if (_events.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      'Events',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ..._events.map(_buildEventResult),
                ],

                // ================= STORES =================
                if (_stores.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      'Stores',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ..._stores.map(_buildStoreResult),
                ],

                if (!_loading &&
                    _events.isEmpty &&
                    _stores.isEmpty &&
                    _controller.text.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('No results found')),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= EVENT RESULT UI =================
  Widget _buildEventResult(em.EventModel e) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EventDetailPage(event: e),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (e.imageUrl?.isNotEmpty == true)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  e.imageUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    e.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= STORE RESULT UI =================
  Widget _buildStoreResult(sm.StoreModel s) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: s.images.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  s.images.first,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              )
            : const Icon(Icons.store, size: 40),
        title: Text(
          s.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${s.type}'),
            Text('Barangay: ${s.barangay}'),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StoreDetailPage(store: s),
            ),
          );
        },
      ),
    );
  }
}
