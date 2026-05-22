import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../config/map_config.dart';
import '../../config/flavor_config.dart';
import '../../providers/job_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/job_model.dart';
import '../../services/mpesa_service.dart';
import 'track_fundi_screen.dart';
import 'rate_fundi.dart';
import '../sharedscreens/report_screen.dart';
import '../sharedscreens/chat_screen.dart';

class BookingDetailsScreen extends StatefulWidget {
  final String jobId;
  const BookingDetailsScreen({super.key, required this.jobId});

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
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
          return Scaffold(backgroundColor: AC.bg(context), body: Center(child: CircularProgressIndicator()));
        }
        if (job == null) {
          return Scaffold(
            backgroundColor: AC.bg(context),
            appBar: AppBar(title: const Text('Details')),
            body: const Center(child: Text('Job not found', style: TextStyle(color: AppColors.textSecondary))),
          );
        }
        return _OrderView(job: job);
      },
    );
  }
}

class _OrderView extends StatelessWidget {
  final Job job;
  const _OrderView({required this.job});

  @override
  Widget build(BuildContext context) {
    final accent = FlavorConfig.instance.primaryColor;
    final center = job.latitude != null
        ? LatLng(job.latitude!, job.longitude!)
        : const LatLng(-1.286389, 36.817223);

    return Scaffold(
      backgroundColor: AC.bg(context),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            options: MapOptions(initialCenter: center, initialZoom: 15),
            children: [
              ...MapConfig.tileLayers(dark: Theme.of(context).brightness == Brightness.dark),
              MarkerLayer(markers: [
                Marker(
                  point: center,
                  width: 36, height: 36,
                  child: Container(
                    decoration: BoxDecoration(color: accent, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                    child: const Icon(Icons.home_repair_service, color: Colors.black, size: 18),
                  ),
                ),
              ]),
            ],
          ),

          // Back button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(color: AC.surface(context), shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.textPrimary),
                ),
              ),
            ),
          ),

          // Promo banner on map
          Positioned(
            left: 16, right: 16,
            bottom: 280,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  const Icon(Icons.local_offer, color: Colors.black, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('First booking 20% off — use code HANDYGO20', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),

          // Bottom panel
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              decoration: BoxDecoration(
                color: AC.surface(context),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 36, height: 4,
                      decoration: BoxDecoration(color: AC.div(context), borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Fundi info row
                  Row(
                    children: [
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(color: accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
                        child: Icon(Icons.build, color: accent, size: 26),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(job.fundiName ?? 'Not assigned', style: TextStyle(color: AC.text(context), fontWeight: FontWeight.w700, fontSize: 15)),
                            const SizedBox(height: 3),
                            Text(job.category, style: TextStyle(color: AC.textSec(context), fontSize: 12)),
                            const SizedBox(height: 3),
                            Row(children: [
                              const Icon(Icons.star, color: Colors.amber, size: 13),
                              const SizedBox(width: 3),
                              Text(job.fundiRating?.toStringAsFixed(1) ?? '—', style: TextStyle(color: AC.textSec(context), fontSize: 12)),
                              if (job.distanceToFundi > 0) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.access_time, color: AppColors.textSecondary, size: 13),
                                const SizedBox(width: 3),
                                Text('${(job.distanceToFundi * 3).toStringAsFixed(0)} min', style: TextStyle(color: AC.textSec(context), fontSize: 12)),
                                const SizedBox(width: 8),
                                const Icon(Icons.near_me, color: AppColors.textSecondary, size: 13),
                                const SizedBox(width: 3),
                                Text('${job.distanceToFundi.toStringAsFixed(1)} km', style: TextStyle(color: AC.textSec(context), fontSize: 12)),
                              ],
                            ]),
                          ],
                        ),
                      ),
                      Text('KES ${job.budget.toStringAsFixed(0)}', style: TextStyle(color: accent, fontWeight: FontWeight.w800, fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: AC.div(context)),
                  const SizedBox(height: 12),

                  // Action icons row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ActionIcon(
                        icon: Icons.phone_android,
                        label: 'M-Pesa',
                        onTap: job.paymentStatus == 'paid'
                            ? null
                            : () => _showMpesaSheet(context, job),
                        color: job.paymentStatus == 'paid' ? Colors.green : null,
                      ),
                      _ActionIcon(
                        icon: Icons.chat_bubble_outline,
                        label: 'Chat',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              jobId: job.id,
                              jobTitle: job.title,
                              otherPartyName: job.fundiName ?? 'Fundi',
                            ),
                          ),
                        ),
                      ),
                      if (job.fundiId != null)
                        _ActionIcon(
                          icon: Icons.flag_outlined,
                          label: 'Report',
                          color: Colors.red,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReportScreen(
                                jobId: job.id,
                                reportedUserId: job.fundiId!,
                                reportedUserName: job.fundiName ?? 'Fundi',
                              ),
                            ),
                          ),
                        )
                      else
                        const _ActionIcon(icon: Icons.grid_view, label: 'Services'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _statusColor(job.status).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(job.statusText, style: TextStyle(color: _statusColor(job.status), fontWeight: FontWeight.w600, fontSize: 13)),
                  ),

                  // Work items checklist (visible once fundi submits)
                  if (job.workItems.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Work Summary', style: TextStyle(color: AC.text(context), fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                    const SizedBox(height: 8),
                    ...job.workItems.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(item['name'] as String? ?? '', style: TextStyle(color: AC.text(context), fontSize: 13)),
                          ),
                          Text(
                            'KES ${(item['amount'] as num?)?.toStringAsFixed(0) ?? '0'}',
                            style: TextStyle(color: AC.text(context), fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ],
                      ),
                    )),
                    Divider(color: AC.div(context)),
                    Row(
                      children: [
                        Text('Total', style: TextStyle(color: AC.text(context), fontWeight: FontWeight.bold, fontSize: 14)),
                        const Spacer(),
                        Text(
                          'KES ${job.workItems.fold<double>(0, (s, i) => s + ((i['amount'] as num?)?.toDouble() ?? 0)).toStringAsFixed(0)}',
                          style: TextStyle(color: accent, fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),

                  // CTA button
                  SizedBox(
                    width: double.infinity,
                    child: _buildCTA(context, job, accent),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCTA(BuildContext context, Job job, Color accent) {
    if (job.status == JobStatus.inProgress) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TrackFundiScreen(jobId: job.id))),
        child: const Text('Track Fundi', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      );
    }
    if (job.status == JobStatus.completed) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RateFundiScreen(jobId: job.id, fundiName: job.fundiName ?? 'Fundi', fundiId: job.fundiId ?? ''))),
        child: const Text('Rate Fundi', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      );
    }
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      onPressed: () {},
      child: const Text('Order', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
    );
  }

  Color _statusColor(JobStatus s) {
    switch (s) {
      case JobStatus.pending: return Colors.orange;
      case JobStatus.accepted: return Colors.blue;
      case JobStatus.inProgress: return Colors.green;
      case JobStatus.completed: return Colors.grey;
      case JobStatus.cancelled: return Colors.red;
    }
  }

  void _showMpesaSheet(BuildContext context, Job job) {
    final phoneCtrl = TextEditingController();
    final auth = context.read<AuthProvider>();
    if (auth.phone != null) phoneCtrl.text = auth.phone!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _MpesaSheet(job: job, phoneCtrl: phoneCtrl),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback? onTap;
  const _ActionIcon({required this.icon, required this.label, this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? AppColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color != null ? color!.withValues(alpha: 0.1) : AC.input(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color ?? AC.textSec(context), fontSize: 11)),
        ],
      ),
    );
  }
}

