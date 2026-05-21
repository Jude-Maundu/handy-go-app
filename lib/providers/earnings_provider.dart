import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EarningsProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  double _totalEarnings = 0;
  double _weeklyEarnings = 0;
  double _monthlyEarnings = 0;
  int _jobsCompleted = 0;
  List<Map<String, dynamic>> _transactions = [];
  bool _loading = false;

  double get totalEarnings => _totalEarnings;
  double get weeklyEarnings => _weeklyEarnings;
  double get monthlyEarnings => _monthlyEarnings;
  int get jobsCompleted => _jobsCompleted;
  List<Map<String, dynamic>> get transactions => _transactions;
  bool get loading => _loading;

  Future<void> fetchEarnings(String fundiId) async {
    _loading = true;
    notifyListeners();

    try {
      final snap = await _db
          .collection('jobs')
          .where('fundiId', isEqualTo: fundiId)
          .where('status', isEqualTo: 'completed')
          .get();

      final jobs = snap.docs.map((d) => d.data()).toList();
      _jobsCompleted = jobs.length;
      _totalEarnings =
          jobs.fold(0.0, (s, j) => s + ((j['budget'] as num?)?.toDouble() ?? 0));

      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      final monthAgo = now.subtract(const Duration(days: 30));

      _weeklyEarnings = jobs.where((j) {
        final ts = j['createdAt'];
        return ts is Timestamp && ts.toDate().isAfter(weekAgo);
      }).fold(0.0, (s, j) => s + ((j['budget'] as num?)?.toDouble() ?? 0));

      _monthlyEarnings = jobs.where((j) {
        final ts = j['createdAt'];
        return ts is Timestamp && ts.toDate().isAfter(monthAgo);
      }).fold(0.0, (s, j) => s + ((j['budget'] as num?)?.toDouble() ?? 0));

      _transactions = jobs.map((j) {
        DateTime? date;
        final ts = j['createdAt'];
        if (ts is Timestamp) date = ts.toDate();
        return {
          'title': j['title'] ?? '',
          'amount': (j['budget'] as num?)?.toDouble() ?? 0.0,
          'date': date,
          'jobId': j['id'] ?? '',
          'clientName': j['clientName'] ?? '',
          'paymentStatus': j['paymentStatus'] ?? 'none',
        };
      }).toList()
        ..sort((a, b) {
          final ta = (a['date'] as DateTime?) ?? DateTime(2000);
          final tb = (b['date'] as DateTime?) ?? DateTime(2000);
          return tb.compareTo(ta);
        });
    } catch (_) {}

    _loading = false;
    notifyListeners();
  }
}
