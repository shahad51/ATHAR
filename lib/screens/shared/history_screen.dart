import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/utils/helpers.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';
import '../../widgets/widgets.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.userId;
    final role = authProvider.currentUser?.role;
    final firestoreService = FirestoreService();

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.get('history'))),
        body: const Center(child: Text('Please login')),
      );
    }

    final actionType = role == UserRole.manager
        ? ActionType.reviewedRequest
        : ActionType.viewedReport;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('history')),
      ),
      body: StreamBuilder<List<HistoryModel>>(
        stream: firestoreService.historyStream(userId, actionType),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ShimmerListLoading();
          }

          final history = snapshot.data ?? [];

          if (history.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.history,
              title: l10n.get('no_history'),
              subtitle: role == UserRole.manager
                  ? 'Your reviewed requests will appear here'
                  : 'Your viewed reports will appear here',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              return _HistoryCard(
                history: item,
                isManagerView: role == UserRole.manager,
              );
            },
          );
        },
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final HistoryModel history;
  final bool isManagerView;

  const _HistoryCard({
    required this.history,
    required this.isManagerView,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isManagerView ? Icons.how_to_reg : Icons.article_outlined,
            color: AppColors.primaryGreen,
          ),
        ),
        title: Text(
          isManagerView ? 'Reviewed Request' : 'Viewed Report',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'ID: ${history.targetId.substring(0, 8)}...',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              Helpers.timeAgo(history.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Navigate to detail screen
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Opening ${history.targetId}')),
          );
        },
      ),
    );
  }
}
