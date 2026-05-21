import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';
import '../../widgets/widgets.dart';

class ReportsExportScreen extends StatefulWidget {
  const ReportsExportScreen({super.key});

  @override
  State<ReportsExportScreen> createState() => _ReportsExportScreenState();
}

class _ReportsExportScreenState extends State<ReportsExportScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isGenerating = false;
  DateTime? _startDate;
  DateTime? _endDate;
  ReportType? _selectedType;
  ReportStatus? _selectedStatus;
  bool? _isCenterSubmitted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      // appBar: AppBar(
      //   title: Text(l10n.get('export_reports')),
      // ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.get('filter_options'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _buildDateRangePicker(l10n),
                    const SizedBox(height: 16),
                    _buildTypeFilter(l10n),
                    const SizedBox(height: 16),
                    _buildStatusFilter(l10n),
                    const SizedBox(height: 16),
                    _buildSourceFilter(l10n),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildExportButtons(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangePicker(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.get('date_range'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _selectStartDate(),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.get('start_date'),
                    border: const OutlineInputBorder(),
                  ),
                  child: Text(
                    _startDate != null
                        ? DateFormat('yyyy-MM-dd').format(_startDate!)
                        : l10n.get('select_date'),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () => _selectEndDate(),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.get('end_date'),
                    border: const OutlineInputBorder(),
                  ),
                  child: Text(
                    _endDate != null
                        ? DateFormat('yyyy-MM-dd').format(_endDate!)
                        : l10n.get('select_date'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeFilter(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.get('report_type'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<ReportType?>(
          value: _selectedType,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          items: [
            DropdownMenuItem(value: null, child: Text(l10n.get('all'))),
            DropdownMenuItem(
                value: ReportType.lost, child: Text(l10n.get('lost'))),
            DropdownMenuItem(
                value: ReportType.found, child: Text(l10n.get('found'))),
          ],
          onChanged: (value) => setState(() => _selectedType = value),
        ),
      ],
    );
  }

  Widget _buildStatusFilter(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.get('status'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<ReportStatus?>(
          value: _selectedStatus,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          items: [
            DropdownMenuItem(value: null, child: Text(l10n.get('all'))),
            DropdownMenuItem(
                value: ReportStatus.inProgress,
                child: Text(l10n.get('in_progress'))),
            DropdownMenuItem(
                value: ReportStatus.matched, child: Text(l10n.get('matched'))),
            DropdownMenuItem(
                value: ReportStatus.rejected,
                child: Text(l10n.get('rejected'))),
          ],
          onChanged: (value) => setState(() => _selectedStatus = value),
        ),
      ],
    );
  }

  Widget _buildSourceFilter(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.get('report_source'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<bool?>(
          value: _isCenterSubmitted,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          items: [
            DropdownMenuItem(value: null, child: Text(l10n.get('all'))),
            DropdownMenuItem(
                value: true, child: Text(l10n.get('center_submitted'))),
            DropdownMenuItem(
                value: false, child: Text(l10n.get('user_submitted'))),
          ],
          onChanged: (value) => setState(() => _isCenterSubmitted = value),
        ),
      ],
    );
  }

  Widget _buildExportButtons(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomButton(
          text: l10n.get('generate_csv_report'),
          onPressed: _isGenerating ? null : _generateCSVReport,
          isLoading: _isGenerating,
          icon: Icons.table_chart,
        ),
        const SizedBox(height: 12),
        CustomButton(
          text: l10n.get('generate_summary_report'),
          onPressed: _isGenerating ? null : _generateSummaryReport,
          isLoading: _isGenerating,
          icon: Icons.summarize,
          isOutlined: true,
        ),
      ],
    );
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _startDate = date);
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _endDate = date);
    }
  }

  Future<void> _generateCSVReport() async {
    setState(() => _isGenerating = true);

    try {
      final reports = await _fetchFilteredReports();

      if (reports.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  AppLocalizations.of(context)!.get('no_reports_to_export')),
              backgroundColor: AppColors.warning,
            ),
          );
        }
        setState(() => _isGenerating = false);
        return;
      }

      final csvData = _convertToCSV(reports);
      await _saveAndShareFile(csvData, 'reports_export.csv');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(AppLocalizations.of(context)!.get('report_generated')),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    setState(() => _isGenerating = false);
  }

  Future<void> _generateSummaryReport() async {
    setState(() => _isGenerating = true);

    try {
      final reports = await _fetchFilteredReports();

      if (reports.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  AppLocalizations.of(context)!.get('no_reports_to_export')),
              backgroundColor: AppColors.warning,
            ),
          );
        }
        setState(() => _isGenerating = false);
        return;
      }

      final summary = _generateSummary(reports);
      await _saveAndShareFile(summary, 'reports_summary.txt');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(AppLocalizations.of(context)!.get('report_generated')),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    setState(() => _isGenerating = false);
  }

  Future<List<ReportModel>> _fetchFilteredReports() async {
    // Fetch all reports and filter in memory
    final allReports = await _firestoreService
        .reportsStream(
          reportType: _selectedType,
          status: _selectedStatus,
          isCenterSubmitted: _isCenterSubmitted,
        )
        .first;

    if (_startDate == null && _endDate == null) {
      return allReports;
    }

    return allReports.where((report) {
      if (_startDate != null && report.submissionDate.isBefore(_startDate!)) {
        return false;
      }
      if (_endDate != null &&
          report.submissionDate
              .isAfter(_endDate!.add(const Duration(days: 1)))) {
        return false;
      }
      return true;
    }).toList();
  }

  String _convertToCSV(List<ReportModel> reports) {
    final List<List<dynamic>> rows = [
      [
        'Report ID',
        'Reference ID',
        'Type',
        'Item Type',
        'Item Color',
        'Location',
        'Status',
        'Submission Date',
        'Source',
        'Matched Report ID'
      ]
    ];

    for (final report in reports) {
      rows.add([
        report.reportId,
        report.referenceId,
        report.reportType.name,
        report.itemType,
        report.itemColor,
        report.itemLocation,
        report.status.name,
        DateFormat('yyyy-MM-dd HH:mm').format(report.submissionDate),
        report.isCenterSubmitted ? 'Center' : 'User',
        report.matchedReportId ?? 'N/A',
      ]);
    }

    return _convertRowsToCSV(rows);
  }

  String _generateSummary(List<ReportModel> reports) {
    final totalReports = reports.length;
    final lostReports =
        reports.where((r) => r.reportType == ReportType.lost).length;
    final foundReports =
        reports.where((r) => r.reportType == ReportType.found).length;
    final matchedReports =
        reports.where((r) => r.status == ReportStatus.matched).length;
    final inProgressReports =
        reports.where((r) => r.status == ReportStatus.inProgress).length;
    final rejectedReports =
        reports.where((r) => r.status == ReportStatus.rejected).length;
    final centerSubmitted = reports.where((r) => r.isCenterSubmitted).length;
    final userSubmitted = reports.where((r) => !r.isCenterSubmitted).length;

    final buffer = StringBuffer();
    buffer.writeln('ATHAR - Reports Summary');
    buffer.writeln(
        'Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}');
    buffer.writeln('=' * 50);
    buffer.writeln();

    if (_startDate != null || _endDate != null) {
      buffer.writeln('Date Range:');
      if (_startDate != null) {
        buffer
            .writeln('  From: ${DateFormat('yyyy-MM-dd').format(_startDate!)}');
      }
      if (_endDate != null) {
        buffer.writeln('  To: ${DateFormat('yyyy-MM-dd').format(_endDate!)}');
      }
      buffer.writeln();
    }

    buffer.writeln('Total Reports: $totalReports');
    buffer.writeln();

    buffer.writeln('By Type:');
    buffer.writeln(
        '  Lost: $lostReports (${_percentage(lostReports, totalReports)}%)');
    buffer.writeln(
        '  Found: $foundReports (${_percentage(foundReports, totalReports)}%)');
    buffer.writeln();

    buffer.writeln('By Status:');
    buffer.writeln(
        '  In Progress: $inProgressReports (${_percentage(inProgressReports, totalReports)}%)');
    buffer.writeln(
        '  Matched: $matchedReports (${_percentage(matchedReports, totalReports)}%)');
    buffer.writeln(
        '  Rejected: $rejectedReports (${_percentage(rejectedReports, totalReports)}%)');
    buffer.writeln();

    buffer.writeln('By Source:');
    buffer.writeln(
        '  Center Submitted: $centerSubmitted (${_percentage(centerSubmitted, totalReports)}%)');
    buffer.writeln(
        '  User Submitted: $userSubmitted (${_percentage(userSubmitted, totalReports)}%)');
    buffer.writeln();

    buffer.writeln('=' * 50);
    buffer.writeln('End of Report');

    return buffer.toString();
  }

  String _percentage(int value, int total) {
    if (total == 0) return '0.0';
    return ((value / total) * 100).toStringAsFixed(1);
  }

  String _convertRowsToCSV(List<List<dynamic>> rows) {
    return rows.map((row) {
      return row.map((cell) {
        final cellStr = cell.toString();
        // Escape quotes and wrap in quotes if contains comma, quote, or newline
        if (cellStr.contains(',') ||
            cellStr.contains('"') ||
            cellStr.contains('\n')) {
          return '"${cellStr.replaceAll('"', '""')}"';
        }
        return cellStr;
      }).join(',');
    }).join('\n');
  }

  Future<void> _saveAndShareFile(String content, String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$filename');
    await file.writeAsString(content);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'ATHAR Report Export',
    );
  }
}
