import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../constants/app_colors.dart';
import '../../models/job_model.dart';
import '../../providers/admin_provider.dart';

class AdminFinanceScreen extends StatefulWidget {
  const AdminFinanceScreen({super.key});

  @override
  State<AdminFinanceScreen> createState() => _AdminFinanceScreenState();
}

class _AdminFinanceScreenState extends State<AdminFinanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final admin = context.read<AdminProvider>();
      admin.fetchAllTransactions();
      admin.computePayouts();
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
      backgroundColor: AC.bg(context),
      appBar: AppBar(
        backgroundColor: AC.bg(context),
        title: const Text('Finance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AdminProvider>().fetchAllTransactions();
              context.read<AdminProvider>().computePayouts();
            },
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Export CSV',
            onPressed: () => _exportCsv(context),
          ),
          IconButton(
            icon: const Icon(Icons.campaign_outlined),
            tooltip: 'Broadcast Notification',
            onPressed: () => _showBroadcastDialog(context),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.blue,
          labelColor: Colors.blue,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Transactions'),
            Tab(text: 'Payouts'),
            Tab(text: 'Reviews'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [_TransactionsTab(), _PayoutsTab(), _ReviewsTab()],
      ),
    );
  }

  Future<void> _exportCsv(BuildContext context) async {
    final admin = context.read<AdminProvider>();
    final jobs = admin.transactions;
    if (jobs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No transactions to export')),
      );
      return;
    }

    final lines = <String>[
      'Date,Title,Category,Client,Fundi,Budget (KES),Platform Fee (KES),Fundi Earnings (KES),Payment Status',
      ...jobs.map((j) {
        final date = DateFormat('yyyy-MM-dd').format(j.createdAt);
        final fee = (j.serviceFee ?? j.budget * 0.10).toStringAsFixed(2);
        final earn = (j.fundiEarnings ?? j.budget * 0.90).toStringAsFixed(2);
        String esc(String? v) => '"${(v ?? '').replaceAll('"', '""')}"';
        return '${esc(date)},${esc(j.title)},${esc(j.category)},${esc(j.clientName)},${esc(j.fundiName)},${j.budget.toStringAsFixed(2)},$fee,$earn,${esc(j.paymentStatus)}';
      }),
    ];

    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/handygo_transactions_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv');
      await file.writeAsString(lines.join('\n'));
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'HandyGo Transactions Export'),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showBroadcastDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    String target = 'client';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Broadcast Notification'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Send to:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              Row(
                children: [
                  _targetChip('Clients', 'client', target, (v) => setS(() => target = v)),
                  const SizedBox(width: 8),
                  _targetChip('Fundis', 'fundi', target, (v) => setS(() => target = v)),
                  const SizedBox(width: 8),
                  _targetChip('All', 'all', target, (v) => setS(() => target = v)),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final t = titleCtrl.text.trim();
                final b = bodyCtrl.text.trim();
                if (t.isEmpty || b.isEmpty) return;
                Navigator.pop(ctx);
                final admin = context.read<AdminProvider>();
                bool ok;
                if (target == 'all') {
                  final r1 = await admin.broadcastNotification('client', t, b);
                  final r2 = await admin.broadcastNotification('fundi', t, b);
                  ok = r1 && r2;
                } else {
                  ok = await admin.broadcastNotification(target, t, b);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok ? 'Notification sent!' : 'Failed to send'),
                      backgroundColor: ok ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _targetChip(String label, String value, String selected, ValueChanged<String> onTap) {
    final active = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? Colors.blue : Colors.transparent,
          border: Border.all(color: active ? Colors.blue : Colors.grey.shade400),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? Colors.white : AppColors.textSecondary, fontSize: 12)),
      ),
    );
  }
}

// ── Transactions tab ──────────────────────────────────────────────────────────

class _TransactionsTab extends StatelessWidget {
  const _TransactionsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        final jobs = admin.transactions;

