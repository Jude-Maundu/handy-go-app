import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemNavigator;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../models/job_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import 'jobs_screen.dart';
import 'user_screen.dart';
import 'reports_screen.dart';
import 'finance_screen.dart';
import 'settings_screen.dart';

// ── Admin shell with bottom nav ───────────────────────────────────────────────

class AdminDashScreen extends StatefulWidget {
  const AdminDashScreen({super.key});

  @override
  State<AdminDashScreen> createState() => _AdminDashScreenState();
}

class _AdminDashScreenState extends State<AdminDashScreen> {
  int _index = 0;
  DateTime? _lastBackPress;

  static const _tabs = [
    _AdminOverviewTab(),
    AdminJobsScreen(),
    AdminUserScreen(),
    AdminReportsScreen(),
    AdminFinanceScreen(),
  ];

  void _onBackPressed() {
    if (_index != 0) {
      setState(() => _index = 0);
      return;
    }
    final now = DateTime.now();
    if (_lastBackPress != null && now.difference(_lastBackPress!) < const Duration(seconds: 2)) {
      SystemNavigator.pop();
    } else {
      _lastBackPress = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Press back again to exit'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingReports = context.watch<AdminProvider>().pendingReports.length;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBackPressed();
      },
      child: Scaffold(
        body: IndexedStack(index: _index, children: _tabs),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            const NavigationDestination(
              icon: Icon(Icons.work_outline),
              selectedIcon: Icon(Icons.work),
              label: 'Jobs',
            ),
            const NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Users',
            ),
            NavigationDestination(
              icon: pendingReports > 0
                  ? Badge.count(count: pendingReports, child: const Icon(Icons.bar_chart_outlined))
                  : const Icon(Icons.bar_chart_outlined),
              selectedIcon: pendingReports > 0
                  ? Badge.count(count: pendingReports, child: const Icon(Icons.bar_chart))
                  : const Icon(Icons.bar_chart),
              label: 'Reports',
            ),
            const NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet),
              label: 'Finance',
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dashboard overview tab ────────────────────────────────────────────────────

class _AdminOverviewTab extends StatefulWidget {
  const _AdminOverviewTab();

