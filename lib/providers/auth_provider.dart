import 'package:flutter/foundation.dart';

import '../features/auth/data/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({required AuthService authService}) : _authService = authService {
    checkAuth();
  }

  final AuthService _authService;

  bool _isLoggedIn = false;
  bool _isLoading = true;
  String? _error;

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> checkAuth() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _isLoggedIn = _authService.hasSession;
    } catch (_) {
      _isLoggedIn = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signInWithEmail(email: email, password: password);
      _isLoggedIn = true;
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoggedIn = false;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.signOut();
    } catch (_) {}
    _isLoggedIn = false;
    _isLoading = false;
    notifyListeners();
  }
}
