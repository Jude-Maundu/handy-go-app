import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../config/flavor_config.dart';
import '../../models/job_model.dart';
import '../../providers/job_provider.dart';
import '../../services/mpesa_service.dart';
import '../../services/toast_service.dart';

class PaymentRequestScreen extends StatefulWidget {
  final Job job;
  final double? customAmount; // total from WorkSummaryScreen
  const PaymentRequestScreen({super.key, required this.job, this.customAmount});

  @override
  State<PaymentRequestScreen> createState() => _PaymentRequestScreenState();
}

class _PaymentRequestScreenState extends State<PaymentRequestScreen> {
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();

  _Stage _stage = _Stage.form;
  _SendingStage _sendingStage = _SendingStage.sending;
  MpesaStatus? _finalStatus;
  String _statusMessage = '';
  bool _pollingCancelled = false;
  int _pollAttempt = 0;
  static const _maxAttempts = 12;

  @override
  void initState() {
    super.initState();
    final amount = widget.customAmount ?? widget.job.budget;
    _amountController.text = amount.toStringAsFixed(0);
    if (widget.job.clientPhone != null) {
      _phoneController.text = widget.job.clientPhone!;
    }
  }

  @override
  void dispose() {
    _pollingCancelled = true;
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
      AppToast.show(context, 'Enter a valid Kenyan number e.g. 0712 345 678', isError: true);
      return;
    }
    if (amount <= 0) {
      AppToast.show(context, 'Enter a valid amount', isError: true);
      return;
    }

