import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/job_model.dart';
import 'navigate_screen.dart';
import 'payment_request_screen.dart';
import '../sharedscreens/chat_screen.dart';

class FundiJobDetailsScreen extends StatefulWidget {
  final String jobId;
  const FundiJobDetailsScreen({super.key, required this.jobId});

  @override
  State<FundiJobDetailsScreen> createState() => _FundiJobDetailsScreenState();
}

class _FundiJobDetailsScreenState extends State<FundiJobDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JobProvider>().getJobDetails(widget.jobId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<JobProvider>(
      builder: (context, jobs, _) {
        final job = jobs.selectedJob ?? jobs.getJob(widget.jobId);
        if (jobs.isJobsLoading && job == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (job == null) {
          return Scaffold(appBar: AppBar(title: const Text('Job Details')), body: const Center(child: Text('Job not found')));
        }
        return _JobDetailView(job: job);
      },
    );
  }
}

class _JobDetailView extends StatelessWidget {
  final Job job;
  const _JobDetailView({required this.job});

  @override
  Widget build(BuildContext context) {
    final jobs = context.read<JobProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Job Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _row(Icons.build, 'Category', job.category),
                    _row(Icons.location_on, 'Location', job.location),
                    _row(Icons.attach_money, 'Budget', 'KES ${job.budget.toStringAsFixed(0)}'),
                    _row(Icons.account_balance_wallet, 'Your Earnings',
                        'KES ${(job.fundiEarnings ?? job.budget * 0.9).toStringAsFixed(0)}'),
                    if (job.clientName != null) _row(Icons.person, 'Client', job.clientName!),
                    if (job.clientRating != null) _row(Icons.star, 'Client Rating', job.clientRating!.toStringAsFixed(1)),
                    const Divider(height: 24),
                    const Text('Description', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text(job.description, style: TextStyle(color: Colors.grey[700])),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (job.status == JobStatus.pending) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final auth = context.read<AuthProvider>();
                    final ok = await jobs.applyForJob(
                      job.id,
                      fundiId: auth.currentUserId ?? '',
                      fundiName: auth.userName ?? 'Fundi',
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(ok ? 'Application sent!' : 'Failed to apply.')),
                      );
                      if (ok) Navigator.pop(context);
                    }
                  },
                  child: const Text('Apply for this Job'),
                ),
              ),
            ] else if (job.status == JobStatus.accepted || job.status == JobStatus.inProgress) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.navigation),
                  label: const Text('Navigate to Client'),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NavigateScreen(job: job))),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Chat with Client'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        jobId: job.id,
                        jobTitle: job.title,
                        otherPartyName: job.clientName ?? 'Client',
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    await jobs.updateJobStatus(job.id, JobStatus.completed);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Mark as Complete'),
                ),
              ),
              const SizedBox(height: 12),
              _PaymentButton(job: job),
            ] else if (job.status == JobStatus.completed) ...[
              _PaymentButton(job: job),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(icon, size: 18, color: Colors.grey[500]),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
        Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
      ]),
    );
  }
}

class _PaymentButton extends StatelessWidget {
  final Job job;
  const _PaymentButton({required this.job});

  @override
  Widget build(BuildContext context) {
    final isPaid = job.paymentStatus == 'paid';
    final isPending = job.paymentStatus == 'pending';

    if (isPaid) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.4)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50), size: 18),
            SizedBox(width: 8),
            Text('Payment Received via M-Pesa',
                style: TextStyle(
                    color: Color(0xFF4CAF50), fontWeight: FontWeight.w700)),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(isPending ? Icons.hourglass_top_rounded : Icons.phone_android,
            size: 18),
        label: Text(
          isPending ? 'Payment Pending…' : 'Request M-Pesa Payment',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        onPressed: isPending
            ? null
            : () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentRequestScreen(job: job),
                  ),
                ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
