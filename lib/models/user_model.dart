import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { regular, employee, admin }

enum ActivationStatus { active, pending, rejected }

class UserModel {
  final String userId;
  final String firstName;
  final String lastName;
  final String mobile;
  final String? email;
  final String username;
  final UserRole role;
  final ActivationStatus activationStatus;
  final String preferredLanguage;
  final DateTime createdAt;
  final String? fcmToken;
  final String? passwordHash;

  UserModel({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.mobile,
    this.email,
    required this.username,
    required this.role,
    required this.activationStatus,
    this.preferredLanguage = 'ar',
    required this.createdAt,
    this.fcmToken,
    this.passwordHash,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      mobile: json['mobile'] ?? '',
      email: json['email'],
      username: json['username'] ?? '',
      role: _parseRole(json['role']),
      activationStatus: _parseActivationStatus(json['activationStatus']),
      preferredLanguage: json['preferredLanguage'] ?? 'ar',
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      fcmToken: json['fcmToken'],
      passwordHash: json['passwordHash'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'firstName': firstName,
      'lastName': lastName,
      'mobile': mobile,
      'email': email,
      'username': username,
      'role': role.name,
      'activationStatus': activationStatus.name,
      'preferredLanguage': preferredLanguage,
      'createdAt': Timestamp.fromDate(createdAt),
      'fcmToken': fcmToken,
      'passwordHash': passwordHash,
    };
  }

  UserModel copyWith({
    String? userId,
    String? firstName,
    String? lastName,
    String? mobile,
    String? email,
    String? username,
    UserRole? role,
    ActivationStatus? activationStatus,
    String? preferredLanguage,
    DateTime? createdAt,
    String? fcmToken,
    String? passwordHash,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      username: username ?? this.username,
      role: role ?? this.role,
      activationStatus: activationStatus ?? this.activationStatus,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      createdAt: createdAt ?? this.createdAt,
      fcmToken: fcmToken ?? this.fcmToken,
      passwordHash: passwordHash ?? this.passwordHash,
    );
  }

  String get fullName => '$firstName $lastName';

  static UserRole _parseRole(String? role) {
    switch (role) {
      case 'employee':
        return UserRole.employee;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.regular;
    }
  }

  static ActivationStatus _parseActivationStatus(String? status) {
    switch (status) {
      case 'pending':
        return ActivationStatus.pending;
      case 'rejected':
        return ActivationStatus.rejected;
      default:
        return ActivationStatus.active;
    }
  }
}
