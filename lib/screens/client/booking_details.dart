import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../config/map_config.dart';
import '../../config/flavor_config.dart';
import '../../providers/job_provider.dart';
import '../../models/job_model.dart';
import 'track_fundi_screen.dart';
import 'rate_fundi.dart';

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
                      _ActionIcon(icon: Icons.phone_android, label: 'M-Pesa'),
                      _ActionIcon(icon: Icons.chat_bubble_outline, label: 'Comment'),
                      _ActionIcon(icon: Icons.grid_view, label: 'Services'),
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
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ActionIcon({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: AC.input(context), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: AppColors.textSecondary, size: 20),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: AC.textSec(context), fontSize: 11)),
      ],
    );
  }
}
