import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/job_model.dart';
import '../../providers/job_provider.dart';
import '../../services/mpesa_service.dart';

/// Call this to show the M-Pesa payment sheet from any screen.
Future<void> showPaymentSheet(BuildContext context, Job job) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PaymentSheet(job: job),
  );
}

class _PaymentSheet extends StatefulWidget {
  final Job job;
  const _PaymentSheet({required this.job});

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();

  _Step _step = _Step.form;
  String _statusMessage = '';
  MpesaStatus? _finalStatus;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.job.budget.toStringAsFixed(0);
    if (widget.job.clientPhone != null) {
      _phoneController.text = widget.job.clientPhone!;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  String _normalisePhone(String raw) {
    var p = raw.trim().replaceAll(RegExp(r'\s+'), '');
    if (p.startsWith('0')) p = '254${p.substring(1)}';
    if (p.startsWith('+')) p = p.substring(1);
    return p;
  }

  Future<void> _sendRequest() async {
    final phone = _normalisePhone(_phoneController.text);
    final amount = int.tryParse(_amountController.text.trim()) ?? 0;

    if (phone.length != 12 || !phone.startsWith('254')) {
      _show('Enter a valid Kenyan number e.g. 0712 345 678');
      return;
    }
    if (amount <= 0) {
      _show('Enter a valid amount');
      return;
    }

    setState(() {
      _step = _Step.sending;
      _statusMessage = 'Sending M-Pesa request…';
    });

    final result = await MpesaService.stkPush(
      phone: phone,
      amount: amount,
      jobId: widget.job.id,
      description: 'Payment for ${widget.job.title}',
    );

    if (!mounted) return;

    if (result.status != MpesaStatus.pending) {
      setState(() {
        _step = _Step.done;
        _finalStatus = MpesaStatus.failed;
        _statusMessage = result.message ?? 'Request failed. Try again.';
      });
      return;
    }

    // Save checkoutRequestId so the Render callback server can find this job
    await context.read<JobProvider>().updatePaymentStatus(
          widget.job.id, 'pending',
          checkoutRequestId: result.checkoutRequestId);

    setState(() => _statusMessage = result.message ??
        'Prompt sent! Waiting for client to enter PIN…');

    // Poll for completion
    final status = await MpesaService.pollStatus(
      checkoutRequestId: result.checkoutRequestId!,
    );

    if (!mounted) return;

    if (status == MpesaStatus.success) {
      await context.read<JobProvider>().updatePaymentStatus(widget.job.id, 'paid');
    } else {
      await context
          .read<JobProvider>()
          .updatePaymentStatus(widget.job.id, 'failed');
    }

    setState(() {
      _step = _Step.done;
      _finalStatus = status;
      _statusMessage = status == MpesaStatus.success
          ? 'Payment received! KES ${_amountController.text}'
          : status == MpesaStatus.timeout
              ? 'No response from client. Try again.'
              : 'Client cancelled or payment failed.';
    });
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: AC.surface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
                color: AC.div(context), borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),

          // M-Pesa logo row
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.phone_android,
                    color: Color(0xFF4CAF50), size: 24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Request M-Pesa Payment',
                      style: TextStyle(
                          color: AC.text(context),
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  Text('Lipa Na M-Pesa',
                      style: TextStyle(
                          color: AC.textSec(context), fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (_step == _Step.form) ..._formWidgets(accent, isDark),
          if (_step == _Step.sending) ..._sendingWidgets(),
          if (_step == _Step.done) ..._doneWidgets(accent),
        ],
      ),
    );
  }

  List<Widget> _formWidgets(Color accent, bool isDark) => [
        // Job summary chip
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AC.input(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.work_outline, color: AC.textSec(context), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(widget.job.title,
                    style: TextStyle(color: AC.text(context), fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              Text('KES ${widget.job.budget.toStringAsFixed(0)}',
                  style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Phone field
        _label('Client M-Pesa Number'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(color: AC.text(context)),
          decoration: InputDecoration(
            hintText: '0712 345 678',
            prefixIcon: Icon(Icons.phone_outlined,
                color: AC.textSec(context), size: 20),
            prefixText: '🇰🇪  ',
          ),
        ),
        const SizedBox(height: 16),

        // Amount field
        _label('Amount (KES)'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(color: AC.text(context)),
          decoration: InputDecoration(
            prefixIcon:
                Icon(Icons.payments_outlined, color: AC.textSec(context), size: 20),
            prefixText: 'KES  ',
            prefixStyle:
                TextStyle(color: accent, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.send_rounded, size: 18),
            label: const Text('Send M-Pesa Request',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            onPressed: _sendRequest,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ];

  List<Widget> _sendingWidgets() => [
        const SizedBox(height: 12),
        const CircularProgressIndicator(color: Color(0xFF4CAF50)),
        const SizedBox(height: 20),
        Text(_statusMessage,
            style: TextStyle(color: AC.text(context), fontSize: 15),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text('Keep this screen open',
            style: TextStyle(color: AC.textSec(context), fontSize: 12)),
        const SizedBox(height: 24),
      ];

  List<Widget> _doneWidgets(Color accent) {
    final success = _finalStatus == MpesaStatus.success;
    final iconColor = success ? const Color(0xFF4CAF50) : Colors.red;
    final icon = success ? Icons.check_circle_rounded : Icons.cancel_rounded;

    return [
      const SizedBox(height: 8),
      Icon(icon, color: iconColor, size: 64),
      const SizedBox(height: 16),
      Text(_statusMessage,
          style: TextStyle(
              color: AC.text(context),
              fontSize: 16,
              fontWeight: FontWeight.w700),
          textAlign: TextAlign.center),
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: success ? const Color(0xFF4CAF50) : accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text(success ? 'Done' : 'Close',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ),
      ),
    ];
  }

  Widget _label(String text) => Text(text,
      style: TextStyle(
          color: AC.textSec(context),
          fontSize: 13,
          fontWeight: FontWeight.w600));
}

enum _Step { form, sending, done }