// ── M-Pesa payment sheet ──────────────────────────────────────────────────────

class _MpesaSheet extends StatefulWidget {
  final Job job;
  final TextEditingController phoneCtrl;
  const _MpesaSheet({required this.job, required this.phoneCtrl});

  @override
  State<_MpesaSheet> createState() => _MpesaSheetState();
}

class _MpesaSheetState extends State<_MpesaSheet> {
  bool _loading = false;
  String? _statusMsg;
  bool _success = false;

  Future<void> _pay() async {
    final raw = widget.phoneCtrl.text.trim().replaceAll(RegExp(r'\s+'), '');
    // Normalise to 2547XXXXXXXX
    String phone = raw.startsWith('0') ? '254${raw.substring(1)}' : raw;
    if (!RegExp(r'^2547\d{8}$').hasMatch(phone)) {
      setState(() => _statusMsg = 'Enter a valid Safaricom number (07XXXXXXXX)');
      return;
    }

    setState(() { _loading = true; _statusMsg = 'Sending STK push to $phone…'; });

    final result = await MpesaService.stkPush(
      phone: phone,
      amount: widget.job.budget.ceil(),
      jobId: widget.job.id,
      description: widget.job.title,
    );

    if (!mounted) return;

    if (result.status == MpesaStatus.failed) {
      setState(() { _loading = false; _statusMsg = result.message ?? 'Payment failed'; });
      return;
    }

    setState(() => _statusMsg = 'Check your phone and enter your M-Pesa PIN…');

    if (result.checkoutRequestId != null) {
      final finalStatus = await MpesaService.pollStatus(
        checkoutRequestId: result.checkoutRequestId!,
        intervalSecs: 5,
        maxAttempts: 12,
      );
      if (!mounted) return;

      if (finalStatus == MpesaStatus.success) {
        await context.read<JobProvider>().updatePaymentStatus(widget.job.id, 'paid');
        setState(() { _loading = false; _success = true; _statusMsg = 'Payment successful!'; });
      } else if (finalStatus == MpesaStatus.cancelled) {
        setState(() { _loading = false; _statusMsg = 'You cancelled the payment'; });
      } else if (finalStatus == MpesaStatus.timeout) {
        setState(() { _loading = false; _statusMsg = 'Timed out — check your M-Pesa messages'; });
      } else {
        setState(() { _loading = false; _statusMsg = 'Payment failed — try again'; });
      }
    } else {
      setState(() { _loading = false; _statusMsg = 'STK push sent — check your phone'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = FlavorConfig.instance.primaryColor;
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AC.div(context), borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 20),
          Text('Pay via M-Pesa',
              style: TextStyle(color: AC.text(context), fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('KES ${widget.job.budget.toStringAsFixed(0)} · ${widget.job.title}',
              style: TextStyle(color: AC.textSec(context), fontSize: 13)),
          const SizedBox(height: 20),
          Text('Phone Number', style: TextStyle(color: AC.textSec(context), fontSize: 12)),
          const SizedBox(height: 6),
          TextField(
            controller: widget.phoneCtrl,
            keyboardType: TextInputType.phone,
            style: TextStyle(color: AC.text(context)),
            enabled: !_loading && !_success,
            decoration: InputDecoration(
              hintText: '07XXXXXXXX',
              hintStyle: TextStyle(color: AC.textSec(context)),
              prefixIcon: const Icon(Icons.phone_android, size: 18),
              filled: true,
              fillColor: AC.input(context),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          if (_statusMsg != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  _success ? Icons.check_circle : (_loading ? Icons.hourglass_top : Icons.info_outline),
                  size: 16,
                  color: _success ? Colors.green : (_loading ? Colors.orange : Colors.red),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_statusMsg!,
                      style: TextStyle(
                          color: _success ? Colors.green : (_loading ? Colors.orange : Colors.red),
                          fontSize: 13)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_loading || _success) ? null : _pay,
              style: ElevatedButton.styleFrom(
                backgroundColor: _success ? Colors.green : accent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _loading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : Text(_success ? 'Payment Complete!' : 'Send STK Push',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
