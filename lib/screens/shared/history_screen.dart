import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/utils/helpers.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';
import '../../widgets/widgets.dart';
import '../employee/report_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  ActionType? _selectedActionType;

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

    final defaultActionType = role == UserRole.admin || role == UserRole.employee
            ? ActionType.updatedReportStatus
            : ActionType.viewedReport;

    final actionType = _selectedActionType ?? defaultActionType;

    return Scaffold(
      body: Column(
        children: [
          if (role == UserRole.admin || role == UserRole.employee)
            _buildFilterChips(l10n),
          Expanded(
            child: StreamBuilder<List<HistoryModel>>(
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
                    subtitle: _getEmptySubtitle(role, actionType),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final item = history[index];
                    return _HistoryCard(
                      history: item,
                      role: role,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(AppLocalizations l10n) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildChip(
            l10n.get('status_updates'),
            _selectedActionType == ActionType.updatedReportStatus,
            () => setState(
                () => _selectedActionType = ActionType.updatedReportStatus),
          ),
          const SizedBox(width: 8),
          _buildChip(
            l10n.get('viewed_reports'),
            _selectedActionType == ActionType.viewedReport,
            () => setState(() => _selectedActionType = ActionType.viewedReport),
          ),
          const SizedBox(width: 8),
          _buildChip(
            l10n.get('created_reports'),
            _selectedActionType == ActionType.createdReport,
            () =>
                setState(() => _selectedActionType = ActionType.createdReport),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool isSelected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primaryGreen.withOpacity(0.2),
      checkmarkColor: AppColors.primaryGreen,
    );
  }

  String _getEmptySubtitle(UserRole? role, ActionType actionType) {
    switch (actionType) {
      case ActionType.updatedReportStatus:
        return 'Report status updates will appear here';
      case ActionType.viewedReport:
        return 'Viewed reports will appear here';
      case ActionType.createdReport:
        return 'Created reports will appear here';
      default:
        return 'Your activity will appear here';
    }
  }
}

class _HistoryCard extends StatelessWidget {
  final HistoryModel history;
  final UserRole? role;

  const _HistoryCard({
    required this.history,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final firestoreService = FirestoreService();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _getActionColor().withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getActionIcon(),
            color: _getActionColor(),
          ),
        ),
        title: Text(
          _getActionTitle(l10n),
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
            if (history.details != null && history.details!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  history.details!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
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
        onTap: () async {
          final report = await firestoreService.getReport(history.targetId);
          if (report != null && context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReportDetailScreen(report: report),
              ),
            );
          } else if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.get('report_not_found'))),
            );
          }
        },
      ),
    );
  }

  IconData _getActionIcon() {
    switch (history.actionType) {
      case ActionType.reviewedRequest:
        return Icons.how_to_reg;
      case ActionType.updatedReportStatus:
        return Icons.update;
      case ActionType.createdReport:
        return Icons.add_circle_outline;
      case ActionType.viewedReport:
      default:
        return Icons.article_outlined;
    }
  }

  Color _getActionColor() {
    switch (history.actionType) {
      case ActionType.reviewedRequest:
        return AppColors.info;
      case ActionType.updatedReportStatus:
        return AppColors.success;
      case ActionType.createdReport:
        return AppColors.primaryGreen;
      case ActionType.viewedReport:
      default:
        return AppColors.textSecondary;
    }
  }

  String _getActionTitle(AppLocalizations l10n) {
    switch (history.actionType) {
      case ActionType.reviewedRequest:
        return l10n.get('reviewed_request');
      case ActionType.updatedReportStatus:
        return l10n.get('updated_status');
      case ActionType.createdReport:
        return l10n.get('created_report');
      case ActionType.viewedReport:
      default:
        return l10n.get('viewed_report');
    }
  }
}
