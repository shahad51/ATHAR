import 'package:cloud_firestore/cloud_firestore.dart';

class LoginLogModel {
  final String logId;
  final String userId;
  final DateTime timestamp;
  final String status;

  LoginLogModel({
    required this.logId,
    required this.userId,
    required this.timestamp,
    required this.status,
  });

  factory LoginLogModel.fromJson(Map<String, dynamic> json) {
    return LoginLogModel(
      logId: json['logId'] ?? '',
      userId: json['userId'] ?? '',
      timestamp: json['timestamp'] is Timestamp
          ? (json['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      status: json['status'] ?? 'failure',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'logId': logId,
      'userId': userId,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status,
    };
  }
}
