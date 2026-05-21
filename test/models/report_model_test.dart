import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:athar_app/models/report_model.dart';

void main() {
  group('RouteMetadata', () {
    test('fromJson parses fields correctly', () {
      final json = {'distance': '2.5 km', 'duration': '15 min', 'polyline': 'abc123'};
      final route = RouteMetadata.fromJson(json);

      expect(route.distance, '2.5 km');
      expect(route.duration, '15 min');
      expect(route.polyline, 'abc123');
    });

    test('toJson serializes correctly', () {
      const route = RouteMetadata(distance: '1 km', duration: '5 min', polyline: 'xyz');
      final json = route.toJson();

      expect(json['distance'], '1 km');
      expect(json['duration'], '5 min');
      expect(json['polyline'], 'xyz');
    });

    test('fromJson handles missing fields', () {
      final route = RouteMetadata.fromJson({});
      expect(route.distance, '');
      expect(route.duration, '');
      expect(route.polyline, '');
    });
  });

  group('ReportModel', () {
    final now = DateTime(2025, 5, 10, 14, 30);
    final testReport = ReportModel(
      reportId: 'rep_001',
      referenceId: 'ATH-2025-000123',
      reportType: ReportType.lost,
      submittedBy: 'user_001',
      itemType: 'Passport',
      itemColor: 'Blue',
      itemLocation: 'Mina',
      imageUrl: 'https://example.com/img.jpg',
      submissionDate: now,
      status: ReportStatus.inProgress,
      isManualEntry: false,
      isCenterSubmitted: false,
      matchedReportId: null,
      nearestCenterName: 'Center A',
      deliveryLocationId: null,
      routeMetadata: null,
      featureVector: [0.1, 0.2, 0.3],
    );

    test('fromJson parses complete report correctly', () {
      final json = {
        'reportId': 'rep_002',
        'referenceId': 'ATH-2025-000456',
        'reportType': 'found',
        'submittedBy': 'user_002',
        'itemType': 'Phone',
        'itemColor': 'Black',
        'itemLocation': 'Arafat',
        'imageUrl': null,
        'submissionDate': Timestamp.fromDate(now),
        'status': 'Matched',
        'isManualEntry': true,
        'isCenterSubmitted': true,
        'matchedReportId': 'rep_001',
        'nearestCenterName': null,
        'deliveryLocationId': 'loc_01',
        'routeMetadata': {'distance': '3 km', 'duration': '20 min', 'polyline': 'poly'},
        'featureVector': [0.5, 0.6],
      };

      final report = ReportModel.fromJson(json);

      expect(report.reportId, 'rep_002');
      expect(report.referenceId, 'ATH-2025-000456');
      expect(report.reportType, ReportType.found);
      expect(report.submittedBy, 'user_002');
      expect(report.itemType, 'Phone');
      expect(report.itemColor, 'Black');
      expect(report.itemLocation, 'Arafat');
      expect(report.imageUrl, isNull);
      expect(report.status, ReportStatus.matched);
      expect(report.isManualEntry, true);
      expect(report.isCenterSubmitted, true);
      expect(report.matchedReportId, 'rep_001');
      expect(report.nearestCenterName, isNull);
      expect(report.deliveryLocationId, 'loc_01');
      expect(report.routeMetadata, isNotNull);
      expect(report.routeMetadata!.distance, '3 km');
      expect(report.featureVector, [0.5, 0.6]);
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'reportId': 'rep_003',
        'referenceId': 'ATH-2025-000789',
        'reportType': 'lost',
        'submittedBy': 'user_003',
        'itemType': 'Wallet',
        'itemColor': 'Brown',
        'itemLocation': 'Masjid Al-Haram',
        'submissionDate': Timestamp.fromDate(now),
        'status': 'InProgress',
      };

      final report = ReportModel.fromJson(json);

      expect(report.imageUrl, isNull);
      expect(report.matchedReportId, isNull);
      expect(report.routeMetadata, isNull);
      expect(report.featureVector, isNull);
      expect(report.isManualEntry, false);
      expect(report.isCenterSubmitted, false);
    });

    test('toJson serializes correctly', () {
      final json = testReport.toJson();

      expect(json['reportId'], 'rep_001');
      expect(json['referenceId'], 'ATH-2025-000123');
      expect(json['reportType'], 'lost');
      expect(json['status'], 'InProgress');
      expect(json['featureVector'], [0.1, 0.2, 0.3]);
      expect(json['submissionDate'], isA<Timestamp>());
    });

    test('copyWith updates only specified fields', () {
      final updated = testReport.copyWith(
        status: ReportStatus.matched,
        matchedReportId: 'rep_999',
      );

      expect(updated.status, ReportStatus.matched);
      expect(updated.matchedReportId, 'rep_999');
      expect(updated.itemType, 'Passport'); // unchanged
      expect(updated.reportId, 'rep_001'); // unchanged
    });

    group('ReportStatus parsing', () {
      test('parses Matched', () {
        expect(ReportModel.fromJson({'status': 'Matched'}).status, ReportStatus.matched);
      });
      test('parses Rejected', () {
        expect(ReportModel.fromJson({'status': 'Rejected'}).status, ReportStatus.rejected);
      });
      test('defaults to InProgress for unknown', () {
        expect(ReportModel.fromJson({'status': 'Deleted'}).status, ReportStatus.inProgress);
      });
      test('defaults to InProgress for null', () {
        expect(ReportModel.fromJson({'status': null}).status, ReportStatus.inProgress);
      });
    });

    group('ReportMatch', () {
      test('constructs correctly', () {
        final match = ReportMatch(report: testReport, confidenceScore: 0.85);

        expect(match.report.reportId, 'rep_001');
        expect(match.confidenceScore, 0.85);
      });
    });
  });
}
