import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _history = [];
  double _totalSpent = 0;
  bool _loading = false;

  List<Map<String, dynamic>> get history => _history;
  double get totalSpent => _totalSpent;
  bool get loading => _loading;

  Future<void> fetchPaymentHistory(String clientId) async {
    _loading = true;
    notifyListeners();

    try {
      final snap = await _db
          .collection('jobs')
          .where('clientId', isEqualTo: clientId)
          .where('status', isEqualTo: 'completed')
          .get();

      final jobs = snap.docs.map((d) => d.data()).toList()
        ..sort((a, b) {
          final ta =
              (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
          final tb =
              (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
          return tb.compareTo(ta);
        });

      _totalSpent = jobs.fold(
          0.0, (s, j) => s + ((j['budget'] as num?)?.toDouble() ?? 0));

      _history = jobs.map((j) {
        DateTime? date;
        final ts = j['createdAt'];
        if (ts is Timestamp) date = ts.toDate();
        return {
          'title': j['title'] ?? '',
          'amount': (j['budget'] as num?)?.toDouble() ?? 0.0,
          'date': date,
          'fundiName': j['fundiName'] ?? '',
          'jobId': j['id'] ?? '',
          'paymentStatus': j['paymentStatus'] ?? 'none',
          'category': j['category'] ?? '',
        };
      }).toList();
    } catch (_) {}

    _loading = false;
    notifyListeners();
  }
}
