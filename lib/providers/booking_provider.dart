import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _bookings = [];
  bool _loading = false;

  List<Map<String, dynamic>> get bookings => _bookings;
  bool get loading => _loading;

  Stream<QuerySnapshot<Map<String, dynamic>>> streamBookings(String clientId) {
    return _db
        .collection('jobs')
        .where('clientId', isEqualTo: clientId)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots();
  }

  Future<void> fetchBookings(String clientId) async {
    _loading = true;
    notifyListeners();

    try {
      final snap = await _db
          .collection('jobs')
          .where('clientId', isEqualTo: clientId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      _bookings = snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
    } catch (_) {}

    _loading = false;
    notifyListeners();
  }

  Future<void> cancelBooking(String jobId) async {
    try {
      await _db.collection('jobs').doc(jobId).update({'status': 'cancelled'});
      _bookings = _bookings.map((b) {
        if (b['id'] == jobId) return {...b, 'status': 'cancelled'};
        return b;
      }).toList();
      notifyListeners();
    } catch (_) {}
  }
}
