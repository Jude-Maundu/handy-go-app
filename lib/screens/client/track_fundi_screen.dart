import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:handygo/providers/location_provider.dart';
import 'package:handygo/providers/job_provider.dart';
import 'package:handygo/models/job_model.dart';
import 'package:handygo/widgets/live_map.dart';
import 'package:handygo/widgets/fundi_marker.dart';

class TrackFundiScreen extends StatelessWidget {
  final String jobId;

  const TrackFundiScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context) {
    final jobs = context.read<JobProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracking Your Fundi'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<Job?>(
        stream: jobs.streamJobById(jobId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }
          final job = snap.data;
          if (job == null) {
            return const Center(child: Text('Job not found'));
          }

          final fundiLat = job.fundiLatitude ?? job.latitude ?? 0.0;
          final fundiLng = job.fundiLongitude ?? job.longitude ?? 0.0;
          final locationProvider = context.watch<LocationProvider>();

          return Column(
            children: [
              Expanded(
                flex: 3,
                child: LiveMap(
                  showUserLocation: true,
                  fundiMarkers: [
                    FundiMarker(
                      id: job.fundiId ?? 'unknown',
                      name: job.fundiName ?? 'Fundi',
                      latitude: fundiLat,
                      longitude: fundiLng,
                      rating: job.fundiRating?.toStringAsFixed(1),
                    ),
                  ],
                  destination: LatLng(
                    job.destinationLatitude,
                    job.destinationLongitude,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Fundi: ${job.fundiName ?? 'Fundi'}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 20),
                              const SizedBox(width: 4),
                              Text(job.fundiRating?.toStringAsFixed(1) ?? '0.0'),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.timer, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(
                            'ETA: ${locationProvider.getETA(job.distanceToFundi)}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: job.progress.clamp(0.0, 1.0),
                        backgroundColor: Colors.grey[300],
                        color: Colors.green,
                        minHeight: 8,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        job.statusText,
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
