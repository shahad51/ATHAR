import 'package:athar_app/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/utils/helpers.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';

class ReportDetailScreen extends StatefulWidget {
  final ReportModel report;

  const ReportDetailScreen({super.key, required this.report});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  bool _isUpdating = false;
  final FirestoreService _firestoreService = FirestoreService();
  String? _selectedMatchId;
  List<ReportModel> _potentialMatches = [];

  @override
  void initState() {
    super.initState();
    _loadPotentialMatches();
  }

  Future<void> _loadPotentialMatches() async {
    final oppositeType = widget.report.reportType == ReportType.lost
        ? ReportType.found
        : ReportType.lost;

    final matches = await _firestoreService.getFoundReports(
      itemType: widget.report.itemType,
      itemColor: widget.report.itemColor,
      itemLocation: widget.report.itemLocation,
    );

    setState(() {
      _potentialMatches = matches
          .where((r) =>
              r.reportType == oppositeType &&
              r.status == ReportStatus.inProgress)
          .toList();
    });
  }

  Future<void> _updateStatus(ReportStatus status) async {
    if (status == ReportStatus.matched &&
        _selectedMatchId == null &&
        _potentialMatches.isNotEmpty) {
      _showMatchSelectionDialog();
      return;
    }

    setState(() => _isUpdating = true);

    final reportsProvider = context.read<ReportsProvider>();
    await reportsProvider.updateReportStatus(
      widget.report.reportId,
      status,
      widget.report.submittedBy,
    );

    if (status == ReportStatus.matched && _selectedMatchId != null) {
      final matchedReport =
          await _firestoreService.getReport(_selectedMatchId!);
      if (matchedReport != null) {
        await _firestoreService.updateReport(_selectedMatchId!, {
          'status': 'Matched',
          'matchedReportId': widget.report.reportId,
        });

        await _firestoreService.updateReport(widget.report.reportId, {
          'matchedReportId': _selectedMatchId,
        });

        await reportsProvider.updateReportStatus(
          _selectedMatchId!,
          ReportStatus.matched,
          matchedReport.submittedBy,
        );
      }
    }

    setState(() => _isUpdating = false);

    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    final userId = context.read<AuthProvider>().currentUser?.userId;
    final role = context.read<AuthProvider>().currentUser?.role;

    // Log status update history
    if (userId != null) {
      await _firestoreService.logHistory(HistoryModel(
        historyId: Helpers.generateId(),
        actorId: userId,
        actorRole: role?.name ?? 'unknown',
        actionType: ActionType.updatedReportStatus,
        targetId: widget.report.reportId,
        timestamp: DateTime.now(),
        details: 'Status changed to ${Helpers.getStatusText(status)}',
      ));
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(status == ReportStatus.matched && _selectedMatchId != null
            ? l10n.get('match_approved_both_updated')
            : 'Status updated to ${Helpers.getStatusText(status)}'),
        backgroundColor: AppColors.success,
      ),
    );
    Navigator.pop(context);
  }

  void _showMatchSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text(AppLocalizations.of(context)!.get('select_matching_report')),
        content: SizedBox(
          width: double.maxFinite,
          child: _potentialMatches.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(AppLocalizations.of(context)!
                      .get('no_potential_matches')),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _potentialMatches.length,
                  itemBuilder: (context, index) {
                    final match = _potentialMatches[index];
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          match.reportType == ReportType.lost
                              ? Icons.search_off
                              : Icons.check_circle_outline,
                          color: match.reportType == ReportType.lost
                              ? AppColors.error
                              : AppColors.success,
                        ),
                        title: Text('${match.itemType} - ${match.itemColor}'),
                        subtitle: Text(
                            '${match.itemLocation}\n${Helpers.formatDateTime(match.submissionDate)}'),
                        isThreeLine: true,
                        trailing: Radio<String>(
                          value: match.reportId,
                          groupValue: _selectedMatchId,
                          onChanged: (value) {
                            setState(() => _selectedMatchId = value);
                            Navigator.pop(context);
                            _updateStatus(ReportStatus.matched);
                          },
                        ),
                        onTap: () {
                          setState(() => _selectedMatchId = match.reportId);
                          Navigator.pop(context);
                          _updateStatus(ReportStatus.matched);
                        },
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _selectedMatchId = null);
              _updateStatus(ReportStatus.matched);
            },
            child: Text(AppLocalizations.of(context)!.get('skip_matching')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.get('cancel')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final role = context.read<AuthProvider>().currentUser?.role;
    final canUpdateStatus = role == UserRole.employee || role == UserRole.admin;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('report_details')),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImage(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(l10n),
                  const Divider(height: 32),
                  _buildDetailRow(
                      l10n.get('item_type'), widget.report.itemType),
                  _buildDetailRow(
                      l10n.get('item_color'), widget.report.itemColor),
                  _buildDetailRow(
                      l10n.get('item_location'), widget.report.itemLocation),
                  _buildDetailRow(l10n.get('submission_date'),
                      Helpers.formatDateTime(widget.report.submissionDate)),
                  if (widget.report.isCenterSubmitted)
                    _buildDetailRow(
                        l10n.get('center_submitted'), l10n.get('yes')),
                  if (widget.report.isManualEntry)
                    _buildDetailRow(l10n.get('manual_entry'), l10n.get('yes')),
                  const SizedBox(height: 24),
                  if (_potentialMatches.isNotEmpty && canUpdateStatus)
                    _buildPotentialMatches(l10n),
                  if (canUpdateStatus &&
                      widget.report.status == ReportStatus.inProgress)
                    _buildActionButtons(l10n),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (widget.report.imageUrl == null) {
      return Container(
        height: 250,
        color: AppColors.background,
        child: const Center(
          child: Icon(Icons.image_not_supported,
              size: 64, color: AppColors.textHint),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: widget.report.imageUrl!,
      height: 250,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        height: 250,
        color: AppColors.background,
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => Container(
        height: 250,
        color: AppColors.background,
        child: const Center(
          child: Icon(Icons.error_outline, size: 64, color: AppColors.error),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: widget.report.reportType == ReportType.lost
                          ? AppColors.error.withOpacity(0.1)
                          : AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.report.reportType == ReportType.lost
                          ? l10n.get('lost')
                          : l10n.get('found'),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: widget.report.reportType == ReportType.lost
                            ? AppColors.error
                            : AppColors.success,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Helpers.getStatusColor(widget.report.status)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      Helpers.getStatusText(widget.report.status),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Helpers.getStatusColor(widget.report.status),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Report #${widget.report.reportId.substring(0, 8)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPotentialMatches(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.get('potential_matches'),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
        ),
        const SizedBox(height: 12),
        ..._potentialMatches.take(3).map((match) {
          final matchPercentage = _calculateMatchPercentage(match);
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getMatchColor(matchPercentage).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${matchPercentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getMatchColor(matchPercentage),
                  ),
                ),
              ),
              title: Text('${match.itemType} - ${match.itemColor}'),
              subtitle: Text(
                '${match.itemLocation}\n${Helpers.formatDateTime(match.submissionDate)}',
              ),
              isThreeLine: true,
              trailing: Icon(
                match.reportType == ReportType.lost
                    ? Icons.search_off
                    : Icons.check_circle_outline,
                color: match.reportType == ReportType.lost
                    ? AppColors.error
                    : AppColors.success,
              ),
            ),
          );
        }).toList(),
        const SizedBox(height: 16),
      ],
    );
  }

  double _calculateMatchPercentage(ReportModel match) {
    int matchPoints = 0;
    int totalPoints = 0;

    // Item type match (40 points)
    totalPoints += 40;
    if (match.itemType.toLowerCase() == widget.report.itemType.toLowerCase()) {
      matchPoints += 40;
    }

    // Item color match (30 points)
    totalPoints += 30;
    if (match.itemColor.toLowerCase() == widget.report.itemColor.toLowerCase()) {
      matchPoints += 30;
    }

    // Location match (30 points)
    totalPoints += 30;
    if (match.itemLocation.toLowerCase().contains(widget.report.itemLocation.toLowerCase()) ||
        widget.report.itemLocation.toLowerCase().contains(match.itemLocation.toLowerCase())) {
      matchPoints += 30;
    }

    return (matchPoints / totalPoints) * 100;
  }

  Color _getMatchColor(double percentage) {
    if (percentage >= 80) return AppColors.success;
    if (percentage >= 60) return AppColors.warning;
    return AppColors.error;
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Update Status',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: l10n.get('mark_matched'),
                onPressed: _isUpdating
                    ? null
                    : () => _updateStatus(ReportStatus.matched),
                isLoading: _isUpdating,
                backgroundColor: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                text: l10n.get('mark_rejected'),
                onPressed: _isUpdating
                    ? null
                    : () => _updateStatus(ReportStatus.rejected),
                isLoading: _isUpdating,
                backgroundColor: AppColors.error,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
