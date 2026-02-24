import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';
import '../../widgets/widgets.dart';
import '../shared/app_drawer.dart';
import '../shared/notifications_screen.dart';
import '../shared/settings_screen.dart';
import 'search_screen.dart';
import 'report_lost_item_screen.dart';
import 'report_found_item_screen.dart';
import 'gps_tracking_dialog.dart';

class RegularUserHomeScreen extends StatefulWidget {
  const RegularUserHomeScreen({super.key});

  @override
  State<RegularUserHomeScreen> createState() => _RegularUserHomeScreenState();
}

class _RegularUserHomeScreenState extends State<RegularUserHomeScreen> {
  int _currentIndex = 0;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _checkFirstLogin();
  }

  void _checkFirstLogin() {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isFirstLogin && authProvider.currentUser?.role == UserRole.regular) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const GpsTrackingDialog(),
        ).then((_) {
          authProvider.setFirstLoginComplete();
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final screens = [
      _DashboardTab(firestoreService: _firestoreService),
      const SearchScreen(),
      const NotificationsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('app_name_arabic')),
        actions: [
          _buildNotificationBadge(),
        ],
      ),
      drawer: const AppDrawer(),
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: l10n.get('home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.search_outlined),
            activeIcon: const Icon(Icons.search),
            label: l10n.get('search'),
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
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _showReportOptions,
              icon: const Icon(Icons.add),
              label: Text(l10n.get('add_report')),
            )
          : null,
    );
  }

  Widget _buildNotificationBadge() {
    final userId = context.read<AuthProvider>().currentUser?.userId;
    if (userId == null) return const SizedBox.shrink();

    return FutureBuilder<int>(
      future: _firestoreService.getUnreadNotificationCount(userId),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => setState(() => _currentIndex = 2),
            ),
            if (count > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    count > 9 ? '9+' : '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showReportOptions() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'What would you like to report?',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.search_off, color: AppColors.error),
                  ),
                  title: Text(l10n.get('report_lost')),
                  subtitle: const Text('Report an item you have lost'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ReportLostItemScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.check_circle_outline, color: AppColors.success),
                  ),
                  title: Text(l10n.get('report_found')),
                  subtitle: const Text('Report an item you have found'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ReportFoundItemScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DashboardTab extends StatelessWidget {
  final FirestoreService firestoreService;

  const _DashboardTab({required this.firestoreService});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final userId = context.read<AuthProvider>().currentUser?.userId;

    if (userId == null) {
      return const Center(child: Text('Please login'));
    }

    return RefreshIndicator(
      onRefresh: () async {},
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.get('my_lost_reports'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            _buildReportsList(userId, ReportType.lost, l10n),
            const SizedBox(height: 24),
            Text(
              l10n.get('my_found_reports'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            _buildReportsList(userId, ReportType.found, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsList(String userId, ReportType type, AppLocalizations l10n) {
    return StreamBuilder<List<ReportModel>>(
      stream: firestoreService.reportsStream(
        submittedBy: userId,
        reportType: type,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ShimmerListLoading(itemCount: 2, itemHeight: 100);
        }

        final reports = snapshot.data ?? [];

        if (reports.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  l10n.get('no_reports'),
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reports.length > 3 ? 3 : reports.length,
          itemBuilder: (context, index) {
            return ReportCard(report: reports[index]);
          },
        );
      },
    );
  }
}
