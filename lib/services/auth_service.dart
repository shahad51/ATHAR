import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../core/utils/helpers.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<Map<String, dynamic>> login(String username, String password) async {
    debugPrint('🔐 [AuthService] Login attempt for: $username');
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username.trim())
          .limit(1)
          .get();
      debugPrint(
          '🔐 [AuthService] Username query result: ${querySnapshot.docs.length} docs');

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
      debugPrint('🔐 [AuthService] Login error: $e');
      return {'success': false, 'error': 'invalid_credentials'};
    }
  }

  Future<Map<String, dynamic>> _processLogin(
    DocumentSnapshot userDoc,
    String password,
  ) async {
    debugPrint('🔐 [AuthService] Processing login...');
    final userData = userDoc.data() as Map<String, dynamic>;
    debugPrint('🔐 [AuthService] User data: $userData');
    final user = UserModel.fromJson(userData);
    debugPrint(
        '🔐 [AuthService] User role: ${user.role}, status: ${user.activationStatus}');

    final passwordHash = userData['passwordHash'] ?? '';
    final inputPasswordHash = Helpers.hashPassword(password);
    debugPrint('🔐 [AuthService] Stored hash: $passwordHash');
    debugPrint('🔐 [AuthService] Input hash:  $inputPasswordHash');
    debugPrint(
        '🔐 [AuthService] Hashes match: ${inputPasswordHash == passwordHash}');

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
      final authEmail = user.email != null && user.email!.isNotEmpty
          ? user.email!
          : '${user.username}@athar.app';
      try {
        await _auth.signInWithEmailAndPassword(
          email: authEmail,
          password: password,
        );
      } catch (e) {
        try {
          await _auth.createUserWithEmailAndPassword(
            email: authEmail,
            password: password,
          );
        } catch (_) {
          // User might exist, try signing in again
        }
      }

      // Check email verification for real emails
      if (user.email != null &&
          user.email!.isNotEmpty &&
          _auth.currentUser != null &&
          !_auth.currentUser!.emailVerified) {
        try {
          await _auth.currentUser!.sendEmailVerification();
          debugPrint('🔐 [AuthService] Resent verification email to: ${user.email}');
        } catch (e) {
          debugPrint('🔐 [AuthService] Failed to resend verification: $e');
        }
        await _auth.signOut();
        await _logLoginAttempt(user.userId, 'failure');
        return {'success': false, 'error': 'email_not_verified'};
      }
    } catch (_) {}

    await _logLoginAttempt(user.userId, 'success');
    await _saveUserSession(user);
    debugPrint(
        '🔐 [AuthService] Login successful! User: ${user.userId}, Role: ${user.role}');

    return {'success': true, 'user': user};
  }

  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String mobile,
    String? email,
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

      // Create Firebase Auth user first - use real email if provided, else generate one
      final authEmail = (email != null && email.trim().isNotEmpty)
          ? email.trim()
          : '${username.trim()}@athar.app';
      UserCredential? authResult;
      try {
        authResult = await _auth.createUserWithEmailAndPassword(
          email: authEmail,
          password: password,
        );
      } catch (e) {
        if (e.toString().contains('email-already-in-use')) {
          return {'success': false, 'error': 'username_exists'};
        }
        print('🔐 [AuthService] Firebase Auth user creation FAILED: $e');
        return {'success': false, 'error': 'registration_failed'};
      }

      // Use Firebase Auth UID as the user ID for consistency
      final userId = authResult.user?.uid ?? Helpers.generateId();
      debugPrint('🔐 [AuthService] Firebase Auth user created: $userId');

      final role = _parseAccountType(accountType);
      final activationStatus = ActivationStatus.active;

      final user = UserModel(
        userId: userId,
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        mobile: mobile.trim(),
        email: (email != null && email.trim().isNotEmpty) ? email.trim() : null,
        username: username.trim(),
        role: role,
        activationStatus: activationStatus,
        preferredLanguage: 'ar',
        createdAt: DateTime.now(),
        passwordHash: Helpers.hashPassword(password),
      );

      debugPrint('🔐 [AuthService] Creating Firestore user document...');
      try {
        final userJson = user.toJson();
        debugPrint('🔐 [AuthService] User JSON: $userJson');
        await _firestore.collection('users').doc(userId).set(userJson);
        debugPrint('🔐 [AuthService] Firestore user document created');
      } catch (firestoreError) {
        debugPrint('🔐 [AuthService] Firestore write FAILED: $firestoreError');
        // User exists in Auth but not Firestore - try to clean up
        try {
          await _auth.currentUser?.delete();
        } catch (_) {}
        rethrow;
      }

      // Send email verification if real email was used
      if (email != null && email.trim().isNotEmpty) {
        try {
          await _auth.currentUser?.sendEmailVerification();
          debugPrint('🔐 [AuthService] Email verification sent to: ${email.trim()}');
        } catch (e) {
          debugPrint('🔐 [AuthService] Failed to send verification email: $e');
        }
      }

      // Sign out after registration (user needs to login)
      debugPrint('🔐 [AuthService] Signing out after registration...');
      await _auth.signOut();
      debugPrint('🔐 [AuthService] Registration complete - SUCCESS');

      return {'success': true, 'user': user, 'email_verification_sent': email != null && email.trim().isNotEmpty};
    } catch (e) {
      debugPrint('🔐 [AuthService] Registration FAILED with error: $e');
      return {'success': false, 'error': 'registration_failed'};
    }
  }

  Future<Map<String, dynamic>> resendEmailVerification(String username) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username.trim())
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return {'success': false, 'error': 'user_not_found'};
      }

      final userData = querySnapshot.docs.first.data() as Map<String, dynamic>;
      final email = userData['email'] as String?;

      if (email == null || email.isEmpty) {
        return {'success': false, 'error': 'no_email'};
      }

      // Sign in temporarily to send verification
      final passwordHash = userData['passwordHash'] ?? '';
      // We can't sign in without password, so this is limited
      return {'success': false, 'error': 'login_required'};
    } catch (e) {
      return {'success': false, 'error': 'resend_failed'};
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
