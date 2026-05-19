import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../providers/location_provider.dart';
import '../../constants/map_constants.dart';
import 'fundi_marker.dart';

class LiveMap extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final bool showUserLocation;
  final bool interactive;
  final Function(LatLng)? onMapTap;
  final List<FundiMarker>? fundiMarkers;
  final LatLng? destination;

  const LiveMap({
    Key? key,
    this.initialLatitude,
    this.initialLongitude,
    this.showUserLocation = true,
    this.interactive = true,
    this.onMapTap,
    this.fundiMarkers,
    this.destination,
  }) : super(key: key);

  @override
  State<LiveMap> createState() => _LiveMapState();
}

class _LiveMapState extends State<LiveMap> {
  late MapController _mapController;
  final List<Marker> _markers = [];
  final List<Polyline> _polylines = [];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(
          widget.initialLatitude ?? MapConstants.defaultLatitude,
          widget.initialLongitude ?? MapConstants.defaultLongitude,
        ),
        initialZoom: MapConstants.defaultZoom,
        onTap: widget.interactive
            ? (tapPosition, point) {
                if (widget.onMapTap != null) widget.onMapTap!(point);
              }
            : null,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.handygo',
        ),
        MarkerLayer(markers: _markers),
        PolylineLayer(polylines: _polylines),
      ],
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.showUserLocation) {
      _centerOnUserLocation();
    }
    if (widget.fundiMarkers != null) {
      addFundiMarkers();
    }
  }

  Future<void> _centerOnUserLocation() async {
    final provider = Provider.of<LocationProvider>(context, listen: false);
    await provider.getCurrentLocation();

    if (provider.currentLocation != null) {
      _mapController.move(
        LatLng(
          provider.currentLocation!.latitude,
          provider.currentLocation!.longitude,
        ),
        15,
      );
    }
  }

  void addFundiMarkers() {
    if (widget.fundiMarkers != null) {
      for (var marker in widget.fundiMarkers!) {
        _markers.add(
          Marker(
            point: LatLng(marker.latitude, marker.longitude),
            width: 80,
            height: 80,
            child: Tooltip(
              message: '${marker.name} - Rating: ${marker.rating}',
              child: Icon(Icons.location_on, color: Colors.red, size: 40),
            ),
          ),
        );
      }
      setState(() {});
    }
  }

  void drawRoute(LatLng start, LatLng end) {
    _polylines.add(
      Polyline(points: [start, end], color: Colors.green, strokeWidth: 4),
    );
    setState(() {});
  }
}
