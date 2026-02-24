import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/utils/helpers.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';
import '../../widgets/widgets.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final userId = context.read<AuthProvider>().currentUser?.userId;
    final firestoreService = FirestoreService();

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.get('notifications'))),
        body: const Center(child: Text('Please login')),
      );
    }

    return Scaffold(
      // appBar: AppBar(
      //   title: Text(l10n.get('notifications')),
      // ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: firestoreService.notificationsStream(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ShimmerListLoading();
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.notifications_off_outlined,
              title: l10n.get('no_notifications'),
              subtitle: 'You will see notifications here when you receive them',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _NotificationCard(
                notification: notification,
                onTap: () async {
                  if (!notification.isRead) {
                    await firestoreService.markNotificationRead(notification.notificationId);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: notification.isRead ? null : AppColors.primaryGreen.withOpacity(0.05),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getNotificationColor(notification.type).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Helpers.getNotificationIcon(notification.type.name),
                  color: _getNotificationColor(notification.type),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      Helpers.timeAgo(notification.sentAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.match:
        return AppColors.success;
      case NotificationType.statusUpdate:
        return AppColors.info;
      case NotificationType.maintenance:
        return AppColors.warning;
      case NotificationType.newReport:
        return AppColors.primaryGreen;
      case NotificationType.accountActivated:
        return AppColors.success;
    }
  }
}
