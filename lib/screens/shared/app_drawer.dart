import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../auth/login_screen.dart';
import 'settings_screen.dart';
import 'help_screen.dart';
import 'notifications_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Drawer(
      child: Column(
        children: [
          _buildHeader(context, user, l10n),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuItem(
                  context,
                  icon: Icons.home_outlined,
                  title: l10n.get('home'),
                  onTap: () => Navigator.pop(context),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.notifications_outlined,
                  title: l10n.get('notifications'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                    );
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.help_outline,
                  title: l10n.get('help'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HelpScreen()),
                    );
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.settings_outlined,
                  title: l10n.get('settings'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
                const Divider(),
                _buildMenuItem(
                  context,
                  icon: Icons.logout,
                  title: l10n.get('logout'),
                  onTap: () => _showLogoutDialog(context, l10n),
                  isDestructive: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserModel? user, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 24,
        bottom: 24,
        left: 16,
        right: 16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primaryGreen,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: Colors.white,
            child: Text(
              user != null ? '${user.firstName[0]}${user.lastName[0]}' : '?',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            user?.fullName ?? 'Guest',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getRoleLabel(user?.role, l10n),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? AppColors.error : AppColors.textSecondary,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? AppColors.error : AppColors.textPrimary,
        ),
      ),
      onTap: onTap,
    );
  }

  String _getRoleLabel(UserRole? role, AppLocalizations l10n) {
    switch (role) {
      case UserRole.employee:
        return l10n.get('employee');
      case UserRole.admin:
        return l10n.get('admin');
      case UserRole.manager:
        return l10n.get('manager');
      default:
        return l10n.get('regular_user');
    }
  }

  void _showLogoutDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.get('logout')),
          content: Text(l10n.get('logout_confirm')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.get('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await context.read<AuthProvider>().logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              child: Text(l10n.get('confirm')),
            ),
          ],
        );
      },
    );
  }
}
