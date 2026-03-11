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
import 'employee_add_report_screen.dart';
import 'report_detail_screen.dart';

class EmployeeHomeScreen extends StatefulWidget {
  const EmployeeHomeScreen({super.key});

  @override
  State<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen> {
  int _currentIndex = 0;
  ReportStatus? _statusFilter;

  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final screens = [
      _buildReportsTab(l10n),
      const EmployeeAddReportScreen(),
      // const HistoryScreen(),
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
            icon: const Icon(Icons.article_outlined),
            activeIcon: const Icon(Icons.article),
            label: l10n.get('reports'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.add_circle_outline),
            activeIcon: const Icon(Icons.add_circle),
            label: l10n.get('add_report'),
          ),
          // BottomNavigationBarItem(
          //   icon: const Icon(Icons.history_outlined),
          //   activeIcon: const Icon(Icons.history),
          //   label: l10n.get('history'),
          // ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_outlined),
            activeIcon: const Icon(Icons.settings),
            label: l10n.get('settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsTab(AppLocalizations l10n) {
    return Column(
      children: [
        _buildFilterChips(l10n),
        Expanded(
          child: StreamBuilder<List<ReportModel>>(
            stream: _firestoreService.reportsStream(status: _statusFilter),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const ShimmerListLoading();
              }

              final reports = snapshot.data ?? [];

              if (reports.isEmpty) {
                return EmptyStateWidget(
                  icon: Icons.article_outlined,
                  title: l10n.get('no_reports'),
                  subtitle: 'No reports match your filter',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  final report = reports[index];
                  return ReportCard(
                    report: report,
                    onTap: () => _openReportDetail(report),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(AppLocalizations l10n) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildChip(l10n.get('all'), _statusFilter == null, () {
            setState(() => _statusFilter = null);
          }),
          const SizedBox(width: 8),
          _buildChip(
              l10n.get('in_progress'), _statusFilter == ReportStatus.inProgress,
              () {
            setState(() => _statusFilter = ReportStatus.inProgress);
          }),
          const SizedBox(width: 8),
          _buildChip(l10n.get('matched'), _statusFilter == ReportStatus.matched,
              () {
            setState(() => _statusFilter = ReportStatus.matched);
          }),
          const SizedBox(width: 8),
          _buildChip(
              l10n.get('rejected'), _statusFilter == ReportStatus.rejected, () {
            setState(() => _statusFilter = ReportStatus.rejected);
          }),
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

  void _openReportDetail(ReportModel report) async {
    final userId = context.read<AuthProvider>().currentUser?.userId;
    final role = context.read<AuthProvider>().currentUser?.role;

    if (userId != null && role != null) {
      final historyId = Helpers.generateId();
      await _firestoreService.logHistory(HistoryModel(
        historyId: historyId,
        actorId: userId,
        actorRole: role.name,
        actionType: ActionType.viewedReport,
        targetId: report.reportId,
        timestamp: DateTime.now(),
      ));
    }

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportDetailScreen(report: report),
      ),
    );
  }
}
