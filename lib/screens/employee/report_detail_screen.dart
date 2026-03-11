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

  Future<void> _updateStatus(ReportStatus status) async {
    setState(() => _isUpdating = true);

    final reportsProvider = context.read<ReportsProvider>();
    await reportsProvider.updateReportStatus(
      widget.report.reportId,
      status,
      widget.report.submittedBy,
    );

    setState(() => _isUpdating = false);

    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Status updated to ${Helpers.getStatusText(status)}'),
        backgroundColor: AppColors.success,
      ),
    );
    Navigator.pop(context);
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
