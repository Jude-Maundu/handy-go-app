import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemNavigator;
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import 'jobs_screen.dart';
import 'user_screen.dart';
import 'reports_screen.dart';

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
        const SnackBar(content: Text('Press back again to exit'), duration: Duration(seconds: 2), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) { if (!didPop) _onBackPressed(); },
      child: Scaffold(
        body: IndexedStack(index: _index, children: _tabs),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
            NavigationDestination(icon: Icon(Icons.work_outline), selectedIcon: Icon(Icons.work), label: 'Jobs'),
            NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Users'),
            NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Reports'),
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
      context.read<AdminProvider>().fetchPlatformStats();
    });
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
            Text('Hello, ${auth.userName?.split(' ').first ?? 'Admin'} 👋',
                style: TextStyle(fontSize: 13, color: AC.textSec(context))),
            const Text('Admin Panel', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<AdminProvider>().fetchPlatformStats(),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) async {
              if (v == 'logout') {
                await context.read<AuthProvider>().logout();
                if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
              }
            },
            itemBuilder: (_) => const [PopupMenuItem(value: 'logout', child: Text('Log Out'))],
          ),
        ],
      ),
      body: Consumer<AdminProvider>(
        builder: (context, admin, _) {
          if (admin.isLoading && admin.platformStats.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (admin.error != null) {
            return Center(child: Text(admin.error!, style: const TextStyle(color: Colors.red)));
          }

          final s = admin.platformStats;
          return RefreshIndicator(
            onRefresh: () => admin.fetchPlatformStats(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Revenue hero card
                _RevenueCard(
                  revenue: (s['totalRevenue'] as double?) ?? 0.0,
                  gmv: (s['totalGMV'] as double?) ?? 0.0,
                ),
                const SizedBox(height: 16),

                // Stat grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    _StatCard(label: 'Total Jobs', value: '${s['totalJobs'] ?? 0}', icon: Icons.work_outline, color: Colors.blue),
                    _StatCard(label: 'Active', value: '${s['activeJobs'] ?? 0}', icon: Icons.hourglass_top_outlined, color: Colors.orange),
                    _StatCard(label: 'Completed', value: '${s['completedJobs'] ?? 0}', icon: Icons.check_circle_outline, color: Colors.green),
                    _StatCard(label: 'Pending', value: '${s['pendingJobs'] ?? 0}', icon: Icons.pending_outlined, color: Colors.purple),
                  ],
                ),
                const SizedBox(height: 16),

                // Users row
                Row(
                  children: [
                    Expanded(child: _StatCard(label: 'Clients', value: '${s['totalClients'] ?? 0}', icon: Icons.person_outline, color: Colors.teal)),
                    const SizedBox(width: 12),
                    Expanded(child: _StatCard(label: 'Fundis', value: '${s['totalFundis'] ?? 0}', icon: Icons.build_outlined, color: Colors.indigo)),
                  ],
                ),
                const SizedBox(height: 24),

                // Category breakdown
                if (admin.categoryStats.isNotEmpty) ...[
                  Text('Top Categories', style: TextStyle(color: AC.text(context), fontWeight: FontWeight.w700, fontSize: 15)),
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

class _RevenueCard extends StatelessWidget {
  final double revenue;
  final double gmv;
  const _RevenueCard({required this.revenue, required this.gmv});

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
          const Text('Platform Revenue (10%)', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 6),
          Text('KES ${revenue.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.swap_horiz, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text('Total GMV: KES ${gmv.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
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
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AC.surface(context), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(color: AC.text(context), fontSize: 22, fontWeight: FontWeight.bold)),
              Text(label, style: TextStyle(color: AC.textSec(context), fontSize: 12)),
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
              Text(cat['name'] as String, style: TextStyle(color: AC.text(context), fontWeight: FontWeight.w500, fontSize: 13)),
              Text('${cat['jobs']} jobs · KES ${(cat['revenue'] as double).toStringAsFixed(0)}',
                  style: TextStyle(color: AC.textSec(context), fontSize: 12)),
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
