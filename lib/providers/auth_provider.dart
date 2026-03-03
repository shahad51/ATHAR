import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';
// Debug logging enabled

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;
  bool _isFirstLogin = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;
  bool get isFirstLogin => _isFirstLogin;

  Future<void> initialize() async {
    debugPrint('🔵 [AuthProvider] Initializing...');
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _authService.getCurrentUserData();
      debugPrint(
          '🔵 [AuthProvider] Init complete. User: ${_currentUser?.userId}, Role: ${_currentUser?.role}');
    } catch (e) {
      debugPrint('🔵 [AuthProvider] Init error: $e');
      _error = e.toString();
    }

    _isLoading = false;
    debugPrint(
        '🔵 [AuthProvider] isLoading: $_isLoading, isLoggedIn: $isLoggedIn');
    notifyListeners();
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    debugPrint('🔵 [AuthProvider] Login starting for: $username');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.login(username, password);
      debugPrint(
          '🔵 [AuthProvider] Login result: ${result['success']}, error: ${result['error']}');

      if (result['success']) {
        _currentUser = result['user'] as UserModel;
        _isFirstLogin = true;
        _isLoading = false;
        debugPrint(
            '🔵 [AuthProvider] SUCCESS! User set: ${_currentUser?.userId}, Role: ${_currentUser?.role}');
        debugPrint('🔵 [AuthProvider] isLoggedIn: $isLoggedIn');
        notifyListeners();
      } else {
        _error = result['error'];
        _currentUser = null;
        _isLoading = false;
        debugPrint('🔵 [AuthProvider] FAILED! Error: $_error');
        notifyListeners();
      }

      return result;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      _currentUser = null;
      debugPrint('🔵 [AuthProvider] EXCEPTION: $e');
      notifyListeners();
      return {'success': false, 'error': 'login_failed'};
    }
  }

  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String mobile,
    required String username,
    required String password,
    required String accountType,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.register(
        firstName: firstName,
        lastName: lastName,
        mobile: mobile,
        username: username,
        password: password,
        accountType: accountType,
      );

      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return {'success': false, 'error': 'registration_failed'};
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _authService.logout();
    _currentUser = null;
    _isFirstLogin = false;

    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> sendPasswordResetOTP(String mobile) async {
    _isLoading = true;
    notifyListeners();

    final result = await _authService.sendPasswordResetOTP(mobile);

    _isLoading = false;
    notifyListeners();
    return result;
  }

  Future<Map<String, dynamic>> resetPassword(
      String userId, String newPassword) async {
    _isLoading = true;
    notifyListeners();

    final result = await _authService.resetPassword(userId, newPassword);

    _isLoading = false;
    notifyListeners();
    return result;
  }

  Future<Map<String, dynamic>> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    if (_currentUser == null) {
      return {'success': false, 'error': 'not_logged_in'};
    }

    _isLoading = true;
    notifyListeners();

    final result = await _authService.changePassword(
      _currentUser!.userId,
      currentPassword,
      newPassword,
    );

    _isLoading = false;
    notifyListeners();
    return result;
  }

  Future<void> updateUserInfo(Map<String, dynamic> data) async {
    if (_currentUser == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final firestoreService = FirestoreService();
      await firestoreService.updateUser(_currentUser!.userId, data);

      _currentUser = _currentUser!.copyWith(
        firstName: data['firstName'] ?? _currentUser!.firstName,
        lastName: data['lastName'] ?? _currentUser!.lastName,
        mobile: data['mobile'] ?? _currentUser!.mobile,
      );
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void setFirstLoginComplete() {
    _isFirstLogin = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
