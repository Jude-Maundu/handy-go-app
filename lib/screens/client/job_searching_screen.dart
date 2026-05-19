import 'dart:async';
import '../../config/map_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../config/flavor_config.dart';
import '../../models/job_model.dart';
import '../../providers/job_provider.dart';
import '../../providers/location_provider.dart';

class JobSearchingScreen extends StatefulWidget {
  final String jobId;
  const JobSearchingScreen({super.key, required this.jobId});

  @override
  State<JobSearchingScreen> createState() => _JobSearchingScreenState();
}

class _JobSearchingScreenState extends State<JobSearchingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  late AnimationController _dotsController;
  final _mapController = MapController();

  // Dots animation
  int _dotCount = 1;
  Timer? _dotsTimer;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _pulseAnim = CurvedAnimation(parent: _pulseController, curve: Curves.easeOut);

    _dotsController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

    _dotsTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() => _dotCount = (_dotCount % 3) + 1);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loc = context.read<LocationProvider>();
      loc.addListener(_onLocationUpdate);
      if (!loc.hasLocation) loc.getCurrentLocation();
    });
  }

  void _onLocationUpdate() {
    if (!mounted) return;
    final loc = context.read<LocationProvider>();
    if (!loc.hasLocation) return;
    try {
      _mapController.move(LatLng(loc.latitude!, loc.longitude!), 14);
    } catch (_) {}
  }

  @override
  void dispose() {
    context.read<LocationProvider>().removeListener(_onLocationUpdate);
    _pulseController.dispose();
    _dotsController.dispose();
    _dotsTimer?.cancel();
    super.dispose();
  }

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Request?'),
        content: const Text('Are you sure you want to cancel this job request?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<JobProvider>().cancelJob(widget.jobId);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final accent = FlavorConfig.instance.primaryColor;
    final location = context.watch<LocationProvider>();
    final center = location.hasLocation
        ? LatLng(location.latitude!, location.longitude!)
        : const LatLng(-1.286389, 36.817223);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) { if (!didPop) _cancel(); },
      child: Scaffold(
        backgroundColor: AC.bg(context),
        body: StreamBuilder<Job?>(
          stream: context.read<JobProvider>().streamJobById(widget.jobId),
          builder: (context, snap) {
            final job = snap.data;
            final matched = job != null && job.status == JobStatus.accepted;

            return Stack(
              children: [
                // Map background
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(initialCenter: center, initialZoom: 15),
                  children: [
                    ...MapConfig.tileLayers(dark: Theme.of(context).brightness == Brightness.dark),
                    // Pulsing rings at client location
                    if (location.hasLocation && !matched)
                      MarkerLayer(markers: [
                        Marker(
                          point: center,
                          width: 120, height: 120,
                          child: AnimatedBuilder(
                            animation: _pulseAnim,
                            builder: (_, child) {
                              final size = 40 + 80 * _pulseAnim.value;
                              return Center(
                                child: Container(
                                  width: size,
                                  height: size,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: accent.withValues(alpha: (1 - _pulseAnim.value) * 0.25),
                                    border: Border.all(
                                      color: accent.withValues(alpha: (1 - _pulseAnim.value) * 0.5),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Marker(
                          point: center,
                          width: 44, height: 44,
                          child: Container(
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: const Icon(Icons.person, color: Colors.black, size: 20),
                          ),
                        ),
                      ]),
                    // Matched fundi marker (placeholder location near client)
                    if (location.hasLocation && matched)
                      MarkerLayer(markers: [
                        Marker(
                          point: center,
                          width: 44, height: 44,
                          child: Container(
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: const Icon(Icons.person, color: Colors.black, size: 20),
                          ),
                        ),
                      ]),
                  ],
                ),

                // Back / Cancel button
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: GestureDetector(
                      onTap: _cancel,
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: AC.surface(context).withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close, color: AC.text(context), size: 18),
                      ),
                    ),
                  ),
                ),

                // Bottom panel
                Positioned(
                  left: 0, right: 0, bottom: 0,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: matched
                        ? _MatchedPanel(job: job, accent: accent)
                        : _SearchingPanel(accent: accent, dotCount: _dotCount),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Searching state panel ─────────────────────────────────────────────────────

class _SearchingPanel extends StatelessWidget {
  final Color accent;
  final int dotCount;
  const _SearchingPanel({required this.accent, required this.dotCount});

  @override
  Widget build(BuildContext context) {
    final dots = '.' * dotCount;
    return Container(
      key: const ValueKey('searching'),
      decoration: BoxDecoration(
        color: AC.surface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 36, height: 4, decoration: BoxDecoration(color: AC.div(context), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              SizedBox(
                width: 60, height: 60,
                child: CircularProgressIndicator(color: accent, strokeWidth: 3),
              ),
              const SizedBox(height: 20),
              Text(
                'Finding your fundi$dots',
                style: TextStyle(color: AC.text(context), fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'We\'re matching you with a nearby professional',
                style: TextStyle(color: AC.textSec(context), fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _step(accent, Icons.check, 'Request sent'),
                  _line(accent),
                  _step(accent, Icons.person_search, 'Matching'),
                  _line(Colors.grey),
                  _step(Colors.grey, Icons.handshake_outlined, 'Connected'),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _step(Color color, IconData icon, String label) => Column(
    children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 16),
      ),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    ],
  );

  Widget _line(Color color) => Expanded(
    child: Container(height: 2, margin: const EdgeInsets.only(bottom: 18), color: color.withValues(alpha: 0.4)),
  );
}

// ── Matched state panel ───────────────────────────────────────────────────────

class _MatchedPanel extends StatelessWidget {
  final Job job;
  final Color accent;
  const _MatchedPanel({required this.job, required this.accent});

  @override
  Widget build(BuildContext context) {
    final name = job.fundiName ?? 'Your Fundi';
    final initials = name.trim().split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase();

    return Container(
      key: const ValueKey('matched'),
      decoration: BoxDecoration(
        color: AC.surface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 36, height: 4, decoration: BoxDecoration(color: AC.div(context), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),

              // Success banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    const Text('Fundi Found!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w700, fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Fundi info
              Row(
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(color: accent.withValues(alpha: 0.15), shape: BoxShape.circle),
                    child: Center(child: Text(initials, style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 20))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: TextStyle(color: AC.text(context), fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(height: 2),
                        Text(job.category, style: TextStyle(color: AC.textSec(context), fontSize: 13)),
                        const SizedBox(height: 4),
                        Row(children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                          const SizedBox(width: 3),
                          Text(job.fundiRating != null ? job.fundiRating!.toStringAsFixed(1) : 'New', style: TextStyle(color: AC.textSec(context), fontSize: 12)),
                          const SizedBox(width: 10),
                          const Icon(Icons.directions_walk, color: AppColors.textSecondary, size: 14),
                          const SizedBox(width: 3),
                          Text('On the way', style: TextStyle(color: AC.textSec(context), fontSize: 12)),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Done', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
