import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import '../core/utils/helpers.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Users
  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      return UserModel.fromJson(doc.data()!);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(userId).update(data);
  }

  Stream<UserModel?> userStream(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromJson(doc.data()!);
    });
  }

  // Reports
  Future<String> createReport(ReportModel report) async {
    final docRef = _firestore.collection('reports').doc(report.reportId);
    await docRef.set(report.toJson());
    return report.reportId;
  }

  Future<void> updateReport(String reportId, Map<String, dynamic> data) async {
    await _firestore.collection('reports').doc(reportId).update(data);
  }

  Future<ReportModel?> getReport(String reportId) async {
    try {
      final doc = await _firestore.collection('reports').doc(reportId).get();
      if (!doc.exists) return null;
      return ReportModel.fromJson(doc.data()!);
    } catch (e) {
      return null;
    }
  }

  Stream<List<ReportModel>> reportsStream({
    String? submittedBy,
    ReportType? reportType,
    ReportStatus? status,
    bool? isCenterSubmitted,
  }) {
    Query query = _firestore.collection('reports');

    if (submittedBy != null) {
      query = query.where('submittedBy', isEqualTo: submittedBy);
    }
    if (reportType != null) {
      query = query.where('reportType', isEqualTo: reportType.name);
    }
    if (status != null) {
      query = query.where('status', isEqualTo: _statusToString(status));
    }
    if (isCenterSubmitted != null) {
      query = query.where('isCenterSubmitted', isEqualTo: isCenterSubmitted);
    }

    query = query.orderBy('submissionDate', descending: true);

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ReportModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  Future<List<ReportModel>> getFoundReports({
    String? itemType,
    String? itemColor,
    String? itemLocation,
  }) async {
    try {
      Query query = _firestore
          .collection('reports')
          .where('reportType', isEqualTo: 'found');

      if (itemType != null && itemType.isNotEmpty) {
        query = query.where('itemType', isEqualTo: itemType);
      }

      final snapshot = await query.get();
      var reports = snapshot.docs
          .map((doc) => ReportModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      if (itemColor != null && itemColor.isNotEmpty) {
        reports = reports.where((r) {
          return r.itemColor.toLowerCase().contains(itemColor.toLowerCase());
        }).toList();
      }

      if (itemLocation != null && itemLocation.isNotEmpty) {
        reports = reports.where((r) {
          return r.itemLocation.toLowerCase().contains(itemLocation.toLowerCase());
        }).toList();
      }

      return reports;
    } catch (e) {
      return [];
    }
  }

  Future<int> getReportsCount24h() async {
    try {
      final yesterday = DateTime.now().subtract(const Duration(hours: 24));
      final snapshot = await _firestore
          .collection('reports')
          .where('submissionDate', isGreaterThan: Timestamp.fromDate(yesterday))
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  Future<Map<String, int>> getReportsCountByStatus() async {
    try {
      final snapshot = await _firestore.collection('reports').get();
      final counts = <String, int>{
        'InProgress': 0,
        'Matched': 0,
        'Rejected': 0,
      };

      for (final doc in snapshot.docs) {
        final status = doc.data()['status'] as String? ?? 'InProgress';
        counts[status] = (counts[status] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      return {'InProgress': 0, 'Matched': 0, 'Rejected': 0};
    }
  }

  Future<String?> getTopReportedLocation() async {
    try {
      final snapshot = await _firestore.collection('reports').get();
      final locationCounts = <String, int>{};

      for (final doc in snapshot.docs) {
        final location = doc.data()['itemLocation'] as String? ?? '';
        if (location.isNotEmpty) {
          locationCounts[location] = (locationCounts[location] ?? 0) + 1;
        }
      }

      if (locationCounts.isEmpty) return null;

      final sorted = locationCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sorted.first.key;
    } catch (e) {
      return null;
    }
  }

  // Movement History
  Future<void> saveMovementHistory(MovementHistoryModel history) async {
    await _firestore
        .collection('movementHistory')
        .doc(history.userId)
        .set(history.toJson());
  }

  Future<void> addLocationEntry(String userId, LocationEntry entry) async {
    await _firestore.collection('movementHistory').doc(userId).update({
      'entries': FieldValue.arrayUnion([entry.toJson()]),
    });
  }

  Future<MovementHistoryModel?> getMovementHistory(String userId) async {
    try {
      final doc = await _firestore.collection('movementHistory').doc(userId).get();
      if (!doc.exists) return null;
      return MovementHistoryModel.fromJson(doc.data()!, doc.id);
    } catch (e) {
      return null;
    }
  }

  // Elevated Account Requests
  Stream<List<ElevatedAccountRequest>> pendingRequestsStream() {
    return _firestore
        .collection('elevatedAccountRequests')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ElevatedAccountRequest.fromJson(doc.data()))
          .toList();
    });
  }

  Future<void> approveRequest(
    String requestId,
    String userId,
    String managerId,
  ) async {
    final batch = _firestore.batch();

    final requestRef = _firestore.collection('elevatedAccountRequests').doc(requestId);
    batch.update(requestRef, {
      'status': 'approved',
      'reviewedByManagerId': managerId,
      'reviewedAt': Timestamp.now(),
    });

    final userRef = _firestore.collection('users').doc(userId);
    batch.update(userRef, {
      'activationStatus': 'active',
    });

    await batch.commit();
  }

  Future<void> rejectRequest(
    String requestId,
    String userId,
    String managerId,
  ) async {
    final batch = _firestore.batch();

    final requestRef = _firestore.collection('elevatedAccountRequests').doc(requestId);
    batch.update(requestRef, {
      'status': 'rejected',
      'reviewedByManagerId': managerId,
      'reviewedAt': Timestamp.now(),
    });

    final userRef = _firestore.collection('users').doc(userId);
    batch.update(userRef, {
      'activationStatus': 'rejected',
    });

    await batch.commit();
  }

  // Notifications
  Future<void> createNotification(NotificationModel notification) async {
    await _firestore
        .collection('notifications')
        .doc(notification.notificationId)
        .set(notification.toJson());
  }

  Stream<List<NotificationModel>> notificationsStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('recipientUserId', isEqualTo: userId)
        .orderBy('sentAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationModel.fromJson(doc.data()))
          .toList();
    });
  }

  Future<void> markNotificationRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  Future<int> getUnreadNotificationCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('recipientUserId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // Locations
  Stream<List<LocationModel>> locationsStream() {
    return _firestore
        .collection('locations')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => LocationModel.fromJson(doc.data()))
          .toList();
    });
  }

  Future<List<LocationModel>> getActiveLocations() async {
    try {
      final snapshot = await _firestore
          .collection('locations')
          .where('isActive', isEqualTo: true)
          .get();
      return snapshot.docs
          .map((doc) => LocationModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<LocationModel?> getNearestLocation(double lat, double lng) async {
    final locations = await getActiveLocations();
    if (locations.isEmpty) return null;

    LocationModel? nearest;
    double minDistance = double.infinity;

    for (final location in locations) {
      final distance = Helpers.calculateDistance(lat, lng, location.lat, location.lng);
      if (distance < minDistance) {
        minDistance = distance;
        nearest = location;
      }
    }

    return nearest;
  }

  // History
  Future<void> logHistory(HistoryModel history) async {
    await _firestore.collection('history').doc(history.historyId).set(history.toJson());
  }

  Stream<List<HistoryModel>> historyStream(String actorId, ActionType actionType) {
    return _firestore
        .collection('history')
        .where('actorId', isEqualTo: actorId)
        .where('actionType', isEqualTo: actionType.name)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => HistoryModel.fromJson(doc.data())).toList();
    });
  }

  // Get all admins and employees for notifications
  Future<List<String>> getAdminAndEmployeeIds() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', whereIn: ['admin', 'employee'])
          .where('activationStatus', isEqualTo: 'active')
          .get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<String>> getAllActiveUserIds() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('activationStatus', isEqualTo: 'active')
          .get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      return [];
    }
  }

  String _statusToString(ReportStatus status) {
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
