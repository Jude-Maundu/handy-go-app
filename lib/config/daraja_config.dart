import 'package:flutter_dotenv/flutter_dotenv.dart';

class DarajaConfig {
  static String get consumerKey    => dotenv.env['DARAJA_CONSUMER_KEY']    ?? '';
  static String get consumerSecret => dotenv.env['DARAJA_CONSUMER_SECRET'] ?? '';
  static String get shortCode      => dotenv.env['DARAJA_SHORT_CODE']      ?? '174379';
  static String get passkey        => dotenv.env['DARAJA_PASSKEY']         ?? '';
  static String get baseUrl        => dotenv.env['DARAJA_BASE_URL']        ?? 'https://sandbox.safaricom.co.ke';
  static String get callbackUrl    => dotenv.env['DARAJA_CALLBACK_URL']    ?? '';
}
