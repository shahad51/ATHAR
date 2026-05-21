import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/models.dart';
import '../core/utils/helpers.dart';
import 'firestore_service.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'athar_high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    try {
      // Request FCM permission
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ User granted notification permission');
      }

      // Initialize local notifications
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create Android notification channel
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      // Listen to FCM messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      debugPrint('✅ Notification service initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize notifications: $e');
    }
  }

  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      return null;
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint(
        '🔔 Received foreground message: ${message.notification?.title}');

    final notification = message.notification;
    if (notification != null) {
      _showLocalNotification(
        title: notification.title ?? 'ATHAR',
        body: notification.body ?? '',
        payload: message.data['reportId'],
      );
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('👆 Message opened app: ${message.data}');
    // Navigation will be handled by onDidReceiveNotificationResponse
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('👆 Notification tapped: ${response.payload}');
    // Handle navigation based on payload (reportId, etc.)
    // This can be implemented with a global navigator key or event bus
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'athar_high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      payload: payload,
    );
  }

  // Send match notification to report submitter
  Future<void> sendMatchNotification(String userId, String reportId) async {
    await _createAndSaveNotification(
      recipientUserId: userId,
      message: 'A match has been found for your lost item.',
      type: NotificationType.match,
    );
  }

  // Send status update notification
  Future<void> sendStatusUpdateNotification(
    String userId,
    String status,
  ) async {
    await _createAndSaveNotification(
      recipientUserId: userId,
      message: 'Your report status has been updated to $status.',
      type: NotificationType.statusUpdate,
    );
  }

  // Send maintenance notification to all users
  Future<void> sendMaintenanceNotification() async {
    final userIds = await _firestoreService.getAllActiveUserIds();
    for (final userId in userIds) {
      await _createAndSaveNotification(
        recipientUserId: userId,
        message: 'System maintenance is currently in progress.',
        type: NotificationType.maintenance,
      );
    }
  }

  // Send new report notification to all admins and employees
  Future<void> sendNewReportNotification() async {
    final userIds = await _firestoreService.getAdminAndEmployeeIds();
    for (final userId in userIds) {
      await _createAndSaveNotification(
        recipientUserId: userId,
        message: 'A new report has been submitted and needs your attention.',
        type: NotificationType.newReport,
      );
    }
  }

  // Send account approved notification
  Future<void> sendAccountApprovedNotification(String userId) async {
    await _createAndSaveNotification(
      recipientUserId: userId,
      message: 'Your account has been approved. You can now log in.',
      type: NotificationType.accountActivated,
    );
  }

  // Send account rejected notification
  Future<void> sendAccountRejectedNotification(String userId) async {
    await _createAndSaveNotification(
      recipientUserId: userId,
      message: 'Your account request was rejected.',
      type: NotificationType.statusUpdate,
    );
  }

  Future<void> _createAndSaveNotification({
    required String recipientUserId,
    required String message,
    required NotificationType type,
  }) async {
    try {
      final notification = NotificationModel(
        notificationId: Helpers.generateId(),
        recipientUserId: recipientUserId,
        message: message,
        type: type,
        sentAt: DateTime.now(),
        isRead: false,
      );

      await _firestoreService.createNotification(notification);
    } catch (e) {
      debugPrint('Failed to create notification: $e');
    }
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
}
