import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';
import '../../widgets/widgets.dart';
import '../shared/app_drawer.dart';
import '../shared/notifications_screen.dart';
import '../shared/settings_screen.dart';
import '../shared/history_screen.dart';
import '../employee/report_detail_screen.dart';
import 'add_employee_screen.dart';
import 'reports_export_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;
  ReportStatus? _statusFilter;
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final screens = [
      _buildDashboardTab(l10n),
      _buildReportsTab(l10n),
      const HistoryScreen(),
      const ReportsExportScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('app_name')),
      ),
      drawer: const AppDrawer(),
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard_outlined),
            activeIcon: const Icon(Icons.dashboard),
            label: l10n.get('dashboard'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.article_outlined),
            activeIcon: const Icon(Icons.article),
            label: l10n.get('reports'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history_outlined),
            activeIcon: const Icon(Icons.history),
            label: l10n.get('history'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.assessment_outlined),
            activeIcon: const Icon(Icons.assessment),
            label: l10n.get('export_reports'),
          ),
        ],
      ),
    );
  }

  void _sendMaintenanceNotification() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Maintenance Notice'),
        content: const Text(
            'This will notify all users about system maintenance. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _notificationService.sendMaintenanceNotification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maintenance notification sent to all users'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Widget _buildDashboardTab(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStatsCards(l10n),
          const SizedBox(height: 24),
          _buildStatusChart(l10n),
          const SizedBox(height: 24),
          _buildCenterSubmittedSection(l10n),
        ],
      ),
    );
  }

  Widget _buildStatsCards(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: FutureBuilder<int>(
            future: _firestoreService.getReportsCount24h(),
            builder: (context, snapshot) {
              return _buildStatCard(
                l10n.get('reports_24h'),
                snapshot.data?.toString() ?? '...',
                Icons.article_outlined,
                AppColors.info,
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FutureBuilder<String?>(
            future: _firestoreService.getTopReportedLocation(),
            builder: (context, snapshot) {
              return _buildStatCard(
                l10n.get('top_location'),
                snapshot.data ?? '--',
                Icons.location_on_outlined,
                AppColors.warning,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChart(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reports by Status',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            FutureBuilder<Map<String, int>>(
              future: _firestoreService.getReportsCountByStatus(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final data = snapshot.data!;
                final total = data.values.fold(0, (a, b) => a + b);

                if (total == 0) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: Text('No data available')),
                  );
                }

                return SizedBox(
                  height: 200,
                  child: Row(
                    children: [
                      Expanded(
                        child: PieChart(
                          PieChartData(
                            sections: [
                              PieChartSectionData(
                                value: data['InProgress']?.toDouble() ?? 0,
                                color: AppColors.statusInProgress,
                                title: '${data['InProgress'] ?? 0}',
                                titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              PieChartSectionData(
                                value: data['Matched']?.toDouble() ?? 0,
                                color: AppColors.statusMatched,
                                title: '${data['Matched'] ?? 0}',
                                titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              PieChartSectionData(
                                value: data['Rejected']?.toDouble() ?? 0,
                                color: AppColors.statusRejected,
                                title: '${data['Rejected'] ?? 0}',
                                titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLegendItem(l10n.get('in_progress'),
                              AppColors.statusInProgress),
                          const SizedBox(height: 8),
                          _buildLegendItem(
                              l10n.get('matched'), AppColors.statusMatched),
                          const SizedBox(height: 8),
                          _buildLegendItem(
                              l10n.get('rejected'), AppColors.statusRejected),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildCenterSubmittedSection(AppLocalizations l10n) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _currentIndex = 1; // Switch to Reports tab
              _statusFilter = null;
            });
            // TODO: Add filter for center submitted
          },
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.get('center_submitted'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textHint),
                    ],
                  ),
                const SizedBox(height: 16),
                StreamBuilder<List<ReportModel>>(
                  stream:
                      _firestoreService.reportsStream(isCenterSubmitted: true),
                  builder: (context, snapshot) {
                    final reports = snapshot.data ?? [];
                    final lostCount = reports
                        .where((r) => r.reportType == ReportType.lost)
                        .length;
                    final foundCount = reports
                        .where((r) => r.reportType == ReportType.found)
                        .length;

                    return Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '$lostCount',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.error,
                                      ),
                                ),
                                Text(l10n.get('lost')),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '$foundCount',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.success,
                                      ),
                                ),
                                Text(l10n.get('found')),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () {
            setState(() {
              _currentIndex = 1; // Switch to Reports tab
              _statusFilter = null;
            });
            // TODO: Add filter for user submitted
          },
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.get('user_submitted'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textHint),
                    ],
                  ),
                const SizedBox(height: 16),
                StreamBuilder<List<ReportModel>>(
                  stream:
                      _firestoreService.reportsStream(isCenterSubmitted: false),
                  builder: (context, snapshot) {
                    final reports = snapshot.data ?? [];
                    final lostCount = reports
                        .where((r) => r.reportType == ReportType.lost)
                        .length;
                    final foundCount = reports
                        .where((r) => r.reportType == ReportType.found)
                        .length;

                    return Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '$lostCount',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.error,
                                      ),
                                ),
                                Text(l10n.get('lost')),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '$foundCount',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.success,
                                      ),
                                ),
                                Text(l10n.get('found')),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        ),
      ],
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
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  return ReportCard(
                    report: reports[index],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ReportDetailScreen(report: reports[index]),
                      ),
                    ),
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
}
