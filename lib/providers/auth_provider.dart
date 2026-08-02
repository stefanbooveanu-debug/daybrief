import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../repositories/auth_repository.dart';
import '../utils/async_value.dart';

class AuthProvider with ChangeNotifier {
  AuthProvider(this._repository) {
    _authSubscription = _repository.authStateChanges.listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  final AuthRepository _repository;
  StreamSubscription<User?>? _authSubscription;

  AsyncValue<void> _state = const AsyncIdle();
  bool _isDemoMode = false;
  User? _user;

  AsyncValue<void> get state => _state;
  bool get isLoading => _state is AsyncLoading<void>;
  String? get error => switch (_state) {
        AsyncError(:final error) => error.toString(),
        _ => null,
      };
  bool get isAuthenticated => _user != null || _isDemoMode;
  bool get isDemoMode => _isDemoMode;
  String? get userId => _user?.uid ?? (_isDemoMode ? 'demo_user' : null);
  String? get userName {
    if (_isDemoMode) return 'Demo User';
    if (_user == null) return null;
    return _user!.displayName ?? _user!.email?.split('@').first;
  }

  String? get userEmail => _user?.email;

  Future<bool> signUp(
    String email,
    String password,
    String name,
    String surname,
  ) async {
    _state = const AsyncLoading();
    notifyListeners();

    try {
      final credential = await _repository.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user != null) {
        await _repository.updateDisplayName(
          credential.user!,
          '$name $surname',
        );
        await _repository.saveUserProfile(
          uid: credential.user!.uid,
          name: name,
          surname: surname,
          email: email.trim(),
        );
      }

      _user = credential.user;
      _state = const AsyncData(null);
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _state = AsyncError<void>(_getErrorMessage(e.code));
      notifyListeners();
      return false;
    } catch (e) {
      _state = AsyncError<void>('An unexpected error occurred: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn(String email, String password) async {
    _state = const AsyncLoading();
    notifyListeners();

    try {
      final credential = await _repository.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      _user = credential.user;
      _state = const AsyncData(null);
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _state = AsyncError<void>(_getErrorMessage(e.code));
      notifyListeners();
      return false;
    } catch (e) {
      _state = AsyncError<void>('An unexpected error occurred: $e');
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _repository.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
    _isDemoMode = false;
    _user = null;
    notifyListeners();
  }

  Future<void> signInDemo() async {
    _isDemoMode = true;
    notifyListeners();
  }

  void clearError() {
    if (_state is AsyncError<void>) {
      _state = const AsyncIdle();
      notifyListeners();
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'Password is too weak (min 6 characters)';
      case 'email-already-in-use':
        return 'Email already registered';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-credential':
        return 'Invalid email or password';
      case 'too-many-requests':
        return 'Too many attempts. Try again later';
      case 'network-request-failed':
        return 'Network error. Check your connection';
      default:
        return 'Authentication error: $code';
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
