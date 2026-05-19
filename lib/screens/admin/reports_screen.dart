import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/admin_provider.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final admin = context.read<AdminProvider>();
      if (admin.platformStats.isEmpty) admin.fetchPlatformStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AC.bg(context),
      appBar: AppBar(
        backgroundColor: AC.bg(context),
        title: const Text('Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<AdminProvider>().fetchPlatformStats(),
          ),
        ],
      ),
      body: Consumer<AdminProvider>(
        builder: (context, admin, _) {
          if (admin.isLoading && admin.platformStats.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final s = admin.platformStats;
          final totalRevenue = (s['totalRevenue'] as double?) ?? 0.0;
          final totalGMV = (s['totalGMV'] as double?) ?? 0.0;
          final totalJobs = (s['totalJobs'] as int?) ?? 0;
          final completedJobs = (s['completedJobs'] as int?) ?? 0;
          final totalClients = (s['totalClients'] as int?) ?? 0;
          final totalFundis = (s['totalFundis'] as int?) ?? 0;
          final completionRate = totalJobs > 0 ? completedJobs / totalJobs : 0.0;

          return RefreshIndicator(
            onRefresh: () => admin.fetchPlatformStats(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Summary cards
                _sectionTitle('Platform Summary', context),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.45,
                  children: [
                    _MetricCard(label: 'Total Revenue', value: 'KES ${totalRevenue.toStringAsFixed(0)}', sub: '10% commission', icon: Icons.monetization_on_outlined, color: Colors.blue),
                    _MetricCard(label: 'Gross Volume', value: 'KES ${totalGMV.toStringAsFixed(0)}', sub: 'All completed jobs', icon: Icons.swap_horiz, color: Colors.teal),
                    _MetricCard(label: 'Total Jobs', value: '$totalJobs', sub: '$completedJobs completed', icon: Icons.work_outline, color: Colors.purple),
                    _MetricCard(label: 'Completion Rate', value: '${(completionRate * 100).toStringAsFixed(1)}%', sub: 'Job success rate', icon: Icons.check_circle_outline, color: Colors.green),
                    _MetricCard(label: 'Clients', value: '$totalClients', sub: 'Registered users', icon: Icons.person_outline, color: Colors.orange),
                    _MetricCard(label: 'Fundis', value: '$totalFundis', sub: 'Service providers', icon: Icons.build_outlined, color: Colors.indigo),
                  ],
                ),
                const SizedBox(height: 24),

                // Monthly revenue chart
                _sectionTitle('Revenue (Last 6 Months)', context),
                const SizedBox(height: 12),
                _RevenueChart(data: admin.monthlyRevenue),
                const SizedBox(height: 24),

                // Category breakdown
                if (admin.categoryStats.isNotEmpty) ...[
                  _sectionTitle('Jobs by Category', context),
                  const SizedBox(height: 12),
                  ...admin.categoryStats.map((c) => _CategoryBar(cat: c)),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String text, BuildContext context) =>
      Text(text, style: TextStyle(color: AC.text(context), fontWeight: FontWeight.w700, fontSize: 15));
}

class _MetricCard extends StatelessWidget {
  final String label, value, sub;
  final IconData icon;
  final Color color;
  const _MetricCard({required this.label, required this.value, required this.sub, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AC.surface(context), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Expanded(child: Text(label, style: TextStyle(color: AC.textSec(context), fontSize: 11))),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(color: AC.text(context), fontSize: 16, fontWeight: FontWeight.bold)),
              Text(sub, style: TextStyle(color: AC.textSec(context), fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RevenueChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _RevenueChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Container(
        height: 120,
        decoration: BoxDecoration(color: AC.surface(context), borderRadius: BorderRadius.circular(14)),
        child: const Center(child: Text('No data yet', style: TextStyle(color: AppColors.textSecondary))),
      );
    }
    return Container(
      height: 140,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(color: AC.surface(context), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: data.map((m) {
                final pct = (m['pct'] as double? ?? 0.0).clamp(0.0, 1.0);
                final revenue = (m['revenue'] as double?) ?? 0.0;
                return Tooltip(
                  message: 'KES ${revenue.toStringAsFixed(0)}',
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(revenue > 0 ? '${(revenue / 1000).toStringAsFixed(1)}k' : '0',
                          style: TextStyle(color: AC.textSec(context), fontSize: 9)),
                      const SizedBox(height: 4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        width: 28,
                        height: pct > 0 ? (80 * pct).clamp(4.0, 80.0) : 4.0,
                        decoration: BoxDecoration(
                          color: pct > 0 ? Colors.blue : AC.div(context),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: data.map((m) => Text(m['label'] as String, style: TextStyle(color: AC.textSec(context), fontSize: 11))).toList(),
          ),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final Map<String, dynamic> cat;
  const _CategoryBar({required this.cat});

  @override
  Widget build(BuildContext context) {
    final pct = (cat['pct'] as double? ?? 0.0).clamp(0.0, 1.0);
    final revenue = (cat['revenue'] as double?) ?? 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(cat['name'] as String, style: TextStyle(color: AC.text(context), fontWeight: FontWeight.w500, fontSize: 13)),
              Text('${cat['jobs']} jobs · KES ${revenue.toStringAsFixed(0)}',
                  style: TextStyle(color: AC.textSec(context), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 7,
              backgroundColor: AC.div(context),
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 3),
          Text('${(pct * 100).toStringAsFixed(1)}% of jobs', style: TextStyle(color: AC.textSec(context), fontSize: 10)),
        ],
      ),
    );
  }
}
