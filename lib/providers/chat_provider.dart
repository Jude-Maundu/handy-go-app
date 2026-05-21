import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _sending = false;
  bool get sending => _sending;

  String _chatDocId(String jobId) => 'job_$jobId';

  Stream<QuerySnapshot<Map<String, dynamic>>> messagesStream(String jobId) {
    return _db
        .collection('chats')
        .doc(_chatDocId(jobId))
        .collection('messages')
        .orderBy('createdAt')
        .snapshots();
  }

  Future<bool> sendMessage({
    required String jobId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    if (text.trim().isEmpty) return false;
    _sending = true;
    notifyListeners();

    try {
      final chatRef = _db.collection('chats').doc(_chatDocId(jobId));
      final msgRef = chatRef.collection('messages').doc();
      final batch = _db.batch();

      batch.set(msgRef, {
        'senderId': senderId,
        'senderName': senderName,
        'text': text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      batch.set(
        chatRef,
        {
          'jobId': jobId,
          'lastMessage': text.trim(),
          'lastSenderId': senderId,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await batch.commit();
      return true;
    } catch (_) {
      return false;
    } finally {
      _sending = false;
      notifyListeners();
    }
  }

  Future<int> unreadCount(String jobId, String userId) async {
    try {
      final snap = await _db
          .collection('chats')
          .doc(_chatDocId(jobId))
          .collection('messages')
          .where('senderId', isNotEqualTo: userId)
          .get();
      return snap.docs.length;
    } catch (_) {
      return 0;
    }
  }
}
