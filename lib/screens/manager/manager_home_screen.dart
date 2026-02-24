import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/utils/helpers.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';
import '../../widgets/widgets.dart';
import '../shared/app_drawer.dart';
import '../shared/notifications_screen.dart';
import '../shared/settings_screen.dart';
import '../shared/history_screen.dart';

class ManagerHomeScreen extends StatefulWidget {
  const ManagerHomeScreen({super.key});

  @override
  State<ManagerHomeScreen> createState() => _ManagerHomeScreenState();
}

class _ManagerHomeScreenState extends State<ManagerHomeScreen> {
  int _currentIndex = 0;
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final screens = [
      _buildRequestsTab(l10n),
      const HistoryScreen(),
      const NotificationsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('app_name_arabic')),
      ),
      drawer: const AppDrawer(),
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.how_to_reg_outlined),
            activeIcon: const Icon(Icons.how_to_reg),
            label: l10n.get('requests'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history_outlined),
            activeIcon: const Icon(Icons.history),
            label: l10n.get('history'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.notifications_outlined),
            activeIcon: const Icon(Icons.notifications),
            label: l10n.get('notifications'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_outlined),
            activeIcon: const Icon(Icons.settings),
            label: l10n.get('settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsTab(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            l10n.get('pending_requests'),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        Expanded(
          child: StreamBuilder<List<ElevatedAccountRequest>>(
            stream: _firestoreService.pendingRequestsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const ShimmerListLoading();
              }

              final requests = snapshot.data ?? [];

              if (requests.isEmpty) {
                return EmptyStateWidget(
                  icon: Icons.check_circle_outline,
                  title: 'No Pending Requests',
                  subtitle: 'All account requests have been processed',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  return _RequestCard(
                    request: requests[index],
                    onApprove: () => _handleApprove(requests[index]),
                    onReject: () => _handleReject(requests[index]),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _handleApprove(ElevatedAccountRequest request) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Request'),
        content: Text('Are you sure you want to approve this ${request.requestedRole} request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final managerId = context.read<AuthProvider>().currentUser?.userId;
    if (managerId == null) return;

    try {
      await _firestoreService.approveRequest(
        request.requestId,
        request.userId,
        managerId,
      );

      await _notificationService.sendAccountApprovedNotification(request.userId);

      final historyId = Helpers.generateId();
      await _firestoreService.logHistory(HistoryModel(
        historyId: historyId,
        actorId: managerId,
        actorRole: 'manager',
        actionType: ActionType.reviewedRequest,
        targetId: request.requestId,
        timestamp: DateTime.now(),
      ));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request approved successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleReject(ElevatedAccountRequest request) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Request'),
        content: Text('Are you sure you want to reject this ${request.requestedRole} request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final managerId = context.read<AuthProvider>().currentUser?.userId;
    if (managerId == null) return;

    try {
      await _firestoreService.rejectRequest(
        request.requestId,
        request.userId,
        managerId,
      );

      await _notificationService.sendAccountRejectedNotification(request.userId);

      final historyId = Helpers.generateId();
      await _firestoreService.logHistory(HistoryModel(
        historyId: historyId,
        actorId: managerId,
        actorRole: 'manager',
        actionType: ActionType.reviewedRequest,
        targetId: request.requestId,
        timestamp: DateTime.now(),
      ));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request rejected'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _RequestCard extends StatelessWidget {
  final ElevatedAccountRequest request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _RequestCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<UserModel?>(
              future: firestoreService.getUser(request.userId),
              builder: (context, snapshot) {
                final user = snapshot.data;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primaryGreen,
                          child: Text(
                            user != null ? '${user.firstName[0]}${user.lastName[0]}' : '?',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.fullName ?? 'Loading...',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                user?.mobile ?? '',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryGold.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            request.requestedRole.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondaryGoldDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Text(
              'Requested: ${Helpers.formatDateTime(request.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
