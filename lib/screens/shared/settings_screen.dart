import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/utils/validators.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _infoFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _mobileController;

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isUpdatingInfo = false;
  bool _isChangingPassword = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _mobileController = TextEditingController(text: user?.mobile ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updateInfo() async {
    if (!_infoFormKey.currentState!.validate()) return;

    setState(() => _isUpdatingInfo = true);

    final authProvider = context.read<AuthProvider>();
    await authProvider.updateUserInfo({
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'mobile': _mobileController.text.trim(),
    });

    setState(() => _isUpdatingInfo = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.get('changes_saved')),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() => _isChangingPassword = true);

    final authProvider = context.read<AuthProvider>();
    final result = await authProvider.changePassword(
      _currentPasswordController.text,
      _newPasswordController.text,
    );

    setState(() => _isChangingPassword = false);

    if (!mounted) return;

    if (result['success']) {
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.get('changes_saved')),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Current password is incorrect'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = context.watch<LocaleProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('settings')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildLanguageSection(l10n, localeProvider),
            const SizedBox(height: 24),
            _buildUpdateInfoSection(l10n),
            const SizedBox(height: 24),
            _buildChangePasswordSection(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSection(AppLocalizations l10n, LocaleProvider localeProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.get('language'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildLanguageOption(
                    'العربية',
                    'ar',
                    localeProvider.locale.languageCode == 'ar',
                    () => localeProvider.setLocale(const Locale('ar')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildLanguageOption(
                    'English',
                    'en',
                    localeProvider.locale.languageCode == 'en',
                    () => localeProvider.setLocale(const Locale('en')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    String label,
    String code,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? AppColors.primaryGreen.withOpacity(0.05) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.primaryGreen : AppColors.textPrimary,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle, color: AppColors.primaryGreen, size: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateInfoSection(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _infoFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.get('update_info'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _firstNameController,
                label: l10n.get('first_name'),
                validator: (v) => Validators.validateName(v, l10n.get('first_name')),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _lastNameController,
                label: l10n.get('last_name'),
                validator: (v) => Validators.validateName(v, l10n.get('last_name')),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _mobileController,
                label: l10n.get('mobile'),
                keyboardType: TextInputType.phone,
                validator: Validators.validateMobile,
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: l10n.get('save'),
                onPressed: _updateInfo,
                isLoading: _isUpdatingInfo,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChangePasswordSection(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _passwordFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.get('change_password'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _currentPasswordController,
                label: l10n.get('current_password'),
                obscureText: _obscureCurrentPassword,
                suffixIcon: IconButton(
                  icon: Icon(_obscureCurrentPassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureCurrentPassword = !_obscureCurrentPassword),
                ),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _newPasswordController,
                label: l10n.get('new_password'),
                obscureText: _obscureNewPassword,
                suffixIcon: IconButton(
                  icon: Icon(_obscureNewPassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                ),
                validator: Validators.validatePassword,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _confirmPasswordController,
                label: l10n.get('confirm_password'),
                obscureText: true,
                validator: (v) => Validators.validateConfirmPassword(v, _newPasswordController.text),
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: l10n.get('change_password'),
                onPressed: _changePassword,
                isLoading: _isChangingPassword,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
