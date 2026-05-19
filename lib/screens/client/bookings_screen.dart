import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../config/flavor_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../models/job_model.dart';
import 'booking_details.dart';

class ClientBookingsScreen extends StatefulWidget {
  const ClientBookingsScreen({super.key});

  @override
  State<ClientBookingsScreen> createState() => _ClientBookingsScreenState();
}

class _ClientBookingsScreenState extends State<ClientBookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().currentUserId;
      if (uid != null) context.read<JobProvider>().fetchMyJobs(refresh: true, userId: uid);
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = FlavorConfig.instance.primaryColor;
    return Scaffold(
      backgroundColor: AC.bg(context),
      appBar: AppBar(
        backgroundColor: AC.bg(context),
        title: const Text('My Bookings'),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: accent,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: accent,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          tabs: const [Tab(text: 'Active'), Tab(text: 'History')],
        ),
      ),
      body: Consumer<JobProvider>(
        builder: (context, jobs, _) {
          if (jobs.isJobsLoading) return const Center(child: CircularProgressIndicator());
          final active = jobs.myJobsList.where((j) => j.status != JobStatus.completed && j.status != JobStatus.cancelled).toList();
          final history = jobs.myJobsList.where((j) => j.status == JobStatus.completed || j.status == JobStatus.cancelled).toList();
          return TabBarView(
            controller: _tab,
            children: [
              _BookingList(jobs: active, emptyMessage: 'No active bookings'),
              _BookingList(jobs: history, emptyMessage: 'No past bookings'),
            ],
          );
        },
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  final List<Job> jobs;
  final String emptyMessage;
  const _BookingList({required this.jobs, required this.emptyMessage});

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(emptyMessage, style: TextStyle(color: AC.textSec(context), fontSize: 16)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: jobs.length,
      itemBuilder: (context, i) => _BookingCard(job: jobs[i]),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Job job;
  const _BookingCard({required this.job});

  Color get _statusColor {
    switch (job.status) {
      case JobStatus.pending: return Colors.orange;
      case JobStatus.accepted: return Colors.blue;
      case JobStatus.inProgress: return Colors.green;
      case JobStatus.completed: return AppColors.textSecondary;
      case JobStatus.cancelled: return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = FlavorConfig.instance.primaryColor;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookingDetailsScreen(jobId: job.id))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AC.surface(context), borderRadius: BorderRadius.circular(18)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.home_repair_service, color: accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(job.title, style: TextStyle(color: AC.text(context), fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 3),
                      Text(job.category, style: TextStyle(color: AC.textSec(context), fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: _statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                  child: Text(job.statusText, style: TextStyle(color: _statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: AC.div(context), height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(job.location, style: TextStyle(color: AC.textSec(context), fontSize: 12)),
                ]),
                Text('KES ${job.budget.toStringAsFixed(0)}', style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 15)),
              ],
            ),
            if (job.fundiName != null) ...[
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(job.fundiName!, style: TextStyle(color: AC.textSec(context), fontSize: 12)),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}
