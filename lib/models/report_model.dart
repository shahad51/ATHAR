import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportType { lost, found }

enum ReportStatus { inProgress, matched, rejected }

class RouteMetadata {
  final String distance;
  final String duration;
  final String polyline;

  RouteMetadata({
    required this.distance,
    required this.duration,
    required this.polyline,
  });

  factory RouteMetadata.fromJson(Map<String, dynamic> json) {
    return RouteMetadata(
      distance: json['distance'] ?? '',
      duration: json['duration'] ?? '',
      polyline: json['polyline'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'distance': distance,
      'duration': duration,
      'polyline': polyline,
    };
  }
}

class ReportModel {
  final String reportId;
  final ReportType reportType;
  final String submittedBy;
  final String itemType;
  final String itemColor;
  final String itemLocation;
  final String? imageUrl;
  final DateTime submissionDate;
  final ReportStatus status;
  final bool isManualEntry;
  final bool isCenterSubmitted;
  final String? matchedReportId;
  final String? nearestCenterName;
  final String? deliveryLocationId;
  final RouteMetadata? routeMetadata;
  final List<double>? featureVector;

  ReportModel({
    required this.reportId,
    required this.reportType,
    required this.submittedBy,
    required this.itemType,
    required this.itemColor,
    required this.itemLocation,
    this.imageUrl,
    required this.submissionDate,
    required this.status,
    this.isManualEntry = false,
    this.isCenterSubmitted = false,
    this.matchedReportId,
    this.nearestCenterName,
    this.deliveryLocationId,
    this.routeMetadata,
    this.featureVector,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      reportId: json['reportId'] ?? '',
      reportType: json['reportType'] == 'found' ? ReportType.found : ReportType.lost,
      submittedBy: json['submittedBy'] ?? '',
      itemType: json['itemType'] ?? '',
      itemColor: json['itemColor'] ?? '',
      itemLocation: json['itemLocation'] ?? '',
      imageUrl: json['imageUrl'],
      submissionDate: json['submissionDate'] is Timestamp
          ? (json['submissionDate'] as Timestamp).toDate()
          : DateTime.now(),
      status: _parseStatus(json['status']),
      isManualEntry: json['isManualEntry'] ?? false,
      isCenterSubmitted: json['isCenterSubmitted'] ?? false,
      matchedReportId: json['matchedReportId'],
      nearestCenterName: json['nearestCenterName'],
      deliveryLocationId: json['deliveryLocationId'],
      routeMetadata: json['routeMetadata'] != null
          ? RouteMetadata.fromJson(json['routeMetadata'])
          : null,
      featureVector: json['featureVector'] != null
          ? List<double>.from(json['featureVector'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reportId': reportId,
      'reportType': reportType.name,
      'submittedBy': submittedBy,
      'itemType': itemType,
      'itemColor': itemColor,
      'itemLocation': itemLocation,
      'imageUrl': imageUrl,
      'submissionDate': Timestamp.fromDate(submissionDate),
      'status': _statusToString(status),
      'isManualEntry': isManualEntry,
      'isCenterSubmitted': isCenterSubmitted,
      'matchedReportId': matchedReportId,
      'nearestCenterName': nearestCenterName,
      'deliveryLocationId': deliveryLocationId,
      'routeMetadata': routeMetadata?.toJson(),
      'featureVector': featureVector,
    };
  }

  ReportModel copyWith({
    String? reportId,
    ReportType? reportType,
    String? submittedBy,
    String? itemType,
    String? itemColor,
    String? itemLocation,
    String? imageUrl,
    DateTime? submissionDate,
    ReportStatus? status,
    bool? isManualEntry,
    bool? isCenterSubmitted,
    String? matchedReportId,
    String? nearestCenterName,
    String? deliveryLocationId,
    RouteMetadata? routeMetadata,
    List<double>? featureVector,
  }) {
    return ReportModel(
      reportId: reportId ?? this.reportId,
      reportType: reportType ?? this.reportType,
      submittedBy: submittedBy ?? this.submittedBy,
      itemType: itemType ?? this.itemType,
      itemColor: itemColor ?? this.itemColor,
      itemLocation: itemLocation ?? this.itemLocation,
      imageUrl: imageUrl ?? this.imageUrl,
      submissionDate: submissionDate ?? this.submissionDate,
      status: status ?? this.status,
      isManualEntry: isManualEntry ?? this.isManualEntry,
      isCenterSubmitted: isCenterSubmitted ?? this.isCenterSubmitted,
      matchedReportId: matchedReportId ?? this.matchedReportId,
      nearestCenterName: nearestCenterName ?? this.nearestCenterName,
      deliveryLocationId: deliveryLocationId ?? this.deliveryLocationId,
      routeMetadata: routeMetadata ?? this.routeMetadata,
      featureVector: featureVector ?? this.featureVector,
    );
  }

  static ReportStatus _parseStatus(String? status) {
    switch (status) {
      case 'Matched':
        return ReportStatus.matched;
      case 'Rejected':
        return ReportStatus.rejected;
      default:
        return ReportStatus.inProgress;
    }
  }

  static String _statusToString(ReportStatus status) {
    switch (status) {
      case ReportStatus.matched:
        return 'Matched';
      case ReportStatus.rejected:
        return 'Rejected';
      default:
        return 'InProgress';
    }
  }
}

class ReportMatch {
  final ReportModel report;
  final double confidenceScore;

  ReportMatch({
    required this.report,
    required this.confidenceScore,
  });
}
