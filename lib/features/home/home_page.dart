// lib/features/home/home_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/services/auth_service.dart';
import '../stores/store_list_page.dart';
import '../events/event_list_page.dart';
import '../events/add_event_page.dart';
import '../stores/add_store_page.dart';
import '../search/search_page.dart';
import '../profile/profile_page.dart';
import '../admin/admin_dashboard_page.dart';

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
    // Setup pages
    _pages = [
      EventListPage(),
      StoreListPage(),
      SearchPage(),
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
        _pages.add(AdminDashboardPage());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Main body
      body: _pages[_currentIndex],

      // Floating Action Button for Add Event / Add Store
      floatingActionButton: _buildFAB(context),

      // Bottom Navigation Bar
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
            icon: Icon(Icons.store),
            label: 'Stores',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
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

  /// Returns the FAB depending on selected tab
  Widget? _buildFAB(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) return null; // Not logged in, no FAB

    // Events tab
    if (_currentIndex == 0) {
      return FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEventPage()),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Add Event (Pending Approval)',
      );
    }

    // Stores tab
    if (_currentIndex == 1) {
      return FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddStorePage()),
          );
        },
        child: const Icon(Icons.add_business),
        tooltip: 'Add Store (Pending Approval)',
      );
    }

    // No FAB for other tabs
    return null;
  }
}
