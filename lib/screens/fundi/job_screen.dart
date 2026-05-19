import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../models/job_model.dart';
import 'job_details_screen.dart';

class FundiJobsScreen extends StatefulWidget {
  const FundiJobsScreen({super.key});

  @override
  State<FundiJobsScreen> createState() => _FundiJobsScreenState();
}

class _FundiJobsScreenState extends State<FundiJobsScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().currentUserId ?? '';
      context.read<JobProvider>().fetchMyJobs(refresh: true, userId: uid);
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Jobs'),
        bottom: TabBar(
          controller: _tab,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [Tab(text: 'Active'), Tab(text: 'Completed')],
        ),
      ),
      body: Consumer<JobProvider>(
        builder: (context, jobs, _) {
          if (jobs.isJobsLoading) return const Center(child: CircularProgressIndicator());
          final active = jobs.myJobsList.where((j) => j.status != JobStatus.completed && j.status != JobStatus.cancelled).toList();
          final done = jobs.myJobsList.where((j) => j.status == JobStatus.completed || j.status == JobStatus.cancelled).toList();
          return TabBarView(
            controller: _tab,
            children: [
              _FundiJobList(jobs: active, emptyMessage: 'No active jobs.'),
              _FundiJobList(jobs: done, emptyMessage: 'No completed jobs yet.'),
            ],
          );
        },
      ),
    );
  }
}

class _FundiJobList extends StatelessWidget {
  final List<Job> jobs;
  final String emptyMessage;
  const _FundiJobList({required this.jobs, required this.emptyMessage});

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) {
      return Center(child: Text(emptyMessage, style: TextStyle(color: Colors.grey[600])));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: jobs.length,
      itemBuilder: (context, i) => _FundiJobCard(job: jobs[i]),
    );
  }
}

class _FundiJobCard extends StatelessWidget {
  final Job job;
  const _FundiJobCard({required this.job});

  Color get _statusColor {
    switch (job.status) {
      case JobStatus.pending: return Colors.orange;
      case JobStatus.accepted: return Colors.blue;
      case JobStatus.inProgress: return Colors.green;
      case JobStatus.completed: return Colors.grey;
      case JobStatus.cancelled: return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FundiJobDetailsScreen(jobId: job.id))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(job.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: _statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                    child: Text(job.statusText, style: TextStyle(color: _statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (job.clientName != null)
                Row(children: [
                  Icon(Icons.person_outline, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text('Client: ${job.clientName}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  if (job.clientRating != null) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.star, size: 12, color: Colors.amber),
                    Text(' ${job.clientRating!.toStringAsFixed(1)}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ]),
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(job.location, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ]),
              const SizedBox(height: 8),
              Text('KES ${(job.fundiEarnings ?? job.budget * 0.9).toStringAsFixed(0)}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }
}
