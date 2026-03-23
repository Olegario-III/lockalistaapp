// lib/features/admin/admin_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'approvals/approval_events_page.dart';
import 'approvals/approval_stores_page.dart';
import 'verification/verification_requests_page.dart';
import 'reports/reported_accounts_page.dart';
import 'customer_messages/admin_customer_messages_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Track which counters have been dismissed
  final List<bool> _hideCounters = List.filled(5, false);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _hideCounters[_tabController.index] = true; // hide counter on tap
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(
              child: Row(
                children: [
                  const Text('Pending Events'),
                  TabCounter(
                    collection: 'events',
                    field: 'status',
                    isEqualTo: 'pending',
                    hideBadge: _hideCounters[0],
                    onNewItems: () {
                      setState(() => _hideCounters[0] = false);
                    },
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                children: [
                  const Text('Pending Stores'),
                  TabCounter(
                    collection: 'stores',
                    field: 'status',
                    isEqualTo: 'pending',
                    hideBadge: _hideCounters[1],
                    onNewItems: () {
                      setState(() => _hideCounters[1] = false);
                    },
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                children: [
                  const Text('Verifications'),
                  TabCounter(
                    collection: 'verificationRequests',
                    hideBadge: _hideCounters[2],
                    onNewItems: () {
                      setState(() => _hideCounters[2] = false);
                    },
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                children: [
                  const Text('Reports'),
                  TabCounter(
                    collection: 'reports',
                    hideBadge: _hideCounters[3],
                    onNewItems: () {
                      setState(() => _hideCounters[3] = false);
                    },
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                children: [
                  const Text('Messages'),
                  TabCounter(
                    collection: 'messages',
                    hideBadge: _hideCounters[4],
                    onNewItems: () {
                      setState(() => _hideCounters[4] = false);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController, // 🔹 use the same controller
        children: const [
          ApprovalEventsPage(),
          ApprovalStoresPage(),
          VerificationRequestsPage(),
          ReportedAccountsPage(),
          AdminCustomerMessagesPage(),
        ],
      ),
    );
  }
}

/// 🔹 TabCounter widget with auto-refresh and hide-on-tap
class TabCounter extends StatefulWidget {
  final String collection;
  final String? field;
  final dynamic isEqualTo;
  final bool hideBadge;
  final VoidCallback onNewItems;

  const TabCounter({
    super.key,
    required this.collection,
    this.field,
    this.isEqualTo,
    required this.hideBadge,
    required this.onNewItems,
  });

  @override
  State<TabCounter> createState() => _TabCounterState();
}

class _TabCounterState extends State<TabCounter> {
  int _lastCount = 0;

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance.collection(widget.collection);
    if (widget.field != null) {
      query = query.where(widget.field!, isEqualTo: widget.isEqualTo);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        int count = snapshot.hasData ? snapshot.data!.docs.length : 0;

        // Show badge again if new items appear
        if (count > _lastCount) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onNewItems();
          });
        }
        _lastCount = count;

        if (count == 0 || widget.hideBadge) return const SizedBox();

        return Container(
          margin: const EdgeInsets.only(left: 6),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        );
      },
    );
  }
}