    setState(() {
      _stage = _Stage.sending;
      _sendingStage = _SendingStage.sending;
      _statusMessage = 'Sending M-Pesa request…';
      _pollingCancelled = false;
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
        _stage = _Stage.done;
        _finalStatus = MpesaStatus.failed;
        _statusMessage = result.message ?? 'Request failed. Try again.';
      });
      return;
    }

    await context.read<JobProvider>().updatePaymentStatus(
          widget.job.id,
          'pending',
          checkoutRequestId: result.checkoutRequestId,
        );

    setState(() {
      _sendingStage = _SendingStage.waitingPin;
      _statusMessage =
          result.message ?? 'PIN prompt sent to client\'s phone!';
    });

    await _pollLoop(result.checkoutRequestId!);
  }

  Future<void> _pollLoop(String checkoutRequestId) async {
    for (int i = 0; i < _maxAttempts; i++) {
      if (_pollingCancelled || !mounted) break;
      setState(() => _pollAttempt = i + 1);

      await Future.delayed(const Duration(seconds: 5));

      if (_pollingCancelled || !mounted) break;

      final status = await MpesaService.queryOnce(checkoutRequestId);

      if (!mounted) return;
      if (status == MpesaStatus.pending) continue;

      // Definitive result
      final payStatus = status == MpesaStatus.success ? 'paid' : 'failed';
      await context
          .read<JobProvider>()
          .updatePaymentStatus(widget.job.id, payStatus);

      if (!mounted) return;
      setState(() {
        _stage = _Stage.done;
        _finalStatus = status;
        _statusMessage = switch (status) {
          MpesaStatus.success =>
            'Payment received! KES ${_amountController.text}',
          MpesaStatus.cancelled => 'Client cancelled the payment.',
          _ => 'Payment failed. Please try again.',
        };
      });
      return;
    }

    // Timed out or cancelled manually
    if (mounted && !_pollingCancelled) {
      await context
          .read<JobProvider>()
          .updatePaymentStatus(widget.job.id, 'failed');
      setState(() {
        _stage = _Stage.done;
        _finalStatus = MpesaStatus.timeout;
        _statusMessage = 'No response from client. Please try again.';
      });
    }
  }

  void _cancelPolling() {
    _pollingCancelled = true;
    setState(() {
      _stage = _Stage.form;
      _sendingStage = _SendingStage.sending;
      _pollAttempt = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = FlavorConfig.instance.primaryColor;

    return Scaffold(
      backgroundColor: AC.bg(context),
      appBar: _stage == _Stage.form
          ? AppBar(
              backgroundColor: AC.bg(context),
              title: const Text('Request Payment'),
              elevation: 0,
            )
          : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_stage == _Stage.form) ..._formWidgets(accent),
              if (_stage == _Stage.sending) ..._sendingWidgets(),
              if (_stage == _Stage.done) ..._doneWidgets(accent),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _formWidgets(Color accent) => [
        // M-Pesa header
        Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.phone_android,
                  color: Colors.green, size: 28),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'M-Pesa Payment Request',
                  style: TextStyle(
                      color: AC.text(context),
                      fontWeight: FontWeight.bold,
                      fontSize: 17),
                ),
                Text(
                  'Lipa Na M-Pesa · STK Push',
                  style: TextStyle(color: AC.textSec(context), fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Job summary card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
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
                    Text(
                      widget.job.title,
                      style: TextStyle(
                          color: AC.text(context),
                          fontWeight: FontWeight.w600,
                          fontSize: 14),
                    ),
                    Text(
                      'Client: ${widget.job.clientName ?? 'Client'}',
                      style: TextStyle(
                          color: AC.textSec(context), fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                'KES ${_amountController.text}',
                style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 16),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Phone field
        _label('Client M-Pesa Number'),
        const SizedBox(height: 8),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(color: AC.text(context), fontSize: 16),
          decoration: InputDecoration(
            hintText: '0712 345 678',
            hintStyle: TextStyle(color: AC.textSec(context)),
            filled: true,
            fillColor: AC.input(context),
            prefixIcon: Icon(Icons.phone_outlined,
                color: AC.textSec(context), size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accent, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'The client will receive an M-Pesa push notification',
          style: TextStyle(color: AC.textSec(context), fontSize: 12),
        ),
        const SizedBox(height: 20),

        // Amount field
        _label('Amount (KES)'),
        const SizedBox(height: 8),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(color: AC.text(context), fontSize: 16),
          decoration: InputDecoration(
            hintStyle: TextStyle(color: AC.textSec(context)),
            filled: true,
            fillColor: AC.input(context),
            prefixIcon: Icon(Icons.payments_outlined,
                color: AC.textSec(context), size: 20),
            prefixText: 'KES  ',
            prefixStyle: TextStyle(
                color: accent, fontWeight: FontWeight.w600, fontSize: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accent, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.send_rounded, size: 20),
            label: const Text(
              'Send M-Pesa Request',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            onPressed: _sendRequest,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ];

  List<Widget> _sendingWidgets() {
    final isSending = _sendingStage == _SendingStage.sending;
    return [
      const SizedBox(height: 48),

      // Stage indicator
      Center(
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: isSending
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(
                      color: Colors.green, strokeWidth: 3),
                )
              : const Icon(Icons.phone_android,
                  color: Colors.green, size: 40),
        ),
      ),
      const SizedBox(height: 24),

      // Status text
      Center(
        child: Text(
          isSending ? 'Sending M-Pesa Request…' : 'Waiting for Client',
          style: TextStyle(
              color: AC.text(context),
              fontSize: 18,
              fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
      const SizedBox(height: 10),
      Center(
        child: Text(
          _statusMessage,
          style: TextStyle(color: AC.textSec(context), fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ),

      // Stages timeline (shown in waitingPin phase)
      if (!isSending) ...[
        const SizedBox(height: 32),
        _stageRow(Icons.send_rounded, 'STK Push Sent', true, Colors.green),
        _stageConnector(true),
        _stageRow(Icons.lock_outline, 'Client Entering PIN', true, Colors.orange),
        _stageConnector(false),
        _stageRow(Icons.check_circle_outline, 'Payment Confirmed', false, AC.textSec(context)),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Attempt $_pollAttempt of $_maxAttempts',
            style: TextStyle(color: AC.textSec(context), fontSize: 12),
          ),
        ),
        const SizedBox(height: 24),

        // Cancel button
        Center(
          child: TextButton(
            onPressed: _cancelPolling,
            child: Text(
              'Cancel & Go Back',
              style: TextStyle(
                  color: Colors.red.withValues(alpha: 0.8), fontSize: 14),
            ),
          ),
        ),
      ],
    ];
  }

  Widget _stageRow(IconData icon, String label, bool active, Color color) =>
      Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: active ? color.withValues(alpha: 0.12) : AC.input(context),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: active ? color : AC.textSec(context).withValues(alpha: 0.4)),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: active ? AC.text(context) : AC.textSec(context).withValues(alpha: 0.4),
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ],
      );

  Widget _stageConnector(bool active) => Padding(
        padding: const EdgeInsets.only(left: 17),
        child: Container(
          width: 2,
          height: 20,
          color: active
              ? Colors.green.withValues(alpha: 0.4)
              : AC.div(context),
        ),
      );

  List<Widget> _doneWidgets(Color accent) {
    final success = _finalStatus == MpesaStatus.success;
    final cancelled = _finalStatus == MpesaStatus.cancelled;

    Color iconColor;
    IconData icon;
    if (success) {
      iconColor = Colors.green;
      icon = Icons.check_circle_rounded;
    } else if (cancelled) {
      iconColor = Colors.orange;
      icon = Icons.cancel_rounded;
    } else {
      iconColor = Colors.red;
      icon = Icons.error_rounded;
    }

    return [
      const SizedBox(height: 48),

      // Status stages — completed view
      _stageRow(Icons.send_rounded, 'STK Push Sent', true, Colors.green),
      _stageConnector(true),
      _stageRow(
        Icons.lock_outline,
        cancelled ? 'Client Cancelled' : 'PIN Entered',
        true,
        cancelled ? Colors.orange : Colors.green,
      ),
      _stageConnector(success),
      _stageRow(
        Icons.check_circle_outline,
        success ? 'Payment Confirmed' : 'Not Completed',
        success,
        success ? Colors.green : AC.textSec(context),
      ),
      const SizedBox(height: 32),

      Center(
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 64),
        ),
      ),
      const SizedBox(height: 24),
      Center(
        child: Text(
          _statusMessage,
          style: TextStyle(
              color: AC.text(context),
              fontSize: 18,
              fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
      const SizedBox(height: 40),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: success ? Colors.green : accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text(
            success ? 'Done' : 'Go Back',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    ];
  }

  Widget _label(String text) => Text(
        text,
        style: TextStyle(
            color: AC.text(context),
            fontSize: 14,
            fontWeight: FontWeight.w600),
      );
}

enum _Stage { form, sending, done }

enum _SendingStage { sending, waitingPin }
