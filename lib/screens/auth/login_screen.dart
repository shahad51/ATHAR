import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import '../shared/track_report_screen.dart';
import '../regular_user/regular_user_home_screen.dart';
import '../employee/employee_home_screen.dart';
import '../admin/admin_home_screen.dart';
import '../manager/manager_home_screen.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;

    setState(() => _isLoading = true);
    debugPrint('🟡 [LoginScreen] Starting login...');

    final authProvider = context.read<AuthProvider>();
    final result = await authProvider.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    debugPrint(
        '🟡 [LoginScreen] Login result: ${result['success']}, error: ${result['error']}');

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result['success']) {
      debugPrint('🟡 [LoginScreen] Login successful!');

      // Get user role and navigate to appropriate home screen
      final user = authProvider.currentUser;
      if (user != null) {
        Widget homeScreen;
        switch (user.role) {
          case UserRole.employee:
            homeScreen = const EmployeeHomeScreen();
            break;
          case UserRole.admin:
            homeScreen = const AdminHomeScreen();
            break;
          case UserRole.manager:
            homeScreen = const ManagerHomeScreen();
            break;
          default:
            homeScreen = const RegularUserHomeScreen();
        }

        // Replace the entire navigation stack with home screen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => homeScreen),
          (route) => false,
        );
      }
    } else {
      debugPrint('🟡 [LoginScreen] Login failed, showing error');
      _showErrorMessage(result['error']);
    }
  }

  void _showErrorMessage(String? error) {
    debugPrint('🟡 [LoginScreen] _showErrorMessage called with: $error');

    String message;
    switch (error) {
      case 'account_pending':
        message = 'حسابك قيد المراجعة - Account pending approval';
        break;
      case 'account_rejected':
        message = 'تم رفض حسابك - Account rejected';
        break;
      default:
        message = 'بيانات الدخول غير صحيحة - Invalid credentials';
    }

    debugPrint('🟡 [LoginScreen] Showing snackbar: $message');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                _buildHeader(l10n),
                const SizedBox(height: 48),
                _buildUsernameField(l10n),
                const SizedBox(height: 16),
                _buildPasswordField(l10n),
                // const SizedBox(height: 8),
                // _buildForgotPassword(l10n),
                const SizedBox(height: 32),
                CustomButton(
                  text: l10n.get('login'),
                  onPressed: _isLoading ? null : _handleLogin,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 24),
                _buildRegisterLink(l10n),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            'assets/images/logo-light.jpeg',
            width: 100,
            height: 100,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.get('app_name_arabic'),
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.get('smart_lost_found'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  Widget _buildUsernameField(AppLocalizations l10n) {
    return CustomTextField(
      controller: _usernameController,
      label: l10n.get('username'),
      prefixIcon: const Icon(Icons.person_outline),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '${l10n.get('username')} is required';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField(AppLocalizations l10n) {
    return CustomTextField(
      controller: _passwordController,
      label: l10n.get('password'),
      obscureText: _obscurePassword,
      prefixIcon: const Icon(Icons.lock_outline),
      suffixIcon: IconButton(
        icon: Icon(
          _obscurePassword ? Icons.visibility_off : Icons.visibility,
        ),
        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '${l10n.get('password')} is required';
        }
        return null;
      },
    );
  }

  Widget _buildForgotPassword(AppLocalizations l10n) {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
          );
        },
        child: Text(l10n.get('forgot_password')),
      ),
    );
  }

  Widget _buildRegisterLink(AppLocalizations l10n) {
    return Column(
      children: [
        OutlinedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TrackReportScreen()),
            );
          },
          icon: const Icon(Icons.search),
          label: Text(l10n.get('track_report_reference')),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.get('dont_have_account'),
              style: TextStyle(color: AppColors.textSecondary),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                );
              },
              child: Text(l10n.get('register')),
            ),
          ],
        ),
      ],
    );
  }
}
