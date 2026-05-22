import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_colors.dart';
import '../../providers/admin_provider.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final admin = context.read<AdminProvider>();
      if (admin.platformStats.isEmpty) admin.fetchPlatformStats();
      admin.fetchReports();
      admin.fetchSupportTickets();
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = context.watch<AdminProvider>().pendingReports.length;
    return Scaffold(
      backgroundColor: AC.bg(context),
      appBar: AppBar(
        backgroundColor: AC.bg(context),
        title: const Text('Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AdminProvider>().fetchPlatformStats();
              context.read<AdminProvider>().fetchReports();
              context.read<AdminProvider>().fetchSupportTickets();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.blue,
          labelColor: Colors.blue,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            const Tab(text: 'Analytics'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Flags'),
                  if (pendingCount > 0) ...[
                    const SizedBox(width: 6),
                    Badge.count(count: pendingCount),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Tickets'),
                  Builder(builder: (ctx) {
                    final openCount =
                        ctx.watch<AdminProvider>().openTickets.length;
                    if (openCount == 0) return const SizedBox.shrink();
                    return Row(children: [
                      const SizedBox(width: 6),
                      Badge.count(count: openCount),
                    ]);
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [_AnalyticsTab(), _FlagsTab(), _TicketsTab()],
      ),
    );
  }
}

// ── Analytics tab ─────────────────────────────────────────────────────────────

class _AnalyticsTab extends StatelessWidget {
  const _AnalyticsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        if (admin.isLoading && admin.platformStats.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final s = admin.platformStats;
        final totalRevenue = (s['totalRevenue'] as double?) ?? 0.0;
        final totalGMV = (s['totalGMV'] as double?) ?? 0.0;
        final totalJobs = (s['totalJobs'] as int?) ?? 0;
        final completedJobs = (s['completedJobs'] as int?) ?? 0;
        final cancelledJobs = (s['cancelledJobs'] as int?) ?? 0;
        final totalClients = (s['totalClients'] as int?) ?? 0;
        final totalFundis = (s['totalFundis'] as int?) ?? 0;
        final completionRate = (s['completionRate'] as double?) ?? 0.0;
        final paidJobs = (s['paidJobs'] as int?) ?? 0;

        return RefreshIndicator(
          onRefresh: () => admin.fetchPlatformStats(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
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
                  _MetricCard(
                      label: 'Platform Revenue',
                      value: 'KES ${totalRevenue.toStringAsFixed(0)}',
                      sub: '$paidJobs paid jobs',
                      icon: Icons.monetization_on_outlined,
                      color: Colors.blue),
                  _MetricCard(
                      label: 'Gross Volume',
                      value: 'KES ${totalGMV.toStringAsFixed(0)}',
                      sub: 'All completed jobs',
                      icon: Icons.swap_horiz,
                      color: Colors.teal),
                  _MetricCard(
                      label: 'Total Jobs',
                      value: '$totalJobs',
                      sub: '$completedJobs completed',
                      icon: Icons.work_outline,
                      color: Colors.purple),
                  _MetricCard(
                      label: 'Completion Rate',
                      value: '${(completionRate * 100).toStringAsFixed(1)}%',
                      sub: '$cancelledJobs cancelled',
                      icon: Icons.check_circle_outline,
                      color: Colors.green),
                  _MetricCard(
                      label: 'Clients',
                      value: '$totalClients',
                      sub: 'Registered users',
                      icon: Icons.person_outline,
                      color: Colors.orange),
                  _MetricCard(
                      label: 'Fundis',
                      value: '$totalFundis',
                      sub: 'Service providers',
                      icon: Icons.build_outlined,
                      color: Colors.indigo),
                ],
              ),
              const SizedBox(height: 24),

              _sectionTitle('Revenue — Last 6 Months', context),
              const SizedBox(height: 12),
              _RevenueChart(data: admin.monthlyRevenue),
              const SizedBox(height: 24),

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
    );
  }

  Widget _sectionTitle(String text, BuildContext context) =>
      Text(text, style: TextStyle(color: AC.text(context), fontWeight: FontWeight.w700, fontSize: 15));
}

// ── Flags tab ─────────────────────────────────────────────────────────────────

class _FlagsTab extends StatelessWidget {
  const _FlagsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        if (admin.reports.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.flag_outlined, size: 48, color: AppColors.textSecondary),
                const SizedBox(height: 12),
                Text('No reports yet',
                    style: TextStyle(color: AC.textSec(context), fontSize: 15)),
                const SizedBox(height: 6),
                Text('User-submitted flags will appear here.',
                    style: TextStyle(color: AC.textSec(context), fontSize: 13)),
              ],
            ),
          );
        }

        final pending = admin.reports.where((r) => r['status'] == 'pending').toList();
        final resolved = admin.reports.where((r) => r['status'] != 'pending').toList();

        return RefreshIndicator(
          onRefresh: () => admin.fetchReports(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (pending.isNotEmpty) ...[
                _sectionHeader(context, 'Open (${pending.length})', Colors.orange),
                const SizedBox(height: 8),
                ...pending.map((r) => _ReportCard(report: r)),
                const SizedBox(height: 20),
              ],
              if (resolved.isNotEmpty) ...[
                _sectionHeader(context, 'Resolved / Dismissed (${resolved.length})', Colors.grey),
                const SizedBox(height: 8),
                ...resolved.map((r) => _ReportCard(report: r)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _sectionHeader(BuildContext context, String text, Color color) => Row(
        children: [
          Container(width: 4, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(text,
              style: TextStyle(
                  color: AC.text(context), fontWeight: FontWeight.w700, fontSize: 14)),
        ],
      );
}

class _ReportCard extends StatelessWidget {
  final Map<String, dynamic> report;
  const _ReportCard({required this.report});

  String get _status => report['status'] as String? ?? 'pending';
  bool get _isPending => _status == 'pending';

  Color get _statusColor {
    switch (_status) {
      case 'resolved':
        return Colors.green;
      case 'dismissed':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  String _formatDate() {
    final ts = report['createdAt'];
    if (ts is Timestamp) return DateFormat('MMM d, y').format(ts.toDate());
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final reporter = report['reporterName'] as String? ?? 'Unknown';
    final reported = report['reportedName'] as String? ?? 'Unknown';
    final reason = report['reason'] as String? ?? 'No reason provided';
    final details = report['details'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AC.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: _isPending
            ? Border.all(color: Colors.orange.withValues(alpha: 0.3))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag, size: 16, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(reason,
                    style: TextStyle(
                        color: AC.text(context), fontWeight: FontWeight.w700, fontSize: 13)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(
                  _status[0].toUpperCase() + _status.substring(1),
                  style: TextStyle(color: _statusColor, fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow(context, 'Reporter', reporter, Icons.person_outline),
                    const SizedBox(height: 4),
                    _infoRow(context, 'Reported', reported, Icons.person_off_outlined),
                    if (details != null && details.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _infoRow(context, 'Details', details, Icons.info_outline),
                    ],
                    if (_formatDate().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _infoRow(context, 'Date', _formatDate(), Icons.calendar_today_outlined),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (_isPending) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _actionBtn(context, 'Dismiss', Colors.grey, () => _resolve(context, dismiss: true)),
                const SizedBox(width: 8),
                _actionBtn(context, 'Resolve', Colors.green, () => _resolve(context, dismiss: false)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _resolve(BuildContext context, {required bool dismiss}) async {
    final ok = await context
        .read<AdminProvider>()
        .resolveReport(report['id'] as String, dismiss: dismiss);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok
              ? 'Report ${dismiss ? 'dismissed' : 'resolved'}'
              : 'Failed to update report'),
          backgroundColor: ok ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Widget _infoRow(BuildContext context, String label, String value, IconData icon) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text('$label: ',
              style: TextStyle(color: AC.textSec(context), fontSize: 12)),
          Expanded(
            child: Text(value,
                style: TextStyle(color: AC.text(context), fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      );

  Widget _actionBtn(BuildContext context, String label, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
          child: Text(label,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      );
}

// ── Analytics widgets ─────────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  final String label, value, sub;
  final IconData icon;
  final Color color;
  const _MetricCard(
      {required this.label,
      required this.value,
      required this.sub,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration:
          BoxDecoration(color: AC.surface(context), borderRadius: BorderRadius.circular(16)),
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
              Text(value,
                  style: TextStyle(color: AC.text(context), fontSize: 16, fontWeight: FontWeight.bold)),
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
      height: 160,
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
                final jobs = (m['jobs'] as int?) ?? 0;
                return Tooltip(
                  message: 'KES ${revenue.toStringAsFixed(0)} · $jobs jobs',
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (revenue > 0)
                        Text(
                          revenue >= 1000
                              ? '${(revenue / 1000).toStringAsFixed(1)}k'
                              : revenue.toStringAsFixed(0),
                          style: TextStyle(color: AC.textSec(context), fontSize: 9),
                        ),
                      const SizedBox(height: 4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        width: 28,
                        height: pct > 0 ? (90 * pct).clamp(4.0, 90.0) : 4.0,
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
            children: data
                .map((m) => Text(m['label'] as String,
                    style: TextStyle(color: AC.textSec(context), fontSize: 11)))
                .toList(),
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
              Text(cat['name'] as String,
                  style: TextStyle(color: AC.text(context), fontWeight: FontWeight.w500, fontSize: 13)),
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
          Text('${(pct * 100).toStringAsFixed(1)}% of jobs',
              style: TextStyle(color: AC.textSec(context), fontSize: 10)),
        ],
      ),
    );
  }
}

// ── Support Tickets tab ───────────────────────────────────────────────────────

class _TicketsTab extends StatelessWidget {
  const _TicketsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        final tickets = admin.tickets;

        if (tickets.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.support_agent_outlined,
                    size: 48, color: AppColors.textSecondary),
                const SizedBox(height: 12),
                Text('No support tickets yet',
                    style: TextStyle(color: AC.textSec(context), fontSize: 15)),
                const SizedBox(height: 6),
                Text('User-submitted tickets will appear here.',
                    style: TextStyle(color: AC.textSec(context), fontSize: 13)),
              ],
            ),
          );
        }

        final open = tickets.where((t) => t['status'] == 'open').toList();
        final inProgress =
            tickets.where((t) => t['status'] == 'in_progress').toList();
        final closed = tickets
            .where((t) => t['status'] != 'open' && t['status'] != 'in_progress')
            .toList();

        return RefreshIndicator(
          onRefresh: () => admin.fetchSupportTickets(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary chips
              Row(
                children: [
                  _badge('Open', open.length, Colors.red),
                  const SizedBox(width: 8),
                  _badge('In Progress', inProgress.length, Colors.orange),
                  const SizedBox(width: 8),
                  _badge('Closed', closed.length, Colors.grey),
                ],
              ),
              const SizedBox(height: 16),
              if (open.isNotEmpty) ...[
                _header(context, 'Open (${open.length})', Colors.red),
                const SizedBox(height: 8),
                ...open.map((t) => _TicketCard(ticket: t)),
                const SizedBox(height: 20),
              ],
              if (inProgress.isNotEmpty) ...[
                _header(context, 'In Progress (${inProgress.length})', Colors.orange),
                const SizedBox(height: 8),
                ...inProgress.map((t) => _TicketCard(ticket: t)),
                const SizedBox(height: 20),
              ],
              if (closed.isNotEmpty) ...[
                _header(context, 'Closed (${closed.length})', Colors.grey),
                const SizedBox(height: 8),
                ...closed.map((t) => _TicketCard(ticket: t)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _badge(String label, int count, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20)),
        child: Text('$label: $count',
            style:
                TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      );

  Widget _header(BuildContext context, String text, Color color) => Row(
        children: [
          Container(
              width: 4,
              height: 14,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(text,
              style: TextStyle(
                  color: AC.text(context),
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
        ],
      );
}

class _TicketCard extends StatelessWidget {
  final Map<String, dynamic> ticket;
  const _TicketCard({required this.ticket});

  String get _status => ticket['status'] as String? ?? 'open';

  Color get _statusColor {
    switch (_status) {
      case 'open':
        return Colors.red;
      case 'in_progress':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate() {
    final ts = ticket['createdAt'];
    if (ts is Timestamp) return DateFormat('MMM d, y').format(ts.toDate());
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final subject = ticket['subject'] as String? ??
        ticket['title'] as String? ??
        'No subject';
    final userName = ticket['userName'] as String? ?? 'Unknown';
    final message = ticket['message'] as String? ?? ticket['body'] as String?;
    final adminNote = ticket['adminNote'] as String?;
    final isOpen = _status == 'open' || _status == 'in_progress';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AC.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: isOpen
            ? Border.all(color: _statusColor.withValues(alpha: 0.3))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.support_agent_outlined,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(subject,
                    style: TextStyle(
                        color: AC.text(context),
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(
                  _status == 'in_progress' ? 'In Progress' : _status[0].toUpperCase() + _status.substring(1),
                  style: TextStyle(
                      color: _statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_outline,
                  size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(userName,
                  style: TextStyle(color: AC.textSec(context), fontSize: 12)),
              if (_formatDate().isNotEmpty) ...[
                const Spacer(),
                const Icon(Icons.calendar_today_outlined,
                    size: 12, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(_formatDate(),
                    style:
                        TextStyle(color: AC.textSec(context), fontSize: 11)),
              ],
            ],
          ),
          if (message != null && message.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: AC.input(context),
                  borderRadius: BorderRadius.circular(10)),
              child: Text(message,
                  style: TextStyle(color: AC.text(context), fontSize: 12),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis),
            ),
          ],
          if (adminNote != null && adminNote.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.admin_panel_settings_outlined,
                    size: 13, color: Colors.blue),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('Admin note: $adminNote',
                      style: const TextStyle(color: Colors.blue, fontSize: 12)),
                ),
              ],
            ),
          ],
          if (isOpen) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_status == 'open')
                  _actionBtn(
                    context,
                    'Mark In Progress',
                    Colors.orange,
                    () => _updateStatus(context, 'in_progress'),
                  ),
                const SizedBox(width: 8),
                _actionBtn(
                  context,
                  'Resolve',
                  Colors.green,
                  () => _resolveWithNote(context),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, String status) async {
    final ok = await context
        .read<AdminProvider>()
        .updateTicketStatus(ticket['id'] as String, status);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Ticket updated' : 'Failed to update ticket'),
          backgroundColor: ok ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _resolveWithNote(BuildContext context) async {
    final noteCtrl = TextEditingController();
    String? captured;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resolve Ticket'),
        content: TextField(
          controller: noteCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Admin note (optional)',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              captured = noteCtrl.text.trim();
              Navigator.pop(ctx);
            },
            child: const Text('Resolve'),
          ),
        ],
      ),
    );

    noteCtrl.dispose();
    if (!context.mounted) return;

    final ok = await context.read<AdminProvider>().updateTicketStatus(
          ticket['id'] as String,
          'resolved',
          adminNote: captured?.isNotEmpty == true ? captured : null,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Ticket resolved' : 'Failed to resolve'),
          backgroundColor: ok ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Widget _actionBtn(
          BuildContext context, String label, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20)),
          child: Text(label,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      );
}
