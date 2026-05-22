import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../models/job_model.dart';
import '../../providers/admin_provider.dart';

class AdminJobsScreen extends StatefulWidget {
  const AdminJobsScreen({super.key});

  @override
  State<AdminJobsScreen> createState() => _AdminJobsScreenState();
}

class _AdminJobsScreenState extends State<AdminJobsScreen> {
  static const _filters = ['All', 'pending', 'accepted', 'inProgress', 'completed', 'cancelled'];
  String _selected = 'All';
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchAllJobs();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Job> _filtered(List<Job> jobs) {
    if (_query.isEmpty) return jobs;
    final q = _query.toLowerCase();
    return jobs
        .where((j) =>
            j.title.toLowerCase().contains(q) ||
            j.category.toLowerCase().contains(q) ||
            j.location.toLowerCase().contains(q) ||
            (j.clientName?.toLowerCase().contains(q) ?? false) ||
            (j.fundiName?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AC.bg(context),
      appBar: AppBar(
        backgroundColor: AC.bg(context),
        title: const Text('All Jobs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context
                .read<AdminProvider>()
                .fetchAllJobs(statusFilter: _selected == 'All' ? null : _selected),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration:
                  BoxDecoration(color: AC.input(context), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.search, color: AppColors.textSecondary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _query = v.toLowerCase()),
                      style: TextStyle(color: AC.text(context), fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Search jobs, clients, fundis...',
                        hintStyle: TextStyle(color: AppColors.textSecondary),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  if (_query.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                      child: const Icon(Icons.close, color: AppColors.textSecondary, size: 16),
                    ),
                ],
              ),
            ),
          ),

          // Status filter chips
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final f = _filters[i];
                final active = _selected == f;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selected = f);
                    context
                        .read<AdminProvider>()
                        .fetchAllJobs(statusFilter: f == 'All' ? null : f);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: active ? Colors.blue : AC.surface(context),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      f == 'All' ? 'All' : _label(f),
                      style: TextStyle(
                        color: active ? Colors.white : AC.textSec(context),
                        fontSize: 12,
                        fontWeight: active ? FontWeight.w700 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Summary bar
          Consumer<AdminProvider>(
            builder: (context, admin, _) {
              final jobs = _filtered(admin.allJobs);
              if (admin.allJobs.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Text('${jobs.length} jobs',
                        style: TextStyle(color: AC.textSec(context), fontSize: 12)),
                    const Spacer(),
                    _chip('Pending',
                        jobs.where((j) => j.status == JobStatus.pending).length, Colors.orange),
                    const SizedBox(width: 6),
                    _chip(
                        'Active',
                        jobs
                            .where((j) =>
                                j.status == JobStatus.accepted ||
                                j.status == JobStatus.inProgress)
                            .length,
                        Colors.blue),
                    const SizedBox(width: 6),
                    _chip('Done', jobs.where((j) => j.status == JobStatus.completed).length,
                        Colors.green),
                  ],
                ),
              );
            },
          ),

