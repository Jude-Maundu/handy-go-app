import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool notifications = true;
  bool locationAccess = true;
  bool emailUpdates = false;
  bool soundEffects = true;
  String language = 'English';

  bool _loading = false;
  bool get loading => _loading;

  Future<void> load(String userId) async {
    _loading = true;
    notifyListeners();
    try {
      final doc =
          await _db.collection('userSettings').doc(userId).get();
      if (doc.exists) {
        final d = doc.data()!;
        notifications = d['notifications'] as bool? ?? true;
        locationAccess = d['locationAccess'] as bool? ?? true;
        emailUpdates = d['emailUpdates'] as bool? ?? false;
        soundEffects = d['soundEffects'] as bool? ?? true;
        language = d['language'] as String? ?? 'English';
      }
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  Future<void> save(String userId) async {
    try {
      await _db.collection('userSettings').doc(userId).set({
        'notifications': notifications,
        'locationAccess': locationAccess,
        'emailUpdates': emailUpdates,
        'soundEffects': soundEffects,
        'language': language,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  void toggle(String key, bool value, String userId) {
    switch (key) {
      case 'notifications':
        notifications = value;
      case 'locationAccess':
        locationAccess = value;
      case 'emailUpdates':
        emailUpdates = value;
      case 'soundEffects':
        soundEffects = value;
    }
    notifyListeners();
    save(userId);
  }

  void setLanguage(String lang, String userId) {
    language = lang;
    notifyListeners();
    save(userId);
  }
}
