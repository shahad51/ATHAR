import 'package:cloud_firestore/cloud_firestore.dart';

enum ActionType {
  viewedReport,
  reviewedRequest,
  updatedReportStatus,
  createdReport
}

class HistoryModel {
  final String historyId;
  final String actorId;
  final String actorRole;
  final ActionType actionType;
  final String targetId;
  final DateTime timestamp;
  final String? details;

  HistoryModel({
    required this.historyId,
    required this.actorId,
    required this.actorRole,
    required this.actionType,
    required this.targetId,
    required this.timestamp,
    this.details,
  });

  factory HistoryModel.fromJson(Map<String, dynamic> json) {
    ActionType parseActionType(String? type) {
      switch (type) {
        case 'reviewedRequest':
          return ActionType.reviewedRequest;
        case 'updatedReportStatus':
          return ActionType.updatedReportStatus;
        case 'createdReport':
          return ActionType.createdReport;
        case 'viewedReport':
        default:
          return ActionType.viewedReport;
      }
    }

    return HistoryModel(
      historyId: json['historyId'] ?? '',
      actorId: json['actorId'] ?? '',
      actorRole: json['actorRole'] ?? '',
      actionType: parseActionType(json['actionType']),
      targetId: json['targetId'] ?? '',
      timestamp: json['timestamp'] is Timestamp
          ? (json['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      details: json['details'],
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
      if (details != null) 'details': details,
    };
  }
}