        if (jobs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.receipt_long_outlined, size: 56, color: AppColors.textSecondary),
                const SizedBox(height: 12),
                Text('No completed transactions yet',
                    style: TextStyle(color: AC.textSec(context), fontSize: 15)),
              ],
            ),
          );
        }

        final totalGMV = jobs.fold(0.0, (s, j) => s + j.budget);
        final totalRevenue =
            jobs.fold(0.0, (s, j) => s + (j.serviceFee ?? j.budget * 0.10));
        final paid = jobs.where((j) => j.paymentStatus == 'paid').length;
        final pending = jobs.where((j) => j.paymentStatus == 'pending').length;
        final failed = jobs.where((j) => j.paymentStatus == 'failed').length;

        return RefreshIndicator(
          onRefresh: () => admin.fetchAllTransactions(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade800, Colors.blue.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Platform Revenue',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 6),
                    Text('KES ${totalRevenue.toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _summaryPill('GMV ${totalGMV.toStringAsFixed(0)}', Colors.white70),
                        const SizedBox(width: 8),
                        _summaryPill('$paid Paid', Colors.green.shade200),
                        const SizedBox(width: 8),
                        _summaryPill('$pending Pending', Colors.orange.shade200),
                        if (failed > 0) ...[
                          const SizedBox(width: 8),
                          _summaryPill('$failed Failed', Colors.red.shade200),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('All Transactions (${jobs.length})',
                  style: TextStyle(
                      color: AC.text(context), fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 10),
              ...jobs.map((j) => _TransactionCard(job: j)),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryPill(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      );
}

class _TransactionCard extends StatelessWidget {
  final Job job;
  const _TransactionCard({required this.job});

  Color get _paymentColor {
    switch (job.paymentStatus) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String get _paymentLabel {
    switch (job.paymentStatus) {
      case 'paid':
        return 'Paid';
      case 'pending':
        return 'Pending';
      case 'failed':
        return 'Failed';
      default:
        return 'Unpaid';
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('MMM d, y').format(job.createdAt);
    final revenue = job.serviceFee ?? job.budget * 0.10;
    final fundiEarnings = job.fundiEarnings ?? job.budget * 0.90;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration:
          BoxDecoration(color: AC.surface(context), borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_outlined, color: Colors.blue, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job.title,
                        style: TextStyle(
                            color: AC.text(context),
                            fontWeight: FontWeight.w700,
                            fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(date, style: TextStyle(color: AC.textSec(context), fontSize: 11)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('KES ${job.budget.toStringAsFixed(0)}',
                      style: TextStyle(
                          color: AC.text(context), fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: _paymentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(_paymentLabel,
                        style: TextStyle(
                            color: _paymentColor, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: AC.div(context)),
          const SizedBox(height: 10),
          Row(
            children: [
              if (job.clientName != null) ...[
                const Icon(Icons.person_outline, size: 12, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(job.clientName!,
                    style: TextStyle(color: AC.textSec(context), fontSize: 11)),
                const SizedBox(width: 12),
              ],
              if (job.fundiName != null) ...[
                const Icon(Icons.build_outlined, size: 12, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(job.fundiName!,
                    style: TextStyle(color: AC.textSec(context), fontSize: 11)),
              ],
              const Spacer(),
              Text('Fee: KES ${revenue.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Text('Fundi: KES ${fundiEarnings.toStringAsFixed(0)}',
                  style:
                      const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Payouts tab ───────────────────────────────────────────────────────────────

class _PayoutsTab extends StatelessWidget {
  const _PayoutsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        final payouts = admin.payouts;

        if (payouts.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_balance_outlined,
                    size: 56, color: AppColors.textSecondary),
                const SizedBox(height: 12),
                Text('No payout data yet',
                    style: TextStyle(color: AC.textSec(context), fontSize: 15)),
              ],
            ),
          );
        }

        final totalPending =
            payouts.fold(0.0, (s, p) => s + (p['pendingEarnings'] as double? ?? 0.0));
        final totalPaid =
            payouts.fold(0.0, (s, p) => s + (p['paidEarnings'] as double? ?? 0.0));

        return RefreshIndicator(
          onRefresh: () => admin.computePayouts(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade800, Colors.green.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Fundi Payouts',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 6),
                    Text('KES ${(totalPaid + totalPending).toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _pill('Paid ${totalPaid.toStringAsFixed(0)}', Colors.white),
                        const SizedBox(width: 8),
                        _pill('Pending ${totalPending.toStringAsFixed(0)}',
                            Colors.orange.shade200),
                        const Spacer(),
                        _pill('${payouts.length} fundis', Colors.white70),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('All Fundis (${payouts.length})',
                  style: TextStyle(
                      color: AC.text(context),
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
              const SizedBox(height: 10),
              ...payouts.map((p) => _PayoutCard(payout: p)),
            ],
          ),
        );
      },
    );
  }

  Widget _pill(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20)),
        child: Text(text,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      );
}

class _PayoutCard extends StatelessWidget {
  final Map<String, dynamic> payout;
  const _PayoutCard({required this.payout});

  @override
  Widget build(BuildContext context) {
    final name = payout['fundiName'] as String? ?? 'Unknown';
    final total = (payout['totalEarnings'] as double?) ?? 0.0;
    final paid = (payout['paidEarnings'] as double?) ?? 0.0;
    final pending = (payout['pendingEarnings'] as double?) ?? 0.0;
    final jobCount = (payout['jobCount'] as int?) ?? 0;
    final paidPct = total > 0 ? paid / total : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration:
          BoxDecoration(color: AC.surface(context), borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase(),
                    style: const TextStyle(
                        color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: TextStyle(
                            color: AC.text(context),
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                    Text('$jobCount completed job${jobCount != 1 ? 's' : ''}',
                        style: TextStyle(color: AC.textSec(context), fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('KES ${total.toStringAsFixed(0)}',
                      style: TextStyle(
                          color: AC.text(context),
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  Text('total earnings',
                      style: TextStyle(color: AC.textSec(context), fontSize: 10)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: paidPct.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: Colors.orange.withValues(alpha: 0.2),
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _badge('Paid: KES ${paid.toStringAsFixed(0)}', Colors.green),
              const SizedBox(width: 8),
              if (pending > 0) _badge('Pending: KES ${pending.toStringAsFixed(0)}', Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
        child: Text(text,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      );
}

// ── Reviews tab ───────────────────────────────────────────────────────────────

class _ReviewsTab extends StatelessWidget {
  const _ReviewsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        final jobs = admin.ratedJobs;

        if (jobs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_outline, size: 56, color: AppColors.textSecondary),
                const SizedBox(height: 12),
                Text('No reviews yet',
                    style: TextStyle(color: AC.textSec(context), fontSize: 15)),
              ],
            ),
          );
        }

        final avgRating = jobs.fold(0.0, (s, j) => s + (j.fundiRating ?? 0.0)) / jobs.length;
        final tips = jobs.fold(0.0, (s, j) {
          final tip = j.toJson()['tipAmount'] as double?;
          return s + (tip ?? 0.0);
        });

        return RefreshIndicator(
          onRefresh: () => admin.fetchAllTransactions(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary
              Row(
                children: [
                  Expanded(
                    child: _ReviewStat(
                        label: 'Avg Rating',
                        value: avgRating.toStringAsFixed(1),
                        icon: Icons.star,
                        color: Colors.amber),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ReviewStat(
                        label: 'Total Reviews',
                        value: '${jobs.length}',
                        icon: Icons.rate_review_outlined,
                        color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ReviewStat(
                        label: 'Tips',
                        value: 'KES ${tips.toStringAsFixed(0)}',
                        icon: Icons.volunteer_activism_outlined,
                        color: Colors.green),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('All Reviews (${jobs.length})',
                  style: TextStyle(
                      color: AC.text(context), fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 10),
              ...jobs.map((j) => _ReviewCard(job: j)),
            ],
          ),
        );
      },
    );
  }
}

class _ReviewStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _ReviewStat(
      {required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration:
          BoxDecoration(color: AC.surface(context), borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(color: AC.text(context), fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label, style: TextStyle(color: AC.textSec(context), fontSize: 11)),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Job job;
  const _ReviewCard({required this.job});

  @override
  Widget build(BuildContext context) {
    final rating = job.fundiRating ?? 0.0;
    final review = job.toJson()['clientReview'] as String?;
    final tip = job.toJson()['tipAmount'] as double?;
    final date = DateFormat('MMM d, y').format(job.createdAt);

    return Container(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job.title,
                        style: TextStyle(
                            color: AC.text(context),
                            fontWeight: FontWeight.w700,
                            fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(date, style: TextStyle(color: AC.textSec(context), fontSize: 11)),
                  ],
                ),
              ),
              // Star rating
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < rating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: Colors.amber,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(rating.toStringAsFixed(1),
                  style: TextStyle(color: AC.text(context), fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          if (review != null && review.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: AC.input(context), borderRadius: BorderRadius.circular(10)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.format_quote, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(review,
                        style: TextStyle(color: AC.text(context), fontSize: 12),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              if (job.clientName != null) ...[
                const Icon(Icons.person_outline, size: 12, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(job.clientName!,
                    style: TextStyle(color: AC.textSec(context), fontSize: 11)),
                const SizedBox(width: 12),
              ],
              if (job.fundiName != null) ...[
                const Icon(Icons.build_outlined, size: 12, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(job.fundiName!,
                    style: TextStyle(color: AC.textSec(context), fontSize: 11)),
              ],
              if (tip != null && tip > 0) ...[
                const Spacer(),
                const Icon(Icons.volunteer_activism_outlined, size: 12, color: Colors.green),
                const SizedBox(width: 4),
                Text('Tip: KES ${tip.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: Colors.green, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
