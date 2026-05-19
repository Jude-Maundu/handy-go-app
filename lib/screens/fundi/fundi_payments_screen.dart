import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../config/flavor_config.dart';
import '../../models/job_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import 'payment_request_screen.dart';

class FundiPaymentsScreen extends StatefulWidget {
  const FundiPaymentsScreen({super.key});

  @override
  State<FundiPaymentsScreen> createState() => _FundiPaymentsScreenState();
}

class _FundiPaymentsScreenState extends State<FundiPaymentsScreen> {
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().currentUserId;
      if (uid != null) {
        context.read<JobProvider>().fetchMyJobs(refresh: true, userId: uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = FlavorConfig.instance.primaryColor;

    return Scaffold(
      backgroundColor: AC.bg(context),
      appBar: AppBar(
        backgroundColor: AC.bg(context),
        title: const Text('Payments'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.phone_android),
        label: const Text('Test Payment', style: TextStyle(fontWeight: FontWeight.w700)),
        onPressed: () {
          final testJob = Job(
            id: 'test-job',
            title: 'Test Job',
            category: 'Plumbing',
            budget: 500,
            location: 'Nairobi',
            description: 'Test payment prompt',
            createdAt: DateTime.now(),
            status: JobStatus.accepted,
            paymentStatus: 'none',
          );
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PaymentRequestScreen(job: testJob)),
          );
        },
      ),
      body: Consumer<JobProvider>(
        builder: (context, jobs, _) {
          if (jobs.isJobsLoading && jobs.myJobsList.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final allJobs = jobs.myJobsList
              .where((j) =>
                  j.status == JobStatus.accepted ||
                  j.status == JobStatus.inProgress ||
                  j.status == JobStatus.completed)
              .toList();

          final totalPaid = allJobs
              .where((j) => j.paymentStatus == 'paid')
              .fold(0.0, (s, j) => s + j.budget);
          final totalPending = allJobs
              .where((j) => j.paymentStatus == 'pending')
              .fold(0.0, (s, j) => s + j.budget);

          final filtered = _filter == 'Paid'
              ? allJobs.where((j) => j.paymentStatus == 'paid').toList()
              : _filter == 'Pending'
                  ? allJobs.where((j) => j.paymentStatus == 'pending').toList()
                  : _filter == 'Unpaid'
                      ? allJobs
                          .where((j) =>
                              j.paymentStatus == 'none' ||
                              j.paymentStatus == 'failed')
                          .toList()
                      : allJobs;

          return Column(
            children: [
              // Stats row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Row(
                  children: [
                    _StatCard(
                      label: 'Total Received',
                      value: 'KES ${totalPaid.toStringAsFixed(0)}',
                      color: Colors.green,
                      icon: Icons.check_circle_outline,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      label: 'Awaiting Payment',
                      value: 'KES ${totalPending.toStringAsFixed(0)}',
                      color: Colors.orange,
                      icon: Icons.hourglass_empty_outlined,
                    ),
                  ],
                ),
              ),

              // Filter chips
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: ['All', 'Paid', 'Pending', 'Unpaid'].map((f) {
                    final selected = _filter == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(f),
                        selected: selected,
                        onSelected: (_) => setState(() => _filter = f),
                        selectedColor: accent,
                        labelStyle: TextStyle(
                          color: selected ? Colors.black : AC.text(context),
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.normal,
                          fontSize: 13,
                        ),
                        backgroundColor: AC.input(context),
                        side: BorderSide.none,
                        showCheckmark: false,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),

              // List
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.payment_outlined,
                                size: 64, color: AC.textSec(context)),
                            const SizedBox(height: 12),
                            Text(
                              'No payments here',
                              style: TextStyle(
                                  color: AC.textSec(context), fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Accept jobs to start receiving payments',
                              style: TextStyle(
                                  color: AC.textSec(context), fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          final uid = context
                              .read<AuthProvider>()
                              .currentUserId;
                          if (uid != null) {
                            await context
                                .read<JobProvider>()
                                .fetchMyJobs(refresh: true, userId: uid);
                          }
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filtered.length,
                          itemBuilder: (context, i) =>
                              _PaymentTile(job: filtered[i], accent: accent),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AC.surface(context),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: TextStyle(
                          color: AC.text(context),
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  const SizedBox(height: 1),
                  Text(label,
                      style: TextStyle(
                          color: AC.textSec(context), fontSize: 10),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final Job job;
  final Color accent;
  const _PaymentTile({required this.job, required this.accent});

  @override
  Widget build(BuildContext context) {
    final isPaid = job.paymentStatus == 'paid';
    final isPending = job.paymentStatus == 'pending';
    final isFailed = job.paymentStatus == 'failed';
    final date = DateFormat('MMM d, yyyy').format(job.createdAt);

    final badgeColor = isPaid
        ? Colors.green
        : isPending
            ? Colors.orange
            : isFailed
                ? Colors.red
                : AC.textSec(context);
    final badgeText = isPaid
        ? 'Paid'
        : isPending
            ? 'Pending'
            : isFailed
                ? 'Failed'
                : 'Not Requested';

    final canRequest = !isPaid &&
        !isPending &&
        (job.status == JobStatus.accepted ||
            job.status == JobStatus.inProgress ||
            job.status == JobStatus.completed);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AC.surface(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.handyman_outlined, color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job.title,
                        style: TextStyle(
                            color: AC.text(context),
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(job.clientName ?? 'Client',
                        style: TextStyle(
                            color: AC.textSec(context), fontSize: 12)),
                    Text(date,
                        style: TextStyle(
                            color: AC.textSec(context), fontSize: 11)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'KES ${job.budget.toStringAsFixed(0)}',
                    style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w800,
                        fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                          color: badgeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (canRequest) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentRequestScreen(job: job),
                  ),
                ),
                icon: const Icon(Icons.phone_android, size: 16),
                label: const Text('Request M-Pesa Payment',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ),
          ],

          if (isPaid) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 14),
                const SizedBox(width: 4),
                Text(
                  'Payment received via M-Pesa',
                  style: TextStyle(color: Colors.green.shade600, fontSize: 11),
                ),
              ],
            ),
          ],

          if (isPending) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.hourglass_empty,
                    color: Colors.orange, size: 14),
                const SizedBox(width: 4),
                Text(
                  'Waiting for client to complete payment...',
                  style:
                      TextStyle(color: Colors.orange.shade700, fontSize: 11),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