          // Job list
          Expanded(
            child: Consumer<AdminProvider>(
              builder: (context, admin, _) {
                if (admin.isLoading) return const Center(child: CircularProgressIndicator());
                final jobs = _filtered(admin.allJobs);
                if (jobs.isEmpty) {
                  return Center(
                    child: Text(
                      _query.isNotEmpty ? 'No results for "$_query"' : 'No jobs found',
                      style: TextStyle(color: AC.textSec(context)),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => admin.fetchAllJobs(
                      statusFilter: _selected == 'All' ? null : _selected),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: jobs.length,
                    itemBuilder: (context, i) => _AdminJobCard(job: jobs[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _label(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'inProgress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  Widget _chip(String label, int count, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
        child: Text('$label: $count',
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      );
}

// ── Job card ──────────────────────────────────────────────────────────────────

class _AdminJobCard extends StatelessWidget {
  final Job job;
  const _AdminJobCard({required this.job});

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
    final date = DateFormat('MMM d, y').format(job.createdAt);
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration:
            BoxDecoration(color: AC.surface(context), borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(job.title,
                      style: TextStyle(
                          color: AC.text(context), fontWeight: FontWeight.w700, fontSize: 14)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(job.statusText,
                      style: TextStyle(
                          color: _statusColor, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                _row(Icons.build_circle_outlined, job.category, context),
                _row(Icons.location_on_outlined, job.location, context),
                _row(Icons.calendar_today_outlined, date, context),
                _row(Icons.attach_money, 'KES ${job.budget.toStringAsFixed(0)}', context),
                if (job.paymentStatus == 'paid')
                  _row(Icons.check_circle_outline, 'Paid', context, color: Colors.green),
              ],
            ),
            if (job.clientName != null || job.fundiName != null) ...[
              const SizedBox(height: 8),
              Divider(color: AC.div(context), height: 1),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (job.clientName != null) ...[
                    const Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text('${job.clientName}',
                        style: TextStyle(color: AC.textSec(context), fontSize: 12)),
                    const SizedBox(width: 16),
                  ],
                  if (job.fundiName != null) ...[
                    const Icon(Icons.build_outlined, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text('${job.fundiName}',
                        style: TextStyle(color: AC.textSec(context), fontSize: 12)),
                  ],
                ],
              ),
            ],
            // Admin actions
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (job.status != JobStatus.completed && job.status != JobStatus.cancelled) ...[
                  if (job.status == JobStatus.inProgress || job.status == JobStatus.accepted)
                    _actionBtn(context, 'Complete', Colors.green,
                        () => _updateStatus(context, 'completed')),
                  if (job.status != JobStatus.cancelled) ...[
                    const SizedBox(width: 8),
                    _actionBtn(context, 'Cancel', Colors.orange,
                        () => _updateStatus(context, 'cancelled')),
                  ],
                  const SizedBox(width: 8),
                ],
                _actionBtn(context, 'Delete', Colors.red, () => _confirmDelete(context),
                    icon: Icons.delete_outline),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, String status) async {
    final ok = await context.read<AdminProvider>().adminUpdateJobStatus(job.id, status);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Job updated to $status' : 'Failed to update'),
          backgroundColor: ok ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Job'),
        content: Text('Permanently delete "${job.title}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    final ok = await context.read<AdminProvider>().deleteJob(job.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Job deleted' : 'Failed to delete'),
          backgroundColor: ok ? Colors.red : Colors.grey,
        ),
      );
    }
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _JobDetailSheet(job: job),
    );
  }

  Widget _row(IconData icon, String text, BuildContext context, {Color? color}) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color ?? AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(color: color ?? AC.textSec(context), fontSize: 12)),
        ],
      );

  Widget _actionBtn(BuildContext context, String label, Color color, VoidCallback onTap,
          {IconData? icon}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration:
              BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 13, color: color), const SizedBox(width: 4)],
              Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      );
}

// ── Job detail bottom sheet ───────────────────────────────────────────────────

class _JobDetailSheet extends StatelessWidget {
  final Job job;
  const _JobDetailSheet({required this.job});

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
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      expand: false,
      builder: (_, ctrl) => ListView(
        controller: ctrl,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration:
                  BoxDecoration(color: AC.div(context), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(job.title,
                    style: TextStyle(
                        color: AC.text(context), fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(job.statusText,
                    style:
                        TextStyle(color: _statusColor, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _detail(context, 'Category', job.category, Icons.category_outlined),
          _detail(context, 'Location', job.location, Icons.location_on_outlined),
          _detail(context, 'Budget', 'KES ${job.budget.toStringAsFixed(0)}', Icons.attach_money),
          _detail(context, 'Payment', job.paymentStatus, Icons.payments_outlined,
              valueColor: job.paymentStatus == 'paid' ? Colors.green : null),
          _detail(context, 'Date', DateFormat('MMM d, y HH:mm').format(job.createdAt),
              Icons.calendar_today_outlined),
          if (job.clientName != null)
            _detail(context, 'Client', job.clientName!, Icons.person_outline),
          if (job.clientPhone != null)
            _detail(context, 'Client Phone', job.clientPhone!, Icons.phone_outlined),
          if (job.fundiName != null)
            _detail(context, 'Fundi', job.fundiName!, Icons.build_outlined),
          if (job.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Description',
                style: TextStyle(
                    color: AC.textSec(context), fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(job.description, style: TextStyle(color: AC.text(context), fontSize: 14)),
          ],
          if (job.workItems.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Work Items',
                style: TextStyle(
                    color: AC.textSec(context), fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...job.workItems.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 15, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(item['name'] as String? ?? '',
                              style: TextStyle(color: AC.text(context), fontSize: 13))),
                      Text('KES ${(item['amount'] as num?)?.toStringAsFixed(0) ?? '0'}',
                          style: TextStyle(
                              color: AC.textSec(context),
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _detail(BuildContext context, String label, String value, IconData icon,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Text('$label: ',
              style: TextStyle(color: AC.textSec(context), fontSize: 13)),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    color: valueColor ?? AC.text(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
