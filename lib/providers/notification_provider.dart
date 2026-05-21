import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  int _unreadCount = 0;
  String? _watchedUserId;

  int get unreadCount => _unreadCount;

  /// Start listening to unread count for [userId].
  void watchUser(String userId) {
    if (_watchedUserId == userId) return;
    _watchedUserId = userId;
    _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .listen((snap) {
      _unreadCount = snap.docs.length;
      notifyListeners();
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> stream(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots();
  }

  Future<void> markRead(String notifId) async {
    try {
      await _db.collection('notifications').doc(notifId).update({'read': true});
    } catch (_) {}
  }

  Future<void> markAllRead(String userId) async {
    try {
      final snap = await _db
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();
      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
      _unreadCount = 0;
      notifyListeners();
    } catch (_) {}
  }
}
