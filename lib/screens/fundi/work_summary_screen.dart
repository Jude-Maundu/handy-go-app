import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../config/flavor_config.dart';
import '../../models/job_model.dart';
import '../../providers/job_provider.dart';
import 'payment_request_screen.dart';

class WorkSummaryScreen extends StatefulWidget {
  final Job job;
  const WorkSummaryScreen({super.key, required this.job});

  @override
  State<WorkSummaryScreen> createState() => _WorkSummaryScreenState();
}

class _WorkSummaryScreenState extends State<WorkSummaryScreen> {
  final List<_LineItem> _items = [];
  bool _updatingStatus = false;

  @override
  void initState() {
    super.initState();
    _markInProgress();
  }

  Future<void> _markInProgress() async {
    await context.read<JobProvider>().updateJobStatus(
      widget.job.id,
      JobStatus.inProgress,
      clientId: widget.job.clientId,
      title: widget.job.title,
    );
  }

  double get _total => _items.fold(0, (sum, i) => sum + i.amount);

  void _showAddItemSheet() {
    final nameCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    String category = 'Labour';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AC.surface(context),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AC.div(ctx),
                        borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              Text('Add Item',
                  style: TextStyle(
                      color: AC.text(ctx),
                      fontSize: 17,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // Category chips
              Row(
                children: ['Labour', 'Equipment', 'Other'].map((cat) {
                  final sel = category == cat;
                  final accent = FlavorConfig.instance.primaryColor;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setSheet(() => category = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel
                              ? accent.withValues(alpha: 0.15)
                              : AC.input(ctx),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: sel ? accent : AC.div(ctx), width: 1.5),
                        ),
                        child: Text(cat,
                            style: TextStyle(
                                color: sel ? accent : AC.textSec(ctx),
                                fontSize: 13,
                                fontWeight: sel
                                    ? FontWeight.w700
                                    : FontWeight.normal)),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Item name
              TextField(
                controller: nameCtrl,
                style: TextStyle(color: AC.text(ctx)),
                decoration: InputDecoration(
                  hintText: 'Description (e.g. PVC pipe, 2 hrs labour)',
                  hintStyle: TextStyle(color: AC.textSec(ctx)),
                  filled: true,
                  fillColor: AC.input(ctx),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),

              // Amount
              TextField(
                controller: amtCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: TextStyle(color: AC.text(ctx)),
                decoration: InputDecoration(
                  hintText: 'Amount (KES)',
                  hintStyle: TextStyle(color: AC.textSec(ctx)),
                  prefixText: 'KES  ',
                  prefixStyle: TextStyle(
                      color: FlavorConfig.instance.primaryColor,
                      fontWeight: FontWeight.w600),
                  filled: true,
                  fillColor: AC.input(ctx),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    final amt = double.tryParse(amtCtrl.text.trim()) ?? 0;
                    if (name.isEmpty || amt <= 0) return;
                    setState(() {
                      _items.add(_LineItem(
                          name: name, amount: amt, category: category));
                    });
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FlavorConfig.instance.primaryColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Add Item',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _requestPayment() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Add at least one item before requesting payment'),
            behavior: SnackBarBehavior.floating),
      );
      return;
    }
    setState(() => _updatingStatus = true);
    await context.read<JobProvider>().updateJobStatus(
          widget.job.id,
          JobStatus.completed,
          clientId: widget.job.clientId,
          title: widget.job.title,
        );
    if (!mounted) return;
    setState(() => _updatingStatus = false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentRequestScreen(
          job: widget.job,
          customAmount: _total,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = FlavorConfig.instance.primaryColor;

    return Scaffold(
      backgroundColor: AC.bg(context),
      appBar: AppBar(
        backgroundColor: AC.bg(context),
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: AC.surface(context),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.arrow_back_ios_new,
                size: 16, color: AppColors.textPrimary),
          ),
        ),
        title: const Text('Work Summary',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      ),
      body: Column(
        children: [
          // Job info banner
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AC.surface(context),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
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
                      Text(widget.job.title,
                          style: TextStyle(
                              color: AC.text(context),
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                      Text('Client: ${widget.job.clientName ?? "—"}',
                          style: TextStyle(
                              color: AC.textSec(context), fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Arrived',
                      style: TextStyle(
                          color: Colors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Items list
          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 56,
                            color: AC.textSec(context).withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        Text('No items yet',
                            style: TextStyle(
                                color: AC.textSec(context),
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text('Tap "Add Item" to list what you used',
                            style: TextStyle(
                                color: AC.textSec(context), fontSize: 13)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _items.length,
                    itemBuilder: (_, i) {
                      final item = _items[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AC.surface(context),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: _categoryColor(item.category)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(_categoryIcon(item.category),
                                  color: _categoryColor(item.category),
                                  size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.name,
                                      style: TextStyle(
                                          color: AC.text(context),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                  Text(item.category,
                                      style: TextStyle(
                                          color: AC.textSec(context),
                                          fontSize: 11)),
                                ],
                              ),
                            ),
                            Text('KES ${item.amount.toStringAsFixed(0)}',
                                style: TextStyle(
                                    color: AC.text(context),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14)),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _items.removeAt(i)),
                              child: Icon(Icons.close,
                                  size: 18,
                                  color: AC.textSec(context)
                                      .withValues(alpha: 0.6)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AC.surface(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, -2)),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Breakdown totals
                if (_items.isNotEmpty) ...[
                  ..._groupTotals().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Text(e.key,
                                style: TextStyle(
                                    color: AC.textSec(context), fontSize: 13)),
                            const Spacer(),
                            Text('KES ${e.value.toStringAsFixed(0)}',
                                style: TextStyle(
                                    color: AC.text(context),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                          ],
                        ),
                      )),
                  Divider(color: AC.div(context)),
                ],
                Row(
                  children: [
                    Text('Total',
                        style: TextStyle(
                            color: AC.text(context),
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    const Spacer(),
                    Text(
                      'KES ${_total.toStringAsFixed(0)}',
                      style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Item',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        onPressed: _showAddItemSheet,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: accent,
                          side: BorderSide(color: accent),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        icon: _updatingStatus
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.black))
                            : const Icon(Icons.payment_outlined, size: 18),
                        label: Text(
                            _updatingStatus ? 'Updating…' : 'Request Payment',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700)),
                        onPressed: _updatingStatus ? null : _requestPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Map<String, double> _groupTotals() {
    final map = <String, double>{};
    for (final item in _items) {
      map[item.category] = (map[item.category] ?? 0) + item.amount;
    }
    return map;
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'Labour':
        return Colors.blue;
      case 'Equipment':
        return Colors.orange;
      default:
        return Colors.purple;
    }
  }

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'Labour':
        return Icons.person_outline;
      case 'Equipment':
        return Icons.construction_outlined;
      default:
        return Icons.category_outlined;
    }
  }
}

class _LineItem {
  final String name;
  final double amount;
  final String category;
  const _LineItem(
      {required this.name, required this.amount, required this.category});
}
