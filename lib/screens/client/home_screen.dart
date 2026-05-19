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
import '../../services/notification_service.dart';
import '../../models/job_model.dart';
import 'bookings_screen.dart';
import 'search_screen.dart';
import 'booking_details.dart';
import '../sharedscreens/profile_screen.dart';
import '../sharedscreens/app_drawer.dart';

class ClientMainScreen extends StatefulWidget {
  const ClientMainScreen({super.key});

  @override
  State<ClientMainScreen> createState() => _ClientMainScreenState();
}

class _ClientMainScreenState extends State<ClientMainScreen> {
  int _selectedIndex = 0;
  DateTime? _lastBackPress;

  late final List<Widget> _tabs = [
    const _ClientHomeTab(),
    const ClientSearchScreen(),
    const ClientBookingsScreen(),
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
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: color),
            label: 'Home',
          ),
          NavigationDestination(
            icon: const Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search, color: color),
            label: 'Search',
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long, color: color),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: color),
            label: 'Profile',
          ),
        ],
      ),
      ),
    );
  }
}

class _ClientHomeTab extends StatefulWidget {
  const _ClientHomeTab();

  @override
  State<_ClientHomeTab> createState() => _ClientHomeTabState();
}

class _ClientHomeTabState extends State<_ClientHomeTab> {
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  final _mapController = MapController();

  static const List<Map<String, dynamic>> _categories = [
    {'name': 'Plumbing', 'icon': Icons.plumbing},
    {'name': 'Electrical', 'icon': Icons.electrical_services},
    {'name': 'Painting', 'icon': Icons.format_paint},
    {'name': 'Cleaning', 'icon': Icons.cleaning_services},
    {'name': 'Carpentry', 'icon': Icons.carpenter},
    {'name': 'Gardening', 'icon': Icons.grass},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JobProvider>().fetchJobs(refresh: true);
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
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final location = context.watch<LocationProvider>();
    final accent = FlavorConfig.instance.primaryColor;
    final center = location.hasLocation
        ? LatLng(location.latitude!, location.longitude!)
        : const LatLng(-1.286389, 36.817223);

    return Scaffold(
      backgroundColor: AC.bg(context),
      body: Stack(
        children: [
          // Full-screen dark map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: center, initialZoom: 15),
            children: [
              ...MapConfig.tileLayers(dark: Theme.of(context).brightness == Brightness.dark),
              if (location.hasLocation)
                MarkerLayer(markers: [
                  Marker(
                    point: center,
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(color: accent, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
                      child: const Icon(Icons.person, color: Colors.black, size: 20),
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
                  _TopButton(
                    icon: Icons.menu,
                    onTap: () => Scaffold.of(context).openDrawer(),
                  ),
                  const Spacer(),
                  Column(
                    children: [
                      Text(
                        location.currentCity ?? 'Nairobi',
                        style: TextStyle(color: AC.text(context), fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        location.currentAddress?.split(',').first ?? 'Getting location...',
                        style: TextStyle(color: AC.textSec(context), fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  const Spacer(),
                  _TopButton(
                    icon: Icons.notifications_outlined,
                    onTap: () => Navigator.pushNamed(context, '/notifications'),
                  ),
                ],
              ),
            ),
          ),

          // Bottom draggable sheet
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.42,
            minChildSize: 0.42,
            maxChildSize: 0.88,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: AC.surface(context),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    const SizedBox(height: 10),
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(color: AC.div(context), borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Greeting
                    Text(
                      'Hello, ${auth.userName?.split(' ').first ?? 'there'} 👋',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    const Text('Where do you need help?', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 16),

                    // Search field
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/search'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(color: AC.input(context), borderRadius: BorderRadius.circular(14)),
                        child: const Row(
                          children: [
                            Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                            SizedBox(width: 10),
                            Text('Search for a service...', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Location rows
                    _LocationRow(
                      icon: Icons.circle, iconColor: accent, iconSize: 10,
                      label: location.currentAddress?.split(',').first ?? 'Current location',
                    ),
                    const SizedBox(height: 1),
                    _LocationRow(
                      icon: Icons.location_on, iconColor: Colors.grey,
                      label: 'Where to?',
                      onTap: () => Navigator.pushNamed(context, '/request-fundi'),
                    ),
                    const SizedBox(height: 16),

                    // Promo banner
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                      child: Row(
                        children: [
                          Icon(Icons.local_offer, color: accent, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Get KES 200 off', style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 14)),
                                const Text('Invite a friend and earn a bonus for each one!', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Categories
                    const Text('What do you need?', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.1,
                      children: _categories.map((cat) => _CategoryTile(
                        icon: cat['icon'] as IconData,
                        label: cat['name'] as String,
                        accent: accent,
                        onTap: () {
                          context.read<JobProvider>().setCategory(cat['name'] as String);
                          Navigator.pushNamed(context, '/search');
                        },
                      )).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Nearby fundis
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Nearby Fundis', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/search'),
                          child: Text('See all', style: TextStyle(color: accent, fontSize: 13)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Consumer<JobProvider>(
                      builder: (context, jobs, _) {
                        if (jobs.isJobsLoading) {
                          return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                        }
                        if (jobs.jobsList.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(child: Text('No fundis available right now.', style: TextStyle(color: AppColors.textSecondary))),
                          );
                        }
                        return Column(
                          children: jobs.jobsList.take(4).map((job) => _FundiCard(job: job, accent: accent)).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TopButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _TopButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(color: AC.surface(context).withValues(alpha: 0.9), shape: BoxShape.circle),
        child: Icon(icon, color: AppColors.textPrimary, size: 20),
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final double iconSize;
  final String label;
  final VoidCallback? onTap;
  const _LocationRow({required this.icon, required this.iconColor, this.iconSize = 20, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: AC.input(context), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: iconSize),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: onTap != null ? AppColors.textSecondary : AppColors.textPrimary, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onTap != null) const Icon(Icons.home_outlined, color: AppColors.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;
  const _CategoryTile({required this.icon, required this.label, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: AC.input(context), borderRadius: BorderRadius.circular(14)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: accent, size: 26),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: AC.text(context), fontSize: 11, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _FundiCard extends StatelessWidget {
  final Job job;
  final Color accent;
  const _FundiCard({required this.job, required this.accent});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookingDetailsScreen(jobId: job.id))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AC.card(context), borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.home_repair_service, color: accent, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(job.fundiName ?? job.title, style: TextStyle(color: AC.text(context), fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 3),
                  Text(job.category, style: TextStyle(color: AC.textSec(context), fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 13),
                      const SizedBox(width: 3),
                      Text(
                        job.fundiRating != null ? job.fundiRating!.toStringAsFixed(1) : '4.5',
                        style: TextStyle(color: AC.textSec(context), fontSize: 12),
                      ),
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
                    ],
                  ),
                ],
              ),
            ),
            Text(
              'KES ${job.budget.toStringAsFixed(0)}',
              style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
