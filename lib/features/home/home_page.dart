import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/services/auth_service.dart';
import '../events/event_list_page.dart';
import '../events/add_event_page.dart';
import '../stores/store_list_page.dart';
import '../stores/add_store_page.dart';
import '../profile/profile_page.dart';
import '../admin/admin_dashboard_page.dart';
import '../trending/trending_page.dart'; // ✅ NEW

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _auth = AuthService();
  int _currentIndex = 0;
  bool _isAdmin = false;

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _pages = [
      const EventListPage(),      // Home
      const StoreListPage(),      // Places
      const TrendingPage(),       // Trending
      if (_auth.currentUser != null)
        ProfilePage(userId: _auth.currentUser!.uid),
    ];

    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists && doc.data()?['role'] == 'admin') {
      setState(() {
        _isAdmin = true;
        _pages.add(const AdminDashboardPage());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      floatingActionButton: _buildFAB(context),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.place), // ✅ PLACES
            label: 'Places',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.trending_up), // ✅ TRENDING
            label: 'Trending',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          if (_isAdmin)
            const BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings),
              label: 'Admin',
            ),
        ],
      ),
    );
  }

  /// Floating Action Button logic
  Widget? _buildFAB(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) return null;

    // Add Event
    if (_currentIndex == 0) {
      return FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEventPage()),
          );
        },
        tooltip: 'Add Event (Pending Approval)',
        child: const Icon(Icons.add),
      );
    }

    // Add Place (Store)
    if (_currentIndex == 1) {
      return FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddStorePage()),
          );
        },
        tooltip: 'Add Place (Pending Approval)',
        child: const Icon(Icons.add_business),
      );
    }

    return null;
  }
}
