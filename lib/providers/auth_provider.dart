import 'package:flutter/foundation.dart';

class AuthProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;
  String? _userEmail;

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;
  String? get userId => _userEmail;
  String? get userName => _userEmail?.split('@').first;

  Future<bool> signUp(String email, String password, String name, String surname) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1));
      
      if (email.isEmpty || !email.contains('@')) {
        _error = 'Please enter a valid email';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      if (password.length < 6) {
        _error = 'Password must be at least 6 characters';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _userEmail = email;
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'An error occurred. Please try again.';
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
      await Future.delayed(const Duration(seconds: 1));
      
      if (email.isEmpty || password.isEmpty) {
        _error = 'Please enter email and password';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _userEmail = email;
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'An error occurred. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      _isAuthenticated = false;
      _userEmail = null;
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Error signing out';
      _isLoading = false;
      notifyListeners();
    }
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
