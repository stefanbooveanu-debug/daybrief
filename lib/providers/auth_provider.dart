import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/firebase_service.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['https://www.googleapis.com/auth/calendar.events'],
  );
  
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;
  String? _userEmail;
  String? _userName;
  bool _isDemoMode = false;

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated || _isDemoMode;
  String? get userId => _userEmail ?? (_isDemoMode ? 'demo-user' : null);
  String? get userName => _userName ?? (_isDemoMode ? 'Demo User' : null);
  bool get isDemoMode => _isDemoMode;

  void enableDemoMode() {
    _isDemoMode = true;
    _isAuthenticated = true;
    _userEmail = 'demo@example.com';
    _userName = 'Demo User';
    notifyListeners();
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      if (userCredential.user != null) {
        _userEmail = userCredential.user!.email;
        _userName = userCredential.user!.displayName;
        _isAuthenticated = true;
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Google sign in failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  AuthProvider() {
    _checkCurrentUser();
  }

  void _checkCurrentUser() {
    final user = _firebaseService.currentUser;
    if (user != null) {
      _userEmail = user.email;
      _isAuthenticated = true;
      notifyListeners();
    }
  }

  Future<bool> signUp(String email, String password, String name, String surname) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _firebaseService.signUp(email, password, name, surname);
      
      if (user != null) {
        _userEmail = user.email;
        _userName = name;
        _isAuthenticated = true;
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _firebaseService.signIn(email, password);
      
      if (user != null) {
        _userEmail = user.email;
        _isAuthenticated = true;
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _firebaseService.signOut();
      
      _isAuthenticated = false;
      _userEmail = null;
      _userName = null;
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Error signing out';
      _isLoading = false;
      notifyListeners();
    }
  }

  String _getErrorMessage(dynamic e) {
    if (e is FirebaseAuthException) {
      debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'user-not-found':
          return 'No account found with this email';
        case 'wrong-password':
          return 'Incorrect password';
        case 'email-already-in-use':
          return 'This email is already registered';
        case 'invalid-email':
          return 'Please enter a valid email';
        case 'weak-password':
          return 'Password is too weak';
        case 'INVALID_LOGIN_CREDENTIALS':
        case 'invalid-credential':
          return 'Invalid email or password';
        case 'ERROR_INVALID_EMAIL':
          return 'Invalid email address';
        case 'ERROR_WRONG_PASSWORD':
          return 'Incorrect password';
        case 'ERROR_USER_NOT_FOUND':
          return 'No account found';
        default:
          return 'Error: ${e.code}';
      }
    }
    debugPrint('General Error: $e');
    return 'Error: $e';
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _error = null;
    super.dispose();
  }
}
