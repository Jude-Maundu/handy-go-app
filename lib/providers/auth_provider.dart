import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? _firebaseUser;
  String? _userName;
  String? _phone;
  String? _role;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider() {
    _auth.authStateChanges().listen((user) async {
      _firebaseUser = user;
      if (user != null) {
        await _loadUserProfile(user.uid);
      } else {
        _userName = null;
        _phone = null;
        _role = null;
      }
      notifyListeners();
    });
  }

  bool get isLoggedIn => _firebaseUser != null;
  bool get isLoading => _isLoading;
  String? get currentUserId => _firebaseUser?.uid;
  String? get userEmail => _firebaseUser?.email;
  String? get userName => _userName;
  String? get phone => _phone;
  String? get role => _role;
  String? get errorMessage => _errorMessage;

  void setError(String msg) {
    _errorMessage = msg;
    notifyListeners();
  }

  Future<void> _loadUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _userName = data['name'] as String?;
        _phone = data['phone'] as String?;
        // Normalize to lowercase so 'Admin', 'ADMIN', 'admin' all work
        _role = (data['role'] as String?)?.toLowerCase().trim();
      }
    } catch (_) {}
  }

  Future<bool> checkAuthStatus({String? requiredRole}) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    if (_role == null) await _loadUserProfile(user.uid);
    // Admin can use either flavor — only block non-admin role mismatches
    if (requiredRole != null && _role != null && _role != requiredRole && _role != 'admin') {
      await _auth.signOut();
      _firebaseUser = null;
      _userName = null;
      _role = null;
      _phone = null;
      notifyListeners();
      return false;
    }
    return _auth.currentUser != null;
  }

  Future<bool> login({required String email, required String password, String? requiredRole}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      await _loadUserProfile(cred.user!.uid);

      // Admin can log in from either flavor — only block role mismatches for client/fundi
      if (requiredRole != null && _role != null && _role != requiredRole && _role != 'admin') {
        final wrongRole = _role!;
        await _auth.signOut();
        _firebaseUser = null;
        _userName = null;
        _role = null;
        _phone = null;
        _errorMessage = 'This account is registered as a ${wrongRole == 'client' ? 'Client' : 'Fundi'}. '
            'Please use the ${wrongRole == 'client' ? 'HandyGo Client' : 'HandyGo Fundi'} app.';
        return false;
      }
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _authMessage(e.code, e.message);
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithGoogle({required String requiredRole}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // User cancelled the picker
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final cred = await _auth.signInWithCredential(credential);
      final uid = cred.user!.uid;
      final isNew = cred.additionalUserInfo?.isNewUser ?? false;

      if (isNew) {
        // New user — create Firestore doc with role from this flavor
        await _db.collection('users').doc(uid).set({
          'name': cred.user!.displayName ?? googleUser.displayName ?? 'User',
          'email': cred.user!.email ?? '',
          'phone': '',
          'role': requiredRole,
          'rating': 0.0,
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
        });
        _role = requiredRole;
        _userName = cred.user!.displayName ?? googleUser.displayName ?? 'User';
        _phone = '';
      } else {
        await _loadUserProfile(uid);
        // Block if this account belongs to the other flavor
        if (_role != null && _role != requiredRole && _role != 'admin') {
          final wrongRole = _role!;
          await _auth.signOut();
          await GoogleSignIn().signOut();
          _firebaseUser = null;
          _userName = null;
          _role = null;
          _phone = null;
          _errorMessage = 'This account is registered as a ${wrongRole == 'client' ? 'Client' : 'Fundi'}. '
              'Please use the ${wrongRole == 'client' ? 'HandyGo Client' : 'HandyGo Fundi'} app.';
          return false;
        }
      }
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _authMessage(e.code, e.message);
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
    String? phone,
    String role = 'client',
    List<String> skills = const [],
    String? primarySkill,
    String? referredBy,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await cred.user!.updateDisplayName(name);
      await _db.collection('users').doc(cred.user!.uid).set({
        'name': name,
        'email': email,
        'phone': phone ?? '',
        'role': role,
        'rating': 0.0,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        if (skills.isNotEmpty) 'skills': skills,
        if (primarySkill != null) 'primarySkill': primarySkill,
        if (referredBy != null && referredBy.isNotEmpty) 'referredBy': referredBy,
      });
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _authMessage(e.code, e.message);
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _authMessage(e.code, e.message);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({required String name, String? phone}) async {
    if (_firebaseUser == null) return false;
    _isLoading = true;
    notifyListeners();

    try {
      await _firebaseUser!.updateDisplayName(name);
      await _db.collection('users').doc(_firebaseUser!.uid).update({
        'name': name,
        if (phone != null) 'phone': phone,
      });
      _userName = name;
      if (phone != null) _phone = phone;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _authMessage(String code, [String? detail]) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with that email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists with that email.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection. Check your network and try again.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled. Enable it in the Firebase Console under Authentication → Sign-in method.';
      default:
        return detail ?? 'Authentication error ($code). Please try again.';
    }
  }
}
