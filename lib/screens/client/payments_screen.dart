import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../config/flavor_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../models/job_model.dart';
import 'package:intl/intl.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().currentUserId;
      if (uid != null) context.read<JobProvider>().fetchClientPayments(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = FlavorConfig.instance.primaryColor;
    return Scaffold(
      backgroundColor: AC.bg(context),
      appBar: AppBar(backgroundColor: AC.bg(context), title: const Text('Payments')),
      body: Consumer<JobProvider>(
        builder: (context, jobs, _) {
          if (jobs.isJobsLoading && jobs.paymentList.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final payments = jobs.paymentList;
          final totalPaid = payments.fold(0.0, (s, j) => s + j.budget);
          final completed = payments.length;

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
                      const Text('Total Spent', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      const SizedBox(height: 6),
                      Text(
                        'KES ${totalPaid.toStringAsFixed(0)}',
                        style: TextStyle(color: AC.text(context), fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _stat(context, '$completed', 'Transactions', accent),
                          const SizedBox(width: 12),
                          _stat(context, '$completed', 'Completed', accent),
                          const SizedBox(width: 12),
                          _stat(context, '0', 'Pending', accent),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Transaction History', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
                ),
              ),

              Expanded(
                child: payments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.textSecondary),
                            const SizedBox(height: 12),
                            Text('No payments yet', style: TextStyle(color: AC.textSec(context), fontSize: 16)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: payments.length,
                        itemBuilder: (context, i) {
                          final job = payments[i];
                          return _PaymentTile(job: job, accent: accent);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _stat(BuildContext ctx, String value, String label, Color accent) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: AC.input(ctx), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: accent, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: AC.textSec(ctx), fontSize: 11)),
        ],
      ),
    ),
  );
}

class _PaymentTile extends StatelessWidget {
  final Job job;
  final Color accent;
  const _PaymentTile({required this.job, required this.accent});

  IconData get _icon {
    switch (job.category.toLowerCase()) {
      case 'plumbing': return Icons.plumbing;
      case 'electrical': return Icons.electrical_services;
      case 'painting': return Icons.format_paint;
      case 'cleaning': return Icons.cleaning_services;
      case 'carpentry': return Icons.carpenter;
      case 'gardening': return Icons.grass;
      default: return Icons.home_repair_service;
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('MMM d, yyyy').format(job.createdAt);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AC.surface(context), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(_icon, color: accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(job.title, style: TextStyle(color: AC.text(context), fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 3),
                Text(date, style: TextStyle(color: AC.textSec(context), fontSize: 12)),
                if (job.fundiName != null) ...[
                  const SizedBox(height: 2),
                  Text('By ${job.fundiName}', style: TextStyle(color: AC.textSec(context), fontSize: 11)),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('KES ${job.budget.toStringAsFixed(0)}', style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                child: const Text('Paid', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