  @override
  State<_AdminOverviewTab> createState() => _AdminOverviewTabState();
}

class _AdminOverviewTabState extends State<_AdminOverviewTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final admin = context.read<AdminProvider>();
      admin.fetchPlatformStats();
      admin.fetchReports();
    });
  }

  Future<void> _refresh() async {
    final admin = context.read<AdminProvider>();
    await Future.wait([admin.fetchPlatformStats(), admin.fetchReports()]);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AC.bg(context),
      appBar: AppBar(
        backgroundColor: AC.bg(context),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${auth.userName?.split(' ').first ?? 'Admin'}',
              style: TextStyle(fontSize: 13, color: AC.textSec(context)),
            ),
            const Text('Admin Panel', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Platform Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminSettingsScreen()),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) async {
              if (v == 'logout') {
                await context.read<AuthProvider>().logout();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
                }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'logout', child: Text('Log Out')),
            ],
          ),
        ],
      ),
      body: Consumer<AdminProvider>(
        builder: (context, admin, _) {
          if (admin.isLoading && admin.platformStats.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (admin.error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(admin.error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _refresh, child: const Text('Retry')),
                ],
              ),
            );
          }

          final s = admin.platformStats;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Revenue hero card
                _RevenueCard(
                  revenue: (s['totalRevenue'] as double?) ?? 0.0,
                  gmv: (s['totalGMV'] as double?) ?? 0.0,
                  paidJobs: (s['paidJobs'] as int?) ?? 0,
                  completedJobs: (s['completedJobs'] as int?) ?? 0,
                ),
                const SizedBox(height: 16),

                // Pending alerts
                if (admin.pendingReports.isNotEmpty) ...[
                  _AlertBanner(
                    icon: Icons.flag_outlined,
                    color: Colors.orange,
                    message:
                        '${admin.pendingReports.length} pending report${admin.pendingReports.length > 1 ? 's' : ''} need review',
                  ),
                  const SizedBox(height: 12),
                ],
                if ((s['pendingJobs'] as int? ?? 0) > 0) ...[
                  _AlertBanner(
                    icon: Icons.pending_outlined,
                    color: Colors.blue,
                    message:
                        '${s['pendingJobs']} job${(s['pendingJobs'] as int) > 1 ? 's' : ''} waiting for a fundi',
                  ),
                  const SizedBox(height: 16),
                ],

                // Stat grid — jobs
                Text('Jobs Overview',
                    style: TextStyle(
                        color: AC.text(context), fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.55,
                  children: [
                    _StatCard(
                        label: 'Total Jobs',
                        value: '${s['totalJobs'] ?? 0}',
                        icon: Icons.work_outline,
                        color: Colors.blue),
                    _StatCard(
                        label: 'Pending',
                        value: '${s['pendingJobs'] ?? 0}',
                        icon: Icons.pending_outlined,
                        color: Colors.orange),
                    _StatCard(
                        label: 'Active',
                        value: '${s['activeJobs'] ?? 0}',
                        icon: Icons.hourglass_top_outlined,
                        color: Colors.teal),
                    _StatCard(
                        label: 'Completed',
                        value: '${s['completedJobs'] ?? 0}',
                        icon: Icons.check_circle_outline,
                        color: Colors.green),
                  ],
                ),
                const SizedBox(height: 12),

                // Completion rate + cancelled
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Completion Rate',
                        value:
                            '${((s['completionRate'] as double? ?? 0.0) * 100).toStringAsFixed(1)}%',
                        icon: Icons.trending_up,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Cancelled',
                        value: '${s['cancelledJobs'] ?? 0}',
                        icon: Icons.cancel_outlined,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                const SizedBox(height: 12),
                // Platform health KPIs
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Avg Rating',
                        value: (s['avgPlatformRating'] as double? ?? 0.0) > 0
                            ? (s['avgPlatformRating'] as double).toStringAsFixed(1)
                            : 'N/A',
                        icon: Icons.star_outline,
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Revenue Growth',
                        value: () {
                          final g = (s['revenueGrowth'] as double? ?? 0.0) * 100;
                          return '${g >= 0 ? '+' : ''}${g.toStringAsFixed(1)}%';
                        }(),
                        icon: Icons.trending_up,
                        color: (s['revenueGrowth'] as double? ?? 0.0) >= 0
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'New This Week',
                        value: '${s['newJobsThisWeek'] ?? 0}',
                        icon: Icons.fiber_new_outlined,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Users
                Text('Users',
                    style: TextStyle(
                        color: AC.text(context), fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                          label: 'Clients',
                          value: '${s['totalClients'] ?? 0}',
                          icon: Icons.person_outline,
                          color: Colors.amber.shade700),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                          label: 'Fundis',
                          value: '${s['totalFundis'] ?? 0}',
                          icon: Icons.build_outlined,
                          color: Colors.indigo),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Recent jobs
                if (admin.recentJobs.isNotEmpty) ...[
                  Text('Recent Activity',
                      style: TextStyle(
                          color: AC.text(context), fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: AC.surface(context),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        for (int i = 0; i < admin.recentJobs.length; i++) ...[
                          _RecentJobRow(job: admin.recentJobs[i]),
                          if (i < admin.recentJobs.length - 1)
                            Divider(
                                height: 1,
                                indent: 56,
                                color: AC.div(context)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Category breakdown
                if (admin.categoryStats.isNotEmpty) ...[
                  Text('Top Categories',
                      style: TextStyle(
                          color: AC.text(context), fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 12),
                  ...admin.categoryStats.take(5).map((c) => _CategoryRow(cat: c)),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _AlertBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;
  const _AlertBanner({required this.icon, required this.color, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: TextStyle(color: color, fontSize: 13))),
        ],
      ),
    );
  }
}

class _RecentJobRow extends StatelessWidget {
  final Job job;
  const _RecentJobRow({required this.job});

  Color get _statusColor {
    switch (job.status) {
      case JobStatus.pending:
        return Colors.orange;
      case JobStatus.accepted:
        return Colors.blue;
      case JobStatus.inProgress:
        return Colors.teal;
      case JobStatus.completed:
        return Colors.green;
      case JobStatus.cancelled:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.work_outline, color: _statusColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.title,
                  style: TextStyle(
                      color: AC.text(context), fontWeight: FontWeight.w600, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  job.clientName != null ? 'by ${job.clientName}' : job.category,
                  style: TextStyle(color: AC.textSec(context), fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  job.statusText,
                  style: TextStyle(color: _statusColor, fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('MMM d').format(job.createdAt),
                style: TextStyle(color: AC.textSec(context), fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RevenueCard extends StatelessWidget {
  final double revenue;
  final double gmv;
  final int paidJobs;
  final int completedJobs;
  const _RevenueCard(
      {required this.revenue,
      required this.gmv,
      required this.paidJobs,
      required this.completedJobs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade800, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Platform Revenue', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 6),
          Text(
            'KES ${revenue.toStringAsFixed(0)}',
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.swap_horiz, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(
                'GMV: KES ${gmv.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const Spacer(),
              const Icon(Icons.payments_outlined, color: Colors.white70, size: 14),
              const SizedBox(width: 4),
              Text(
                '$paidJobs / $completedJobs paid',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard(
      {required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration:
          BoxDecoration(color: AC.surface(context), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration:
                BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 17),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      color: AC.text(context), fontSize: 20, fontWeight: FontWeight.bold)),
              Text(label, style: TextStyle(color: AC.textSec(context), fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final Map<String, dynamic> cat;
  const _CategoryRow({required this.cat});

  @override
  Widget build(BuildContext context) {
    final pct = (cat['pct'] as double? ?? 0.0).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(cat['name'] as String,
                  style: TextStyle(
                      color: AC.text(context), fontWeight: FontWeight.w500, fontSize: 13)),
              Text(
                '${cat['jobs']} jobs · KES ${(cat['revenue'] as double).toStringAsFixed(0)}',
                style: TextStyle(color: AC.textSec(context), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: AC.div(context),
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}
