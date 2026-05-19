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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchAllJobs();
    });
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
            onPressed: () => context.read<AdminProvider>().fetchAllJobs(statusFilter: _selected == 'All' ? null : _selected),
          ),
        ],
      ),
      body: Column(
        children: [
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
                    context.read<AdminProvider>().fetchAllJobs(statusFilter: f == 'All' ? null : f);
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
              if (admin.allJobs.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Text('${admin.allJobs.length} jobs', style: TextStyle(color: AC.textSec(context), fontSize: 12)),
                    const Spacer(),
                    _chip('Pending', admin.allJobs.where((j) => j.status == JobStatus.pending).length, Colors.orange),
                    const SizedBox(width: 6),
                    _chip('Active', admin.allJobs.where((j) => j.status == JobStatus.accepted || j.status == JobStatus.inProgress).length, Colors.blue),
                    const SizedBox(width: 6),
                    _chip('Done', admin.allJobs.where((j) => j.status == JobStatus.completed).length, Colors.green),
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
                if (admin.allJobs.isEmpty) {
                  return Center(child: Text('No jobs found', style: TextStyle(color: AC.textSec(context))));
                }
                return RefreshIndicator(
                  onRefresh: () => admin.fetchAllJobs(statusFilter: _selected == 'All' ? null : _selected),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: admin.allJobs.length,
                    itemBuilder: (context, i) => _AdminJobCard(job: admin.allJobs[i]),
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
      case 'pending': return 'Pending';
      case 'accepted': return 'Accepted';
      case 'inProgress': return 'In Progress';
      case 'completed': return 'Completed';
      case 'cancelled': return 'Cancelled';
      default: return status;
    }
  }

  Widget _chip(String label, int count, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
    child: Text('$label: $count', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
  );
}

class _AdminJobCard extends StatelessWidget {
  final Job job;
  const _AdminJobCard({required this.job});

  Color get _statusColor {
    switch (job.status) {
      case JobStatus.pending: return Colors.orange;
      case JobStatus.accepted: return Colors.blue;
      case JobStatus.inProgress: return Colors.teal;
      case JobStatus.completed: return Colors.green;
      case JobStatus.cancelled: return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('MMM d, y').format(job.createdAt);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AC.surface(context), borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(job.title, style: TextStyle(color: AC.text(context), fontWeight: FontWeight.w700, fontSize: 14)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                child: Text(job.statusText, style: TextStyle(color: _statusColor, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            children: [
              _row(Icons.build_circle_outlined, job.category, context),
              _row(Icons.location_on_outlined, job.location, context),
              _row(Icons.calendar_today_outlined, date, context),
              _row(Icons.attach_money, 'KES ${job.budget.toStringAsFixed(0)}', context),
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
                  Text('Client: ${job.clientName}', style: TextStyle(color: AC.textSec(context), fontSize: 12)),
                  const SizedBox(width: 16),
                ],
                if (job.fundiName != null) ...[
                  const Icon(Icons.build_outlined, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text('Fundi: ${job.fundiName}', style: TextStyle(color: AC.textSec(context), fontSize: 12)),
                ],
              ],
            ),
          ],
          // Admin actions
          if (job.status == JobStatus.pending || job.status == JobStatus.inProgress) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (job.status == JobStatus.pending)
                  _actionBtn(context, 'Cancel', Colors.red, () => _updateStatus(context, job.id, 'cancelled')),
                if (job.status == JobStatus.inProgress) ...[
                  _actionBtn(context, 'Complete', Colors.green, () => _updateStatus(context, job.id, 'completed')),
                  const SizedBox(width: 8),
                  _actionBtn(context, 'Cancel', Colors.red, () => _updateStatus(context, job.id, 'cancelled')),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, String jobId, String status) async {
    final ok = await context.read<AdminProvider>().adminUpdateJobStatus(jobId, status);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Job updated' : 'Failed to update'), backgroundColor: ok ? Colors.green : Colors.red),
      );
    }
  }

  Widget _row(IconData icon, String text, BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: AppColors.textSecondary),
      const SizedBox(width: 4),
      Text(text, style: TextStyle(color: AC.textSec(context), fontSize: 12)),
    ],
  );

  Widget _actionBtn(BuildContext context, String label, Color color, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
    ),
  );
}
