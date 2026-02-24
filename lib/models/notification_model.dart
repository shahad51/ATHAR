import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  match,
  statusUpdate,
  maintenance,
  newReport,
  accountActivated,
}

class NotificationModel {
  final String notificationId;
  final String recipientUserId;
  final String message;
  final NotificationType type;
  final DateTime sentAt;
  final bool isRead;

  NotificationModel({
    required this.notificationId,
    required this.recipientUserId,
    required this.message,
    required this.type,
    required this.sentAt,
    this.isRead = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      notificationId: json['notificationId'] ?? '',
      recipientUserId: json['recipientUserId'] ?? '',
      message: json['message'] ?? '',
      type: _parseType(json['type']),
      sentAt: json['sentAt'] is Timestamp
          ? (json['sentAt'] as Timestamp).toDate()
          : DateTime.now(),
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationId': notificationId,
      'recipientUserId': recipientUserId,
      'message': message,
      'type': type.name,
      'sentAt': Timestamp.fromDate(sentAt),
      'isRead': isRead,
    };
  }

  NotificationModel copyWith({
    String? notificationId,
    String? recipientUserId,
    String? message,
    NotificationType? type,
    DateTime? sentAt,
    bool? isRead,
  }) {
    return NotificationModel(
      notificationId: notificationId ?? this.notificationId,
      recipientUserId: recipientUserId ?? this.recipientUserId,
      message: message ?? this.message,
      type: type ?? this.type,
      sentAt: sentAt ?? this.sentAt,
      isRead: isRead ?? this.isRead,
    );
  }

  static NotificationType _parseType(String? type) {
    switch (type) {
      case 'match':
        return NotificationType.match;
      case 'statusUpdate':
        return NotificationType.statusUpdate;
      case 'maintenance':
        return NotificationType.maintenance;
      case 'newReport':
        return NotificationType.newReport;
      case 'accountActivated':
        return NotificationType.accountActivated;
      default:
        return NotificationType.statusUpdate;
    }
  }
}
