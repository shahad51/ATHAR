import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final role = context.read<AuthProvider>().currentUser?.role ?? UserRole.regular;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('help')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _buildContent(context, role, l10n),
        ),
      ),
    );
  }

  List<Widget> _buildContent(BuildContext context, UserRole role, AppLocalizations l10n) {
    switch (role) {
      case UserRole.admin:
        return _buildAdminContent(context, l10n);
      case UserRole.employee:
        return _buildEmployeeContent(context, l10n);
      case UserRole.manager:
        return _buildManagerContent(context, l10n);
      default:
        return _buildRegularUserContent(context, l10n);
    }
  }

  List<Widget> _buildRegularUserContent(BuildContext context, AppLocalizations l10n) {
    return [
      _buildSection(
        context,
        title: l10n.get('faqs'),
        icon: Icons.help_outline,
        children: [
          _buildFaqItem(
            context,
            question: 'How do I report a lost item?',
            answer: 'Tap the + button on the home screen, select "Report Lost Item", fill in the details about your lost item including type, color, and location where you lost it.',
          ),
          _buildFaqItem(
            context,
            question: 'How do I report a found item?',
            answer: 'Tap the + button on the home screen, select "Report Found Item", take a photo of the item and fill in the required details. The app will show you the nearest collection center.',
          ),
          _buildFaqItem(
            context,
            question: 'How does the matching system work?',
            answer: 'Our AI-powered system compares your lost item description with found items in the database. You\'ll receive a notification when a potential match is found.',
          ),
          _buildFaqItem(
            context,
            question: 'Where can I collect my matched item?',
            answer: 'When a match is found, you\'ll be notified with the location of the Lost & Found center holding your item. The app will provide directions to the center.',
          ),
          _buildFaqItem(
            context,
            question: 'Why does the app need my location?',
            answer: 'Location tracking helps validate your reported locations and provides directions to nearby collection centers. Your movement data is private and only used for validation.',
          ),
        ],
      ),
      const SizedBox(height: 24),
      _buildSection(
        context,
        title: l10n.get('how_to_use'),
        icon: Icons.school_outlined,
        children: [
          _buildStepItem(context, '1', 'Register and complete your profile'),
          _buildStepItem(context, '2', 'Enable location tracking for better service'),
          _buildStepItem(context, '3', 'Report lost or found items with photos'),
          _buildStepItem(context, '4', 'Wait for matching notifications'),
          _buildStepItem(context, '5', 'Collect matched items from centers'),
        ],
      ),
      const SizedBox(height: 24),
      _buildSection(
        context,
        title: l10n.get('contact_us'),
        icon: Icons.contact_support_outlined,
        children: [
          _buildContactItem(context, Icons.email, 'support@athar.app'),
          _buildContactItem(context, Icons.phone, '+966 12 345 6789'),
          _buildContactItem(context, Icons.access_time, 'Available 24/7 during Hajj season'),
        ],
      ),
    ];
  }

  List<Widget> _buildAdminContent(BuildContext context, AppLocalizations l10n) {
    return [
      _buildSection(
        context,
        title: l10n.get('dashboard_guide'),
        icon: Icons.dashboard_outlined,
        children: [
          _buildGuideItem(context, 'Dashboard Overview', 'View real-time statistics including reports in the last 24 hours, top reported locations, and status distribution charts.'),
          _buildGuideItem(context, 'Reports Management', 'Access all reports submitted by users and center employees. Use filters to find specific reports by status, location, or date.'),
          _buildGuideItem(context, 'Center Submitted Reports', 'Review reports submitted by Lost & Found center employees. These are marked with a "Center" badge.'),
          _buildGuideItem(context, 'Analytics', 'Use the charts to understand trends and identify areas that need attention.'),
        ],
      ),
      const SizedBox(height: 24),
      _buildSection(
        context,
        title: l10n.get('technical_support'),
        icon: Icons.build_outlined,
        children: [
          _buildContactItem(context, Icons.email, 'admin-support@athar.app'),
          _buildContactItem(context, Icons.phone, '+966 12 345 6790'),
          _buildContactItem(context, Icons.access_time, 'Technical support: 8 AM - 10 PM'),
        ],
      ),
    ];
  }

  List<Widget> _buildEmployeeContent(BuildContext context, AppLocalizations l10n) {
    return [
      _buildSection(
        context,
        title: l10n.get('submit_reports_guide'),
        icon: Icons.article_outlined,
        children: [
          _buildGuideItem(context, 'Adding Manual Reports', 'Use the "Add Report" tab to submit reports on behalf of pilgrims who bring items to your center.'),
          _buildGuideItem(context, 'Updating Report Status', 'When viewing a report, use the status buttons to mark items as "Matched" or "Rejected".'),
          _buildGuideItem(context, 'Viewing All Reports', 'Access the Reports tab to see all submitted reports. Use filters to find specific reports.'),
          _buildGuideItem(context, 'Notifications', 'You will receive notifications when new reports are submitted that need your attention.'),
        ],
      ),
      const SizedBox(height: 24),
      _buildSection(
        context,
        title: l10n.get('user_policy'),
        icon: Icons.policy_outlined,
        children: [
          _buildPolicyItem(context, 'Handle all pilgrim data with care and confidentiality'),
          _buildPolicyItem(context, 'Verify item ownership before releasing matched items'),
          _buildPolicyItem(context, 'Document all transactions in the system'),
          _buildPolicyItem(context, 'Report any suspicious activities to your supervisor'),
          _buildPolicyItem(context, 'Maintain professional conduct with all users'),
        ],
      ),
    ];
  }

  List<Widget> _buildManagerContent(BuildContext context, AppLocalizations l10n) {
    return [
      _buildSection(
        context,
        title: 'Account Management',
        icon: Icons.manage_accounts_outlined,
        children: [
          _buildGuideItem(context, 'Reviewing Requests', 'Access pending account requests from the Requests tab. Review each application carefully before approving or rejecting.'),
          _buildGuideItem(context, 'Approval Process', 'When approving, the user will receive a notification and can immediately log in with their credentials.'),
          _buildGuideItem(context, 'Rejection Process', 'When rejecting, provide a valid reason. The user will be notified of the rejection.'),
          _buildGuideItem(context, 'History', 'View your review history in the History tab to track all your decisions.'),
        ],
      ),
      const SizedBox(height: 24),
      _buildSection(
        context,
        title: l10n.get('contact_us'),
        icon: Icons.contact_support_outlined,
        children: [
          _buildContactItem(context, Icons.email, 'manager-support@athar.app'),
          _buildContactItem(context, Icons.phone, '+966 12 345 6791'),
        ],
      ),
    ];
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primaryGreen),
                const SizedBox(width: 12),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(BuildContext context, {required String question, required String answer}) {
    return ExpansionTile(
      title: Text(question, style: Theme.of(context).textTheme.titleMedium),
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 16),
      children: [
        Text(answer, style: TextStyle(color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildStepItem(BuildContext context, String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.primaryGreen,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildContactItem(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryGreen, size: 20),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildGuideItem(BuildContext context, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(description, style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildPolicyItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: AppColors.primaryGreen, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
