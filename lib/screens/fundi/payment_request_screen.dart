import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../config/flavor_config.dart';
import '../../models/job_model.dart';
import '../../providers/job_provider.dart';
import '../../services/mpesa_service.dart';

class PaymentRequestScreen extends StatefulWidget {
  final Job job;
  const PaymentRequestScreen({super.key, required this.job});

  @override
  State<PaymentRequestScreen> createState() => _PaymentRequestScreenState();
}

class _PaymentRequestScreenState extends State<PaymentRequestScreen> {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid Kenyan number e.g. 0712 345 678'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid amount'),
          behavior: SnackBarBehavior.floating,
        ),
      );
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

    await context.read<JobProvider>().updatePaymentStatus(
          widget.job.id,
          'pending',
          checkoutRequestId: result.checkoutRequestId,
        );

    setState(() =>
        _statusMessage = result.message ?? 'Prompt sent! Waiting for client to enter PIN…');

    final status = await MpesaService.pollStatus(
      checkoutRequestId: result.checkoutRequestId!,
    );

    if (!mounted) return;

    if (status == MpesaStatus.success) {
      await context.read<JobProvider>().updatePaymentStatus(widget.job.id, 'paid');
    } else {
      await context.read<JobProvider>().updatePaymentStatus(widget.job.id, 'failed');
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

  @override
  Widget build(BuildContext context) {
    final accent = FlavorConfig.instance.primaryColor;

    return Scaffold(
      backgroundColor: AC.bg(context),
      appBar: _step == _Step.form
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
              if (_step == _Step.form) ..._formWidgets(accent),
              if (_step == _Step.sending) ..._sendingWidgets(),
              if (_step == _Step.done) ..._doneWidgets(accent),
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
                'KES ${widget.job.budget.toStringAsFixed(0)}',
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

  List<Widget> _sendingWidgets() => [
        const SizedBox(height: 60),
        const Center(
          child: CircularProgressIndicator(color: Colors.green, strokeWidth: 3),
        ),
        const SizedBox(height: 32),
        Center(
          child: Text(
            _statusMessage,
            style: TextStyle(
                color: AC.text(context),
                fontSize: 16,
                fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'Keep this screen open while waiting for the client',
            style: TextStyle(color: AC.textSec(context), fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),
      ];

  List<Widget> _doneWidgets(Color accent) {
    final success = _finalStatus == MpesaStatus.success;

    return [
      const SizedBox(height: 48),
      Center(
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: (success ? Colors.green : Colors.red).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            success ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: success ? Colors.green : Colors.red,
            size: 64,
          ),
        ),
      ),
      const SizedBox(height: 28),
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
      const SizedBox(height: 12),
      if (!success)
        Center(
          child: Text(
            'You can request payment again from the Payments tab',
            style: TextStyle(color: AC.textSec(context), fontSize: 13),
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

enum _Step { form, sending, done }
