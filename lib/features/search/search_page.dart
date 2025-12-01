// lib/features/search/search_page.dart
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
  final FirestoreService _service = const FirestoreService.instance;
  final TextEditingController _q = TextEditingController();
  List<em.EventModel> _events = [];
  List<sm.StoreModel> _stores = [];

  void _doSearch(String q) async {
    if (q.trim().isEmpty) {
      setState(() {
        _events = [];
        _stores = [];
      });
      return;
    }
    final ev = await _service.searchEvents(q);
    final st = await _service.searchStores(q);
    setState(() {
      _events = ev;
      _stores = st;
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
              controller: _q,
              onChanged: _doSearch,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search events or stores'),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                if (_events.isNotEmpty) const Padding(padding: EdgeInsets.all(8), child: Text('Events', style: TextStyle(fontWeight: FontWeight.bold))),
                ..._events.map((e) => ListTile(title: Text(e.title), subtitle: Text(e.description, maxLines: 1, overflow: TextOverflow.ellipsis), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailPage(event: e))))),
                if (_stores.isNotEmpty) const Padding(padding: EdgeInsets.all(8), child: Text('Stores', style: TextStyle(fontWeight: FontWeight.bold))),
                ..._stores.map((s) => ListTile(title: Text(s.name), subtitle: Text(s.description ?? '', maxLines: 1, overflow: TextOverflow.ellipsis), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StoreDetailPage(store: s))))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
