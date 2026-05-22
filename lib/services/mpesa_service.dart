import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/daraja_config.dart';

enum MpesaStatus { pending, success, cancelled, failed, timeout }

class MpesaResult {
  final MpesaStatus status;
  final String? checkoutRequestId;
  final String? message;
  const MpesaResult({required this.status, this.checkoutRequestId, this.message});
}

class MpesaService {
  // ── OAuth ──────────────────────────────────────────────────────────────────
  static Future<String?> _getToken() async {
    if (DarajaConfig.consumerKey.isEmpty || DarajaConfig.consumerSecret.isEmpty) {
      return null;
    }
    try {
      final creds = base64Encode(
          utf8.encode('${DarajaConfig.consumerKey}:${DarajaConfig.consumerSecret}'));
      final res = await http
          .get(
            Uri.parse(
                '${DarajaConfig.baseUrl}/oauth/v1/generate?grant_type=client_credentials'),
            headers: {'Authorization': 'Basic $creds'},
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        return jsonDecode(res.body)['access_token'] as String?;
      }
    } catch (_) {}
    return null;
  }

  // ── Build password (Base64 of shortcode + passkey + timestamp) ─────────────
  static String _password(String timestamp) {
    final raw =
        '${DarajaConfig.shortCode}${DarajaConfig.passkey}$timestamp';
    return base64Encode(utf8.encode(raw));
  }

  static String _timestamp() {
    final now = DateTime.now();
    return '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
  }

  // ── STK Push ───────────────────────────────────────────────────────────────
  /// Sends an M-Pesa STK push prompt to [phone] (format: 2547XXXXXXXX).
  /// Returns a [MpesaResult] with a CheckoutRequestID on success.
  static Future<MpesaResult> stkPush({
    required String phone,
    required int amount,
    required String jobId,
    required String description,
  }) async {
    if (DarajaConfig.passkey.isEmpty) {
      return const MpesaResult(
          status: MpesaStatus.failed, message: 'M-Pesa not configured — check .env credentials');
    }
    final token = await _getToken();
    if (token == null) {
      return const MpesaResult(
          status: MpesaStatus.failed,
          message: 'M-Pesa authentication failed — check consumer key & secret');
    }

    final ts = _timestamp();
    final body = {
      'BusinessShortCode': DarajaConfig.shortCode,
      'Password': _password(ts),
      'Timestamp': ts,
      'TransactionType': 'CustomerPayBillOnline',
      'Amount': amount,
      'PartyA': phone,
      'PartyB': DarajaConfig.shortCode,
      'PhoneNumber': phone,
      'CallBackURL': DarajaConfig.callbackUrl,
      'AccountReference': 'HandyGo-$jobId',
      'TransactionDesc': description,
    };

    try {
      final res = await http
          .post(
            Uri.parse('${DarajaConfig.baseUrl}/mpesa/stkpush/v1/processrequest'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && data['ResponseCode'] == '0') {
        return MpesaResult(
          status: MpesaStatus.pending,
          checkoutRequestId: data['CheckoutRequestID'] as String?,
          message: data['CustomerMessage'] as String?,
        );
      }
      final errMsg = data['errorMessage'] as String? ??
          data['ResponseDescription'] as String? ??
          'STK push failed (HTTP ${res.statusCode})';
      return MpesaResult(status: MpesaStatus.failed, message: errMsg);
    } catch (e) {
      return MpesaResult(status: MpesaStatus.failed, message: 'Network error: $e');
    }
  }

  // ── Single STK query (one attempt) ────────────────────────────────────────
  /// Returns [pending] if the transaction is still processing,
  /// [success], [cancelled], or [failed] when it resolves.
  static Future<MpesaStatus> queryOnce(String checkoutRequestId) async {
    final token = await _getToken();
    if (token == null) return MpesaStatus.pending;

    final ts = _timestamp();
    final body = {
      'BusinessShortCode': DarajaConfig.shortCode,
      'Password': _password(ts),
      'Timestamp': ts,
      'CheckoutRequestID': checkoutRequestId,
    };

    try {
      final res = await http.post(
        Uri.parse('${DarajaConfig.baseUrl}/mpesa/stkpushquery/v1/query'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final resultCode = data['ResultCode']?.toString();

      if (resultCode == '0') return MpesaStatus.success;
      if (resultCode == '1032') return MpesaStatus.cancelled; // user cancelled
      if (resultCode != null) return MpesaStatus.failed; // any other code = failed
    } catch (_) {}
    return MpesaStatus.pending; // network error or still processing
  }

  // ── STK Query (poll for completion) — kept for backward compat ────────────
  static Future<MpesaStatus> pollStatus({
    required String checkoutRequestId,
    int intervalSecs = 5,
    int maxAttempts = 12,
  }) async {
    for (int i = 0; i < maxAttempts; i++) {
      await Future.delayed(Duration(seconds: intervalSecs));
      final status = await queryOnce(checkoutRequestId);
      if (status != MpesaStatus.pending) return status;
    }
    return MpesaStatus.timeout;
  }
}
