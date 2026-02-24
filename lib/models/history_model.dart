import 'package:cloud_firestore/cloud_firestore.dart';

enum ActionType { viewedReport, reviewedRequest }

class HistoryModel {
  final String historyId;
  final String actorId;
  final String actorRole;
  final ActionType actionType;
  final String targetId;
  final DateTime timestamp;

  HistoryModel({
    required this.historyId,
    required this.actorId,
    required this.actorRole,
    required this.actionType,
    required this.targetId,
    required this.timestamp,
  });

  factory HistoryModel.fromJson(Map<String, dynamic> json) {
    return HistoryModel(
      historyId: json['historyId'] ?? '',
      actorId: json['actorId'] ?? '',
      actorRole: json['actorRole'] ?? '',
      actionType: json['actionType'] == 'reviewedRequest'
          ? ActionType.reviewedRequest
          : ActionType.viewedReport,
      targetId: json['targetId'] ?? '',
      timestamp: json['timestamp'] is Timestamp
          ? (json['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'historyId': historyId,
      'actorId': actorId,
      'actorRole': actorRole,
      'actionType': actionType.name,
      'targetId': targetId,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
