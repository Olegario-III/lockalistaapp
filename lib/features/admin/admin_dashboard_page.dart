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

  final List<bool> _hideCounters = List.filled(5, false);

  final List<_DashboardItem> items = [
    _DashboardItem(
      title: 'Pending Events',
      icon: Icons.event,
      collection: 'events',
      field: 'status',
      isEqualTo: 'pending',
    ),
    _DashboardItem(
      title: 'Pending Stores',
      icon: Icons.store,
      collection: 'stores',
      field: 'status',
      isEqualTo: 'pending',
    ),
    _DashboardItem(
      title: 'Verifications',
      icon: Icons.verified,
      collection: 'verification_requests',
    ),
    _DashboardItem(
      title: 'Reports',
      icon: Icons.report,
      collection: 'reports',
    ),
    _DashboardItem(
      title: 'Customer Messages',
      icon: Icons.message,
      collection: 'customer_messages',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: items.length, vsync: this);
  }

  void _selectTab(int index) {
    setState(() {
      _tabController.index = index;
      _hideCounters[index] = true;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const ApprovalEventsPage(),
      const ApprovalStoresPage(),
      const VerificationRequestsPage(),
      const ReportedAccountsPage(),
      const AdminCustomerMessagesPage(),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: Column(
        children: [
          // 🔥 WRAPPED BUTTON TABS
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(items.length, (index) {
                final item = items[index];
                final isSelected = _tabController.index == index;

                return GestureDetector(
                  onTap: () => _selectTab(index),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.blue
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.icon,
                          size: 18,
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          item.title,
                          style: TextStyle(
                            color:
                                isSelected ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        // 🔴 COUNTER
                        TabCounter(
                          collection: item.collection,
                          field: item.field,
                          isEqualTo: item.isEqualTo,
                          hideBadge: _hideCounters[index],
                          onNewItems: () {
                            setState(() => _hideCounters[index] = false);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),

          // 🔥 TAB CONTENT (STILL WORKS LIKE TAB)
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: pages,
            ),
          ),
        ],
      ),
    );
  }
}

// 🔹 ITEM MODEL
class _DashboardItem {
  final String title;
  final IconData icon;
  final String collection;
  final String? field;
  final dynamic isEqualTo;

  _DashboardItem({
    required this.title,
    required this.icon,
    required this.collection,
    this.field,
    this.isEqualTo,
  });
}

// 🔹 COUNTER (same logic)
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

        if (count > _lastCount) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onNewItems();
          });
        }

        _lastCount = count;

        if (count == 0 || widget.hideBadge) {
          return const SizedBox();
        }

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