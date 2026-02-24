import 'package:cloud_firestore/cloud_firestore.dart';

enum RequestStatus { pending, approved, rejected }

class ElevatedAccountRequest {
  final String requestId;
  final String userId;
  final String requestedRole;
  final RequestStatus status;
  final String? reviewedByManagerId;
  final DateTime? reviewedAt;
  final DateTime createdAt;

  ElevatedAccountRequest({
    required this.requestId,
    required this.userId,
    required this.requestedRole,
    required this.status,
    this.reviewedByManagerId,
    this.reviewedAt,
    required this.createdAt,
  });

  factory ElevatedAccountRequest.fromJson(Map<String, dynamic> json) {
    return ElevatedAccountRequest(
      requestId: json['requestId'] ?? '',
      userId: json['userId'] ?? '',
      requestedRole: json['requestedRole'] ?? '',
      status: _parseStatus(json['status']),
      reviewedByManagerId: json['reviewedByManagerId'],
      reviewedAt: json['reviewedAt'] is Timestamp
          ? (json['reviewedAt'] as Timestamp).toDate()
          : null,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requestId': requestId,
      'userId': userId,
      'requestedRole': requestedRole,
      'status': status.name,
      'reviewedByManagerId': reviewedByManagerId,
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  ElevatedAccountRequest copyWith({
    String? requestId,
    String? userId,
    String? requestedRole,
    RequestStatus? status,
    String? reviewedByManagerId,
    DateTime? reviewedAt,
    DateTime? createdAt,
  }) {
    return ElevatedAccountRequest(
      requestId: requestId ?? this.requestId,
      userId: userId ?? this.userId,
      requestedRole: requestedRole ?? this.requestedRole,
      status: status ?? this.status,
      reviewedByManagerId: reviewedByManagerId ?? this.reviewedByManagerId,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static RequestStatus _parseStatus(String? status) {
    switch (status) {
      case 'approved':
        return RequestStatus.approved;
      case 'rejected':
        return RequestStatus.rejected;
      default:
        return RequestStatus.pending;
    }
  }
}
