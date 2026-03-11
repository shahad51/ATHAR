import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../core/utils/helpers.dart';

class ReportsProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final AiMatchingService _aiMatchingService = AiMatchingService();
  final NotificationService _notificationService = NotificationService();

  List<ReportModel> _reports = [];
  List<ReportModel> _userLostReports = [];
  List<ReportModel> _userFoundReports = [];
  List<ReportMatch> _matchResults = [];
  bool _isLoading = false;
  String? _error;

  List<ReportModel> get reports => _reports;
  List<ReportModel> get userLostReports => _userLostReports;
  List<ReportModel> get userFoundReports => _userFoundReports;
  List<ReportMatch> get matchResults => _matchResults;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Stream<List<ReportModel>> getReportsStream({
    String? submittedBy,
    ReportType? reportType,
    ReportStatus? status,
  }) {
    return _firestoreService.reportsStream(
      submittedBy: submittedBy,
      reportType: reportType,
      status: status,
    );
  }

  Future<String?> submitFoundReport({
    required String userId,
    required String itemType,
    required String itemColor,
    required String itemLocation,
    required File imageFile,
    bool isCenterSubmitted = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final reportId = Helpers.generateId();
      final referenceId = Helpers.generateReferenceId();

      final imageUrl =
          await _storageService.uploadReportImage(imageFile, reportId);
      if (imageUrl == null) {
        _error = 'Failed to upload image';
        _isLoading = false;
        notifyListeners();
        return null;
      }

      final featureVector =
          await _aiMatchingService.extractFeatureVector(imageFile);

      final report = ReportModel(
        reportId: reportId,
        referenceId: referenceId,
        reportType: ReportType.found,
        submittedBy: userId,
        itemType: itemType,
        itemColor: itemColor,
        itemLocation: itemLocation,
        imageUrl: imageUrl,
        submissionDate: DateTime.now(),
        status: ReportStatus.inProgress,
        isManualEntry: isCenterSubmitted,
        isCenterSubmitted: isCenterSubmitted,
        featureVector: featureVector,
      );

      await _firestoreService.createReport(report);
      await _notificationService.sendNewReportNotification();

      _isLoading = false;
      notifyListeners();
      return reportId;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<String?> submitLostReport({
    required String userId,
    required String itemType,
    required String itemColor,
    required String itemLocation,
    File? imageFile,
    String? matchedReportId,
    bool isCenterSubmitted = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final reportId = Helpers.generateId();
      final referenceId = Helpers.generateReferenceId();
      String? imageUrl;
      List<double>? featureVector;

      if (imageFile != null) {
        imageUrl = await _storageService.uploadReportImage(imageFile, reportId);
        featureVector =
            await _aiMatchingService.extractFeatureVector(imageFile);
      }

      final report = ReportModel(
        reportId: reportId,
        referenceId: referenceId,
        reportType: ReportType.lost,
        submittedBy: userId,
        itemType: itemType,
        itemColor: itemColor,
        itemLocation: itemLocation,
        imageUrl: imageUrl,
        submissionDate: DateTime.now(),
        status: ReportStatus.inProgress,
        isManualEntry: isCenterSubmitted,
        isCenterSubmitted: isCenterSubmitted,
        matchedReportId: matchedReportId,
        featureVector: featureVector,
      );

      await _firestoreService.createReport(report);
      await _notificationService.sendNewReportNotification();

      _isLoading = false;
      notifyListeners();
      return reportId;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<List<ReportMatch>> searchForMatches({
    required String itemType,
    required String itemColor,
    required String itemLocation,
    File? imageFile,
  }) async {
    _isLoading = true;
    _matchResults = [];
    notifyListeners();

    try {
      final foundReports = await _firestoreService.getFoundReports(
        itemType: itemType,
        itemColor: itemColor,
        itemLocation: itemLocation,
      );

      _matchResults = await _aiMatchingService.findMatchesWithRuleBased(
        imageFile,
        foundReports,
      );

      _isLoading = false;
      notifyListeners();
      return _matchResults;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

  Future<void> updateReportStatus(
    String reportId,
    ReportStatus status,
    String submitterId,
  ) async {
    try {
      await _firestoreService.updateReport(reportId, {
        'status': status == ReportStatus.matched ? 'Matched' : 'Rejected',
      });

      if (status == ReportStatus.matched) {
        await _notificationService.sendMatchNotification(submitterId, reportId);
      } else {
        await _notificationService.sendStatusUpdateNotification(
          submitterId,
          'Rejected',
        );
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearMatchResults() {
    _matchResults = [];
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
