import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:athar_app/models/user_model.dart';

void main() {
  group('UserModel', () {
    final testUser = UserModel(
      userId: 'user_001',
      firstName: 'Ahmed',
      lastName: 'Ali',
      mobile: '+966501234567',
      username: 'ahmed_ali',
      role: UserRole.employee,
      activationStatus: ActivationStatus.pending,
      preferredLanguage: 'ar',
      createdAt: DateTime(2025, 1, 15),
      fcmToken: 'fcm_token_123',
      passwordHash: 'hash_abc',
    );

    test('fullName returns first + last name', () {
      expect(testUser.fullName, 'Ahmed Ali');
    });

    test('fromJson parses all fields correctly', () {
      final json = {
        'userId': 'user_002',
        'firstName': 'Sara',
        'lastName': 'Khan',
        'mobile': '+966509876543',
        'username': 'sara_khan',
        'role': 'admin',
        'activationStatus': 'active',
        'preferredLanguage': 'en',
        'createdAt': Timestamp.fromDate(DateTime(2025, 2, 1)),
        'fcmToken': null,
        'passwordHash': null,
      };

      final user = UserModel.fromJson(json);

      expect(user.userId, 'user_002');
      expect(user.firstName, 'Sara');
      expect(user.lastName, 'Khan');
      expect(user.mobile, '+966509876543');
      expect(user.username, 'sara_khan');
      expect(user.role, UserRole.admin);
      expect(user.activationStatus, ActivationStatus.active);
      expect(user.preferredLanguage, 'en');
      expect(user.fcmToken, isNull);
      expect(user.passwordHash, isNull);
    });

    test('fromJson handles missing fields with defaults', () {
      final json = {
        'userId': '',
        'firstName': '',
        'lastName': '',
        'mobile': '',
        'username': '',
        'role': 'unknown',
        'activationStatus': 'unknown',
      };

      final user = UserModel.fromJson(json);

      expect(user.role, UserRole.regular); // default
      expect(user.activationStatus, ActivationStatus.active); // default
      expect(user.preferredLanguage, 'ar'); // default
    });

    test('toJson serializes all fields correctly', () {
      final json = testUser.toJson();

      expect(json['userId'], 'user_001');
      expect(json['firstName'], 'Ahmed');
      expect(json['role'], 'employee');
      expect(json['activationStatus'], 'pending');
      expect(json['preferredLanguage'], 'ar');
      expect(json['fcmToken'], 'fcm_token_123');
      expect(json['createdAt'], isA<Timestamp>());
    });

    test('copyWith updates only specified fields', () {
      final updated = testUser.copyWith(
        firstName: 'Mohamed',
        activationStatus: ActivationStatus.active,
      );

      expect(updated.firstName, 'Mohamed');
      expect(updated.activationStatus, ActivationStatus.active);
      expect(updated.lastName, 'Ali'); // unchanged
      expect(updated.userId, 'user_001'); // unchanged
    });

    group('UserRole parsing', () {
      test('parses employee correctly', () {
        expect(UserModel.fromJson({'role': 'employee'}).role, UserRole.employee);
      });
      test('parses admin correctly', () {
        expect(UserModel.fromJson({'role': 'admin'}).role, UserRole.admin);
      });
      test('parses manager correctly', () {
        expect(UserModel.fromJson({'role': 'manager'}).role, UserRole.manager);
      });
      test('defaults to regular for unknown', () {
        expect(UserModel.fromJson({'role': 'superuser'}).role, UserRole.regular);
      });
      test('defaults to regular for null', () {
        expect(UserModel.fromJson({'role': null}).role, UserRole.regular);
      });
    });

    group('ActivationStatus parsing', () {
      test('parses pending correctly', () {
        expect(
          UserModel.fromJson({'activationStatus': 'pending'}).activationStatus,
          ActivationStatus.pending,
        );
      });
      test('parses rejected correctly', () {
        expect(
          UserModel.fromJson({'activationStatus': 'rejected'}).activationStatus,
          ActivationStatus.rejected,
        );
      });
      test('defaults to active for unknown', () {
        expect(
          UserModel.fromJson({'activationStatus': 'banned'}).activationStatus,
          ActivationStatus.active,
        );
      });
      test('defaults to active for null', () {
        expect(
          UserModel.fromJson({'activationStatus': null}).activationStatus,
          ActivationStatus.active,
        );
      });
    });
  });
}
