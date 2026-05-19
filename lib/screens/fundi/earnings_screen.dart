import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../config/flavor_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../models/job_model.dart';
import 'withdrawal_screen.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().currentUserId;
      if (uid != null) context.read<JobProvider>().fetchFundiEarnings(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = FlavorConfig.instance.primaryColor;

    return Scaffold(
      backgroundColor: AC.bg(context),
      appBar: AppBar(backgroundColor: AC.bg(context), title: const Text('Earnings')),
      body: Consumer<JobProvider>(
        builder: (context, jobs, _) {
          if (jobs.isJobsLoading && jobs.paymentList.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final completedJobs = jobs.paymentList;
          final totalEarned = completedJobs.fold(0.0, (s, j) => s + (j.fundiEarnings ?? j.budget * 0.9));
          final thisMonth = _thisMonthEarnings(completedJobs);
          final avgRating = _avgRating(completedJobs);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: AC.surface(context), borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Available Balance', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      const SizedBox(height: 6),
                      Text(
                        'KES ${totalEarned.toStringAsFixed(0)}',
                        style: TextStyle(color: AC.text(context), fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _stat(context, 'KES ${thisMonth.toStringAsFixed(0)}', 'This Month', accent),
                          const SizedBox(width: 12),
                          _stat(context, '${completedJobs.length}', 'Jobs Done', accent),
                          const SizedBox(width: 12),
                          _stat(context, avgRating > 0 ? '${avgRating.toStringAsFixed(1)} ⭐' : '—', 'Rating', accent),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WithdrawalScreen())),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Withdraw', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Recent Transactions', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
                ),
              ),

              Expanded(
                child: completedJobs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.account_balance_wallet_outlined, size: 64, color: AppColors.textSecondary),
                            const SizedBox(height: 12),
                            Text('No completed jobs yet', style: TextStyle(color: AC.textSec(context), fontSize: 16)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: completedJobs.length,
                        itemBuilder: (context, i) => _EarningTile(job: completedJobs[i], accent: accent),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  double _thisMonthEarnings(List<Job> jobs) {
    final now = DateTime.now();
    return jobs
        .where((j) => j.createdAt.year == now.year && j.createdAt.month == now.month)
        .fold(0.0, (s, j) => s + (j.fundiEarnings ?? j.budget * 0.9));
  }

  double _avgRating(List<Job> jobs) {
    final rated = jobs.where((j) => j.fundiRating != null).toList();
    if (rated.isEmpty) return 0.0;
    return rated.fold(0.0, (s, j) => s + j.fundiRating!) / rated.length;
  }

  Widget _stat(BuildContext ctx, String value, String label, Color accent) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: AC.input(ctx), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: accent, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: AC.textSec(ctx), fontSize: 11)),
        ],
      ),
    ),
  );
}

class _EarningTile extends StatelessWidget {
  final Job job;
  final Color accent;
  const _EarningTile({required this.job, required this.accent});

  @override
  Widget build(BuildContext context) {
    final amount = job.fundiEarnings ?? job.budget * 0.9;
    final date = DateFormat('MMM d, yyyy').format(job.createdAt);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AC.surface(context), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.arrow_downward_rounded, color: Colors.green, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(job.title, style: TextStyle(color: AC.text(context), fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 3),
                Text(date, style: TextStyle(color: AC.textSec(context), fontSize: 12)),
                if (job.clientName != null) ...[
                  const SizedBox(height: 2),
                  Text('Client: ${job.clientName}', style: TextStyle(color: AC.textSec(context), fontSize: 11)),
                ],
              ],
            ),
          ),
          Text(
            '+KES ${amount.toStringAsFixed(0)}',
            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
