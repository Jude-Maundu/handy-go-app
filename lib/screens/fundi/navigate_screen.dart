import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/map_config.dart';
import '../../constants/app_colors.dart';
import '../../models/job_model.dart';
import '../../providers/location_provider.dart';
import '../../services/tomtom_service.dart';

class NavigateScreen extends StatefulWidget {
  final Job? job;
  const NavigateScreen({super.key, this.job});

  @override
  State<NavigateScreen> createState() => _NavigateScreenState();
}

class _NavigateScreenState extends State<NavigateScreen> {
  final _mapController = MapController();
  LatLng? _myPos;
  bool _following = true;
  List<LatLng> _routePoints = [];
  bool _routeLoading = false;

  bool get _hasJobCoords =>
      widget.job?.latitude != null && widget.job?.longitude != null;

  LatLng get _destPos => _hasJobCoords
      ? LatLng(widget.job!.latitude!, widget.job!.longitude!)
      : const LatLng(-1.286389, 36.817223);

  double get _distanceKm {
    if (_myPos == null || !_hasJobCoords) return 0;
    return Geolocator.distanceBetween(
          _myPos!.latitude, _myPos!.longitude,
          _destPos.latitude, _destPos.longitude,
        ) /
        1000;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loc = context.read<LocationProvider>();
      if (loc.hasLocation) {
        _myPos = LatLng(loc.latitude!, loc.longitude!);
        if (_hasJobCoords) _fetchRoute(_myPos!);
      }
      loc.addListener(_onLocationUpdate);
      loc.startTracking();
    });
  }

  Future<void> _fetchRoute(LatLng origin) async {
    if (!_hasJobCoords) return;
    setState(() => _routeLoading = true);
    final points = await TomTomService.getRoute(origin, _destPos);
    if (mounted) setState(() { _routePoints = points; _routeLoading = false; });
  }

  void _onLocationUpdate() {
    if (!mounted) return;
    final loc = context.read<LocationProvider>();
    if (!loc.hasLocation) return;
    final pos = LatLng(loc.latitude!, loc.longitude!);
    setState(() => _myPos = pos);
    if (_following) {
      _safeMoveMap(pos, null);
    }
  }

  void _safeMoveMap(LatLng center, double? zoom) {
    try {
      _mapController.move(center, zoom ?? _mapController.camera.zoom);
    } catch (_) {}
  }

  void _recenter() {
    setState(() => _following = true);
    if (_myPos != null) _safeMoveMap(_myPos!, 16);
  }

  Future<void> _openInMaps() async {
    final job = widget.job;
    Uri uri;
    if (_hasJobCoords) {
      uri = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=${_destPos.latitude},${_destPos.longitude}&travelmode=driving');
    } else if (job != null) {
      final encoded = Uri.encodeComponent(job.location);
      uri = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$encoded');
    } else {
      return;
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    context.read<LocationProvider>()
      ..removeListener(_onLocationUpdate)
      ..stopTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final green = const Color(0xFF4CAF50);
    final mapCenter = _myPos ?? _destPos;
    final dist = _distanceKm;
    final eta = dist > 0
        ? context.read<LocationProvider>().getETA(dist)
        : '—';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Map ────────────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: mapCenter,
              initialZoom: 16,
              onMapEvent: (event) {
                // Detect manual drag: disable auto-follow
                if (event is MapEventMoveStart &&
                    event.source == MapEventSource.dragStart) {
                  if (_following) setState(() => _following = false);
                }
              },
            ),
            children: [
              ...MapConfig.tileLayers(dark: true),

              // Real road route from TomTom
              if (_routePoints.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: green,
                      strokeWidth: 6,
                      borderColor: Colors.black26,
                      borderStrokeWidth: 2,
                    ),
                  ],
                )
              // Fallback straight line while route loads
              else if (_myPos != null && _hasJobCoords)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [_myPos!, _destPos],
                      color: green.withValues(alpha: 0.4),
                      strokeWidth: 3,
                      isDotted: true,
                    ),
                  ],
                ),

              // Markers
              MarkerLayer(
                markers: [
                  // Destination pin
                  if (_hasJobCoords)
                    Marker(
                      point: _destPos,
                      width: 48,
                      height: 56,
                      child: const Icon(Icons.location_pin,
                          color: Colors.red, size: 48),
                    ),
                  // My live position
                  if (_myPos != null)
                    Marker(
                      point: _myPos!,
                      width: 46,
                      height: 46,
                      child: Container(
                        decoration: BoxDecoration(
                          color: green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                                color: green.withValues(alpha: 0.4),
                                blurRadius: 10,
                                spreadRadius: 2),
                          ],
                        ),
                        child: const Icon(Icons.navigation,
                            color: Colors.black, size: 22),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // ── Top controls ───────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Row(
                children: [
                  _iconBtn(
                    Icons.arrow_back_ios_new,
                    () => Navigator.pop(context),
                    context,
                  ),
                  const Spacer(),
                  if (_routeLoading)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AC.surface(context).withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: green)),
                          const SizedBox(width: 8),
                          Text('Finding route…', style: TextStyle(color: AC.text(context), fontSize: 12)),
                        ],
                      ),
                    ),
                  if (!_following)
                    _iconBtn(
                      Icons.my_location,
                      _recenter,
                      context,
                      color: green,
                    ),
                ],
              ),
            ),
          ),

          // ── Destination label on map ────────────────────────────────────────
          if (job != null && _hasJobCoords)
            Positioned(
              top: 80,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        job.location,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Bottom panel ──────────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AC.surface(context),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, -4)),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                              color: AC.div(context),
                              borderRadius: BorderRadius.circular(2))),
                      const SizedBox(height: 16),

                      // Stats row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _stat(
                            Icons.straighten,
                            dist > 0
                                ? '${dist.toStringAsFixed(1)} km'
                                : 'Calculating…',
                            'Distance',
                            Colors.blue,
                            context,
                          ),
                          Container(
                              width: 1,
                              height: 40,
                              color: AC.div(context)),
                          _stat(
                            Icons.access_time_rounded,
                            eta,
                            'ETA',
                            Colors.orange,
                            context,
                          ),
                          Container(
                              width: 1,
                              height: 40,
                              color: AC.div(context)),
                          _stat(
                            Icons.payments_outlined,
                            job != null
                                ? 'KES ${job.budget.toStringAsFixed(0)}'
                                : '—',
                            'Earnings',
                            green,
                            context,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Job title
                      if (job != null)
                        Row(
                          children: [
                            const Icon(Icons.handyman_outlined,
                                size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                job.title,
                                style: TextStyle(
                                    color: AC.textSec(context), fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              'Client: ${job.clientName ?? "—"}',
                              style: TextStyle(
                                  color: AC.textSec(context), fontSize: 12),
                            ),
                          ],
                        ),
                      const SizedBox(height: 14),

                      // No-coords notice
                      if (!_hasJobCoords && widget.job != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: Colors.orange, size: 16),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'No GPS pin — tap Open in Maps to navigate by address.',
                                  style: TextStyle(color: Colors.orange, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Open in Maps + Arrived buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.map_outlined, size: 18),
                              label: const Text('Open in Maps',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              onPressed: _openInMaps,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: green,
                                side: BorderSide(color: green),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.check_circle_outline, size: 18),
                              label: const Text("Arrived",
                                  style: TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.w700)),
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: green,
                                foregroundColor: Colors.white,
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
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap, BuildContext context,
      {Color? color}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AC.surface(context).withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2), blurRadius: 6)
            ],
          ),
          child: Icon(icon, color: color ?? AC.text(context), size: 18),
        ),
      );

  Widget _stat(IconData icon, String value, String label, Color color,
          BuildContext context) =>
      Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: AC.text(context),
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
          Text(label,
              style: TextStyle(color: AC.textSec(context), fontSize: 10)),
        ],
      );
}
