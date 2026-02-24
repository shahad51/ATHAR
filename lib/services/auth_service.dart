import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../core/utils/helpers.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username.trim())
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        final mobileQuery = await _firestore
            .collection('users')
            .where('mobile', isEqualTo: username.trim())
            .limit(1)
            .get();

        if (mobileQuery.docs.isEmpty) {
          await _logLoginAttempt('unknown', 'failure');
          return {'success': false, 'error': 'invalid_credentials'};
        }

        return _processLogin(mobileQuery.docs.first, password);
      }

      return _processLogin(querySnapshot.docs.first, password);
    } catch (e) {
      return {'success': false, 'error': 'invalid_credentials'};
    }
  }

  Future<Map<String, dynamic>> _processLogin(
    DocumentSnapshot userDoc,
    String password,
  ) async {
    final userData = userDoc.data() as Map<String, dynamic>;
    final user = UserModel.fromJson(userData);

    final passwordHash = userData['passwordHash'] ?? '';
    if (!Helpers.verifyPassword(password, passwordHash)) {
      await _logLoginAttempt(user.userId, 'failure');
      return {'success': false, 'error': 'invalid_credentials'};
    }

    if (user.activationStatus == ActivationStatus.pending) {
      await _logLoginAttempt(user.userId, 'failure');
      return {'success': false, 'error': 'account_pending'};
    }

    if (user.activationStatus == ActivationStatus.rejected) {
      await _logLoginAttempt(user.userId, 'failure');
      return {'success': false, 'error': 'account_rejected'};
    }

    try {
      final email = '${user.username}@athar.app';
      try {
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } catch (e) {
        try {
          await _auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
        } catch (_) {
          // User might exist, try signing in again
        }
      }
    } catch (_) {}

    await _logLoginAttempt(user.userId, 'success');
    await _saveUserSession(user);

    return {'success': true, 'user': user};
  }

  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String mobile,
    required String username,
    required String password,
    required String accountType,
  }) async {
    try {
      final usernameQuery = await _firestore
          .collection('users')
          .where('username', isEqualTo: username.trim())
          .limit(1)
          .get();

      if (usernameQuery.docs.isNotEmpty) {
        return {'success': false, 'error': 'username_exists'};
      }

      final mobileQuery = await _firestore
          .collection('users')
          .where('mobile', isEqualTo: mobile.trim())
          .limit(1)
          .get();

      if (mobileQuery.docs.isNotEmpty) {
        return {'success': false, 'error': 'mobile_exists'};
      }

      final userId = Helpers.generateId();
      final role = _parseAccountType(accountType);
      final activationStatus = role == UserRole.regular
          ? ActivationStatus.active
          : ActivationStatus.pending;

      final user = UserModel(
        userId: userId,
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        mobile: mobile.trim(),
        username: username.trim(),
        role: role,
        activationStatus: activationStatus,
        preferredLanguage: 'ar',
        createdAt: DateTime.now(),
        passwordHash: Helpers.hashPassword(password),
      );

      await _firestore.collection('users').doc(userId).set(user.toJson());

      if (role != UserRole.regular) {
        final requestId = Helpers.generateId();
        final request = ElevatedAccountRequest(
          requestId: requestId,
          userId: userId,
          requestedRole: role.name,
          status: RequestStatus.pending,
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection('elevatedAccountRequests')
            .doc(requestId)
            .set(request.toJson());
      }

      return {'success': true, 'user': user};
    } catch (e) {
      return {'success': false, 'error': 'registration_failed'};
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user_id');
      await prefs.remove('current_user_role');
    } catch (_) {}
  }

  Future<UserModel?> getCurrentUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('current_user_id');

      if (userId == null) return null;

      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;

      return UserModel.fromJson(doc.data()!);
    } catch (_) {
      return null;
    }
  }

  Future<void> updateUserFCMToken(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
      });
    } catch (_) {}
  }

  Future<Map<String, dynamic>> sendPasswordResetOTP(String mobile) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('mobile', isEqualTo: mobile.trim())
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return {'success': false, 'error': 'mobile_not_found'};
      }

      // TODO: Implement actual OTP sending via Firebase Phone Auth or SMS service
      // For now, return a mock OTP for testing
      return {'success': true, 'otp': '1234', 'userId': query.docs.first.id};
    } catch (e) {
      return {'success': false, 'error': 'otp_failed'};
    }
  }

  Future<Map<String, dynamic>> resetPassword(
    String userId,
    String newPassword,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'passwordHash': Helpers.hashPassword(newPassword),
      });

      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': 'reset_failed'};
    }
  }

  Future<Map<String, dynamic>> changePassword(
    String userId,
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) {
        return {'success': false, 'error': 'user_not_found'};
      }

      final userData = doc.data()!;
      final currentHash = userData['passwordHash'] ?? '';

      if (!Helpers.verifyPassword(currentPassword, currentHash)) {
        return {'success': false, 'error': 'invalid_current_password'};
      }

      await _firestore.collection('users').doc(userId).update({
        'passwordHash': Helpers.hashPassword(newPassword),
      });

      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': 'change_failed'};
    }
  }

  Future<void> _logLoginAttempt(String userId, String status) async {
    try {
      final logId = Helpers.generateId();
      final log = LoginLogModel(
        logId: logId,
        userId: userId,
        timestamp: DateTime.now(),
        status: status,
      );

      await _firestore.collection('loginLogs').doc(logId).set(log.toJson());
    } catch (_) {}
  }

  Future<void> _saveUserSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user_id', user.userId);
    await prefs.setString('current_user_role', user.role.name);
  }

  UserRole _parseAccountType(String type) {
    switch (type.toLowerCase()) {
      case 'admin':
      case 'administrator':
        return UserRole.admin;
      case 'employee':
        return UserRole.employee;
      default:
        return UserRole.regular;
    }
  }
}
