import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemNavigator;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/location_provider.dart';
import '../../config/flavor_config.dart';
import '../../config/map_config.dart';
import '../../models/job_model.dart';
import 'job_screen.dart';
import 'navigate_screen.dart';
import '../sharedscreens/profile_screen.dart';
import '../sharedscreens/app_drawer.dart';
import 'fundi_payments_screen.dart';
import '../../services/notification_service.dart';

class FundiMainScreen extends StatefulWidget {
  const FundiMainScreen({super.key});

  @override
  State<FundiMainScreen> createState() => _FundiMainScreenState();
}

class _FundiMainScreenState extends State<FundiMainScreen> {
  int _selectedIndex = 0;
  DateTime? _lastBackPress;

  late final List<Widget> _tabs = [
    _FundiHomeTab(onJobAccepted: () {
      setState(() => _selectedIndex = 1);
      final uid = context.read<AuthProvider>().currentUserId ?? '';
      context.read<JobProvider>().fetchMyJobs(refresh: true, userId: uid);
    }),
    const FundiJobsScreen(),
    const FundiPaymentsScreen(),
    const ProfileScreen(),
  ];

  void _onBackPressed() {
    if (_selectedIndex != 0) {
      setState(() => _selectedIndex = 0);
      return;
    }
    final now = DateTime.now();
    if (_lastBackPress != null && now.difference(_lastBackPress!) < const Duration(seconds: 2)) {
      SystemNavigator.pop();
    } else {
      _lastBackPress = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Press back again to exit'), duration: Duration(seconds: 2), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = FlavorConfig.instance.primaryColor;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) { if (!didPop) _onBackPressed(); },
      child: Scaffold(
        drawer: const AppDrawer(),
        body: IndexedStack(index: _selectedIndex, children: _tabs),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (i) {
            setState(() => _selectedIndex = i);
            if (i == 1) {
              final uid = context.read<AuthProvider>().currentUserId ?? '';
              context.read<JobProvider>().fetchMyJobs(refresh: true, userId: uid);
            }
          },
          indicatorColor: color.withValues(alpha: 0.15),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Discover'),
            NavigationDestination(icon: Icon(Icons.work_outline), selectedIcon: Icon(Icons.work), label: 'My Jobs'),
            NavigationDestination(icon: Icon(Icons.payment_outlined), selectedIcon: Icon(Icons.payment), label: 'Payments'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class _FundiHomeTab extends StatefulWidget {
  final VoidCallback? onJobAccepted;
  const _FundiHomeTab({this.onJobAccepted});

  @override
  State<_FundiHomeTab> createState() => _FundiHomeTabState();
}

class _FundiHomeTabState extends State<_FundiHomeTab> {
  bool _isOnline = false;
  int _secondsLeft = 30;
  String? _timerJobId;
  Timer? _countdown;
  final _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loc = context.read<LocationProvider>();
      loc.addListener(_onLocationUpdate);
      if (!loc.hasLocation) loc.getCurrentLocation();
      final uid = context.read<AuthProvider>().currentUserId;
      if (uid != null) NotificationService.init(uid);
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
    _countdown?.cancel();
    super.dispose();
  }

  void _startCountdown(String jobId) {
    if (_timerJobId == jobId) return;
    _countdown?.cancel();
    _timerJobId = jobId;
    _secondsLeft = 30;
    _countdown = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          _timerJobId = null;
          _countdown?.cancel();
        }
      });
    });
  }

  Future<void> _accept(Job job) async {
    _countdown?.cancel();
    _timerJobId = null;
    final auth = context.read<AuthProvider>();
    final uid = auth.currentUserId;
    final name = auth.userName ?? 'Fundi';
    if (uid == null) return;
    final ok = await context.read<JobProvider>().acceptJob(
      jobId: job.id,
      fundiId: uid,
      fundiName: name,
    );
    if (!mounted) return;
    if (ok) {
      if (job.clientId != null) {
        NotificationService.notifyClient(
          clientId: job.clientId!,
          fundiName: name,
          jobId: job.id,
          jobTitle: job.title,
        );
      }
      await Navigator.push(context, MaterialPageRoute(builder: (_) => NavigateScreen(job: job)));
      if (mounted) widget.onJobAccepted?.call();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job was taken by another fundi'), backgroundColor: Colors.orange),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final location = context.watch<LocationProvider>();
    final color = FlavorConfig.instance.primaryColor;
    final center = location.hasLocation
        ? LatLng(location.latitude!, location.longitude!)
        : const LatLng(-1.286389, 36.817223);

    return Scaffold(
      backgroundColor: AC.bg(context),
      body: Stack(
        children: [
          // Full-screen map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: center, initialZoom: 15),
            children: [
              ...MapConfig.tileLayers(dark: Theme.of(context).brightness == Brightness.dark),
              if (location.hasLocation)
                MarkerLayer(markers: [
                  Marker(
                    point: center,
                    width: 44, height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(Icons.build, color: Colors.black, size: 20),
                    ),
                  ),
                ]),
            ],
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Menu button
                  GestureDetector(
                    onTap: () => Scaffold.of(context).openDrawer(),
                    child: Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: AC.surface(context).withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.menu, color: AC.text(context), size: 20),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Greeting
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AC.surface(context).withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'Hey ${auth.userName?.split(' ').first ?? 'Fundi'} 👋',
                        style: TextStyle(color: AC.text(context), fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Online/offline pill
                  GestureDetector(
                    onTap: () {
                      setState(() => _isOnline = !_isOnline);
                      if (_isOnline) context.read<LocationProvider>().getCurrentLocation();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: _isOnline ? Colors.green : AC.surface(context).withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 6)],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(
                              color: _isOnline ? Colors.white : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isOnline ? 'Online' : 'Go Online',
                            style: TextStyle(
                              color: _isOnline ? Colors.white : AC.textSec(context),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Offline overlay
          if (!_isOnline)
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AC.surface(context).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.power_settings_new, size: 52, color: AC.textSec(context)),
                    const SizedBox(height: 16),
                    Text('You\'re Offline', style: TextStyle(color: AC.text(context), fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Tap "Go Online" to start receiving job requests', style: TextStyle(color: AC.textSec(context), fontSize: 13), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),

          // Live job request card (bottom)
          if (_isOnline)
            StreamBuilder<List<Job>>(
              stream: context.read<JobProvider>().streamPendingJobs(),
              builder: (context, snap) {
                final jobs = snap.data ?? [];
                if (jobs.isEmpty) {
                  return Positioned(
                    left: 16, right: 16, bottom: 24,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AC.surface(context).withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: color)),
                          const SizedBox(width: 12),
                          Text('Waiting for requests...', style: TextStyle(color: AC.text(context), fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  );
                }

                final job = jobs.first;
                _startCountdown(job.id);

                return Positioned(
                  left: 0, right: 0, bottom: 0,
                  child: _JobRequestCard(
                    job: job,
                    secondsLeft: _secondsLeft,
                    color: color,
                    onAccept: () => _accept(job),
                    onSkip: () {
                      // Decline: skip this job for now (timer reset handled by stream)
                      setState(() { _timerJobId = null; _secondsLeft = 0; });
                    },
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// ── Incoming request card ─────────────────────────────────────────────────────

class _JobRequestCard extends StatelessWidget {
  final Job job;
  final int secondsLeft;
  final Color color;
  final VoidCallback onAccept;
  final VoidCallback onSkip;
  const _JobRequestCard({required this.job, required this.secondsLeft, required this.color, required this.onAccept, required this.onSkip});

  static const _icons = {
    'Plumbing': Icons.plumbing,
    'Electrical': Icons.electrical_services,
    'Painting': Icons.format_paint,
    'Cleaning': Icons.cleaning_services,
    'Carpentry': Icons.carpenter,
    'Gardening': Icons.grass,
    'Roofing': Icons.roofing,
    'Masonry': Icons.construction,
  };

  @override
  Widget build(BuildContext context) {
    final icon = _icons[job.category] ?? Icons.handyman_outlined;
    final pct = secondsLeft / 30.0;
    final timerColor = secondsLeft > 10 ? Colors.green : Colors.orange;

    return Container(
      decoration: BoxDecoration(
        color: AC.surface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(width: 36, height: 4, decoration: BoxDecoration(color: AC.div(context), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 14),

              // Header: "New Request" + timer
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                    child: Text('New Request', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                  const Spacer(),
                  // Countdown ring
                  SizedBox(
                    width: 44, height: 44,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(value: pct, backgroundColor: AC.div(context), color: timerColor, strokeWidth: 3),
                        Text('$secondsLeft', style: TextStyle(color: timerColor, fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Job details
              Row(
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                    child: Icon(icon, color: color, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(job.title, style: TextStyle(color: AC.text(context), fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(height: 3),
                        Text(job.category, style: TextStyle(color: AC.textSec(context), fontSize: 12)),
                      ],
                    ),
                  ),
                  Text('KES ${job.budget.toStringAsFixed(0)}', style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 12),

              // Location + description
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(child: Text(job.location, style: TextStyle(color: AC.textSec(context), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.notes, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(child: Text(job.description, style: TextStyle(color: AC.textSec(context), fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis)),
                ],
              ),
              const SizedBox(height: 20),

              // Accept / Skip buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onSkip,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AC.textSec(context),
                        side: BorderSide(color: AC.div(context)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Skip', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: secondsLeft > 0 ? onAccept : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Accept Job', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
