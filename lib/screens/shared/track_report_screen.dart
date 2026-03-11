import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/utils/helpers.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';

class TrackReportScreen extends StatefulWidget {
  const TrackReportScreen({super.key});

  @override
  State<TrackReportScreen> createState() => _TrackReportScreenState();
}

class _TrackReportScreenState extends State<TrackReportScreen> {
  final _referenceIdController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSearching = false;
  ReportModel? _report;
  String? _error;

  @override
  void dispose() {
    _referenceIdController.dispose();
    super.dispose();
  }

  Future<void> _searchReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSearching = true;
      _error = null;
      _report = null;
    });

    try {
      final referenceId = _referenceIdController.text.trim().toUpperCase();

      final querySnapshot = await FirebaseFirestore.instance
          .collection('reports')
          .where('referenceId', isEqualTo: referenceId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        setState(() {
          _error = 'No report found with this Reference ID';
          _isSearching = false;
        });
        return;
      }

      final reportData = querySnapshot.docs.first.data();
      setState(() {
        _report = ReportModel.fromJson(reportData);
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error searching for report. Please try again.';
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Report'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildSearchForm(l10n),
            const SizedBox(height: 24),
            if (_isSearching) const Center(child: CircularProgressIndicator()),
            if (_error != null) _buildError(),
            if (_report != null) _buildReportDetails(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.search,
            size: 48,
            color: AppColors.primaryGreen,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Track Your Report',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your Reference ID to track the status of your report',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSearchForm(AppLocalizations l10n) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomTextField(
            controller: _referenceIdController,
            label: 'Reference ID',
            hint: 'e.g., ATH-2024-123456',
            prefixIcon: Icon(Icons.tag),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter Reference ID';
              }
              if (!RegExp(r'^ATH-\d{4}-\d{6}$').hasMatch(value.toUpperCase())) {
                return 'Invalid format. Use: ATH-YYYY-XXXXXX';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: 'Search',
            onPressed: _searchReport,
            isLoading: _isSearching,
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportDetails(AppLocalizations l10n) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Helpers.getStatusColor(_report!.status)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _report!.reportType == ReportType.lost
                        ? Icons.search
                        : Icons.inventory_2,
                    color: Helpers.getStatusColor(_report!.status),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _report!.reportType == ReportType.lost
                            ? 'Lost Item'
                            : 'Found Item',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      Text(
                        _report!.referenceId,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Helpers.getStatusColor(_report!.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    Helpers.getStatusText(_report!.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            _buildDetailRow(Icons.category, 'Item Type', _report!.itemType),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.palette, 'Color', _report!.itemColor),
            const SizedBox(height: 12),
            _buildDetailRow(
                Icons.location_on, 'Location', _report!.itemLocation),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.calendar_today,
              'Submitted',
              Helpers.formatDate(_report!.submissionDate),
            ),
            if (_report!.imageUrl != null) ...[
              const Divider(height: 32),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  _report!.imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported, size: 48),
                    );
                  },
                ),
              ),
            ],
            if (_report!.status == ReportStatus.matched) ...[
              const Divider(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.success),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Great news! Your item has been matched. Please contact the Lost & Found center for collection.',
                        style: TextStyle(
                          color: AppColors.success.withOpacity(0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
