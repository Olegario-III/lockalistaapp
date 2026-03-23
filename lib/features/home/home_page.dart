// lib/features/home/home_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

import '../../core/services/auth_service.dart';
import '../events/event_list_page.dart';
import '../events/add_event_page.dart';
import '../stores/store_list_page.dart';
import '../stores/add_store_page.dart';
import '../profile/profile_page.dart';
import '../admin/admin_dashboard_page.dart';
import '../trending/trending_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _auth = AuthService();
  int _currentIndex = 0;
  bool _isAdmin = false;
  bool _hideAdminBadge = false;
  int _lastTotal = 0;

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _pages = [
      const EventListPage(),
      const StoreListPage(),
      const TrendingPage(),
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
        onTap: (index) {
          setState(() {
            _currentIndex = index;

            // hide badge when Admin tab is tapped
            if (_isAdmin && index == _pages.length - 1) {
              _hideAdminBadge = true;
            }
          });
        },
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(Icons.place), label: 'Places'),
          const BottomNavigationBarItem(icon: Icon(Icons.trending_up), label: 'Trending'),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          if (_isAdmin)
            BottomNavigationBarItem(
              icon: AdminTabIcon(
                hideBadge: _hideAdminBadge,
                lastTotal: _lastTotal,
                onNewItems: (newTotal) {
                  setState(() {
                    _hideAdminBadge = false;
                    _lastTotal = newTotal;
                  });
                },
              ),
              label: 'Admin',
            ),
        ],
      ),
    );
  }

  Widget? _buildFAB(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) return null;

    if (_currentIndex == 0) {
      return FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEventPage()));
        },
        tooltip: 'Add Event (Pending Approval)',
        child: const Icon(Icons.add),
      );
    }

    if (_currentIndex == 1) {
      return FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddStorePage()));
        },
        tooltip: 'Add Place (Pending Approval)',
        child: const Icon(Icons.add_business),
      );
    }

    return null;
  }
}

/// 🔹 Admin Tab Icon with total counter that can vanish
class AdminTabIcon extends StatelessWidget {
  final bool hideBadge;
  final int lastTotal;
  final void Function(int newTotal) onNewItems;

  const AdminTabIcon({
    super.key,
    required this.hideBadge,
    required this.lastTotal,
    required this.onNewItems,
  });

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return StreamBuilder<List<QuerySnapshot>>(
      stream: CombineLatestStream.list([
        firestore.collection('events').where('status', isEqualTo: 'pending').snapshots(),
        firestore.collection('stores').where('status', isEqualTo: 'pending').snapshots(),
        firestore.collection('verificationRequests').snapshots(),
        firestore.collection('reports').snapshots(),
        firestore.collection('messages').snapshots(),
      ]),
      builder: (context, snapshot) {
        int total = 0;
        if (snapshot.hasData) {
          for (var qs in snapshot.data!) {
            total += qs.docs.length;
          }

          // show badge again if new items arrive
          if (total > lastTotal) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              onNewItems(total);
            });
          }
        }

        if (hideBadge || total == 0) return const Icon(Icons.admin_panel_settings);

        return Stack(
          children: [
            const Icon(Icons.admin_panel_settings),
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  total.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}