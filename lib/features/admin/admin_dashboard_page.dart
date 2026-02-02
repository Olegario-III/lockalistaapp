// lib/features/admin/admin_dashboard_page.dart
import 'package:flutter/material.dart';

import 'approvals/approval_events_page.dart';
import 'approvals/approval_stores_page.dart';
import 'verification/verification_requests_page.dart';
import 'reports/reported_accounts_page.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Pending Events'),
              Tab(text: 'Pending Stores'),
              Tab(text: 'Verifications'),
              Tab(text: 'Reports'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ApprovalEventsPage(),
            ApprovalStoresPage(),
            VerificationRequestsPage(),
            ReportedAccountsPage(),
          ],
        ),
      ),
    );
  }
}
