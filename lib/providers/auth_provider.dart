import 'package:flutter/foundation.dart';
import '../services/firebase_service.dart';
import '../models/event.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;
  String? get userId => _firebaseService.currentUser?.uid;
  String? get userName => _firebaseService.currentUser?.email?.split('@').first;

  Future<bool> signUp(String email, String password, String name, String surname) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _firebaseService.signUp(email, password, name, surname);
      _isAuthenticated = user != null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseError(e.toString());
      _isLoading = false;
      notifyListeners();
      debugPrint('Sign up error: $e');
      return false;
    }
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _firebaseService.signIn(email, password);
      _isAuthenticated = user != null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseError(e.toString());
      _isLoading = false;
      notifyListeners();
      debugPrint('Sign in error: $e');
      return false;
    }
  }

  String _parseError(String error) {
    debugPrint('Parsing error: $error');
    if (error.contains('email-already-in-use')) {
      return 'This email is already registered';
    } else if (error.contains('weak-password')) {
      return 'Password should be at least 6 characters';
    } else if (error.contains('invalid-email')) {
      return 'Invalid email address';
    } else if (error.contains('user-not-found') || error.contains('wrong-password')) {
      return 'Invalid email or password';
    } else if (error.contains('network')) {
      return 'Network error. Check your connection.';
    }
    return error.length > 100 ? 'Error: ${error.substring(0, 100)}...' : error;
  }

  Future<void> signOut() async {
    await _firebaseService.signOut();
    _isAuthenticated = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
