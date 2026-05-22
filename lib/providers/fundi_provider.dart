import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FundiProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _fundis = [];
  bool _loading = false;
  String? _error;

  List<Map<String, dynamic>> get fundis => _fundis;
  bool get loading => _loading;
  String? get error => _error;

  /// Fetch fundis from Firestore, sorted by score = rating / (distanceKm + 1).
  /// Pass [clientLat]/[clientLng] to enable distance-based sorting.
  Future<void> fetchNearbyFundis({
    String? skill,
    double? clientLat,
    double? clientLng,
    double radiusKm = 30.0,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      Query<Map<String, dynamic>> q =
          _db.collection('users').where('role', isEqualTo: 'fundi');
      if (skill != null && skill != 'All') {
        q = q.where('skills', arrayContains: skill);
      }
      final snap = await q.get();

      var list = snap.docs.map((d) {
        final data = d.data();
        final lat = (data['latitude'] as num?)?.toDouble();
        final lng = (data['longitude'] as num?)?.toDouble();
        double? dist;
        if (clientLat != null && clientLng != null && lat != null && lng != null) {
          dist = _haversine(clientLat, clientLng, lat, lng);
        }
        return {
          'uid': d.id,
          'name': data['name'] ?? '',
          'email': data['email'] ?? '',
          'rating': (data['rating'] as num?)?.toDouble() ?? 0.0,
          'ratingCount': (data['ratingCount'] as num?)?.toInt() ?? 0,
          'skills': (data['skills'] as List?)?.cast<String>() ?? <String>[],
          'primarySkill': data['primarySkill'] ?? '',
          'status': data['status'] ?? 'active',
          'jobsCompleted': (data['jobsCompleted'] as num?)?.toInt() ?? 0,
          'latitude': lat,
          'longitude': lng,
          'distanceKm': dist,
        };
      }).toList();

      // Filter by radius when location is available
      if (clientLat != null && clientLng != null) {
        list = list.where((f) {
          final d = f['distanceKm'] as double?;
          return d == null || d <= radiusKm;
        }).toList();
      }

      // score = rating / (distance + 1) so closest + highest-rated comes first
      list.sort((a, b) {
        final dA = (a['distanceKm'] as double?) ?? 999.0;
        final dB = (b['distanceKm'] as double?) ?? 999.0;
        final rA = a['rating'] as double;
        final rB = b['rating'] as double;
        final scoreA = rA / (dA + 1);
        final scoreB = rB / (dB + 1);
        return scoreB.compareTo(scoreA);
      });

      _fundis = list;
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> getFundiProfile(String fundiId) async {
    try {
      final doc = await _db.collection('users').doc(fundiId).get();
      if (!doc.exists) return null;
      final data = doc.data()!;
      return {
        'uid': doc.id,
        ...data,
        'rating': (data['rating'] as num?)?.toDouble() ?? 0.0,
        'ratingCount': (data['ratingCount'] as num?)?.toInt() ?? 0,
        'jobsCompleted': (data['jobsCompleted'] as num?)?.toInt() ?? 0,
        'skills': (data['skills'] as List?)?.cast<String>() ?? <String>[],
      };
    } catch (_) {
      return null;
    }
  }

  /// Update fundi's last-known location in Firestore (called when going online).
  Future<void> updateFundiLocation(String fundiId, double lat, double lng) async {
    try {
      await _db.collection('users').doc(fundiId).update({
        'latitude': lat,
        'longitude': lng,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  /// Persist fundi's online/offline status to Firestore so clients can see it.
  Future<void> setOnlineStatus(String fundiId, bool isOnline) async {
    try {
      await _db.collection('users').doc(fundiId).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  double _haversine(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
            sin(dLng / 2) * sin(dLng / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }
}
