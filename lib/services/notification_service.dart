import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

// Top-level handler required by firebase_messaging for background messages
@pragma('vm:entry-point')
Future<void> _backgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background: ${message.notification?.title}');
}

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _db = FirebaseFirestore.instance;

  static String get _serverUrl =>
      dotenv.env['RENDER_SERVER_URL'] ?? 'https://handy-go-server.onrender.com';

  // ── Call this once from each main screen after the user is logged in ─────────
  static Future<void> init(String userId) async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_backgroundHandler);

    // Request permission (required on iOS and Android 13+)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Save token to Firestore
    final token = await _messaging.getToken();
    if (token != null) await _saveToken(userId, token);

    // Keep token fresh
    _messaging.onTokenRefresh.listen((t) => _saveToken(userId, t));

    // Show a SnackBar when a notification arrives while the app is open
    // (background/terminated are handled by the OS automatically)
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;
      // Store the latest message so widgets can display it via a GlobalKey
      _onMessageCallback?.call(notification);
    });
  }

  // Simple callback so UI layers can react to foreground messages
  static void Function(RemoteNotification)? _onMessageCallback;
  static void setForegroundListener(void Function(RemoteNotification) cb) {
    _onMessageCallback = cb;
  }

  // ── Save / remove FCM token ──────────────────────────────────────────────────
  static Future<void> _saveToken(String userId, String token) async {
    try {
      await _db.collection('users').doc(userId).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
      });
    } catch (_) {}
  }

  static Future<void> removeToken(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;
      await _db.collection('users').doc(userId).update({
        'fcmTokens': FieldValue.arrayRemove([token]),
      });
      await _messaging.deleteToken();
    } catch (_) {}
  }

  // ── Send notifications via Render server ─────────────────────────────────────

  /// Notify all fundis about a new job request
  static Future<void> notifyFundis({
    required String jobTitle,
    required String jobId,
    required String category,
    required String location,
  }) async {
    try {
      await http.post(
        Uri.parse('$_serverUrl/notify-fundis'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': '🔧 New $category Job!',
          'body': '$jobTitle · $location',
          'data': {'jobId': jobId, 'type': 'new_job'},
        }),
      );
    } catch (_) {}
  }

  /// Notify the client that a fundi has accepted their job
  static Future<void> notifyClient({
    required String clientId,
    required String fundiName,
    required String jobId,
    required String jobTitle,
  }) async {
    try {
      await http.post(
        Uri.parse('$_serverUrl/notify-client'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'clientId': clientId,
          'title': '✅ Fundi Found!',
          'body': '$fundiName is on the way · $jobTitle',
          'data': {'jobId': jobId, 'type': 'job_accepted'},
        }),
      );
    } catch (_) {}
  }
}
