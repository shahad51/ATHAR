import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/utils/validators.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _step = 0; // 0: mobile, 1: OTP, 2: new password
  String? _userId;
  String? _expectedOtp;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _mobileController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    if (_mobileController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your mobile number')),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final result = await authProvider.sendPasswordResetOTP(_mobileController.text);

    if (!mounted) return;

    if (result['success']) {
      setState(() {
        _step = 1;
        _userId = result['userId'];
        _expectedOtp = result['otp'];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP sent to your mobile'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mobile number not found'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _verifyOTP() {
    if (_otpController.text == _expectedOtp) {
      setState(() => _step = 2);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid OTP'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _resetPassword() async {
    final passwordError = Validators.validatePassword(_newPasswordController.text);
    if (passwordError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(passwordError), backgroundColor: AppColors.error),
      );
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final result = await authProvider.resetPassword(
      _userId!,
      _newPasswordController.text,
    );

    if (!mounted) return;

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset successful'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to reset password'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('reset_password')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStepIndicator(),
            const SizedBox(height: 32),
            if (_step == 0) _buildMobileStep(l10n, isLoading),
            if (_step == 1) _buildOtpStep(l10n, isLoading),
            if (_step == 2) _buildPasswordStep(l10n, isLoading),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _buildStepDot(0, 'Mobile'),
        Expanded(child: Container(height: 2, color: _step >= 1 ? AppColors.primaryGreen : AppColors.divider)),
        _buildStepDot(1, 'OTP'),
        Expanded(child: Container(height: 2, color: _step >= 2 ? AppColors.primaryGreen : AppColors.divider)),
        _buildStepDot(2, 'Password'),
      ],
    );
  }

  Widget _buildStepDot(int step, String label) {
    final isActive = _step >= step;
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.primaryGreen : AppColors.divider,
          ),
          child: Center(
            child: Text(
              '${step + 1}',
              style: TextStyle(
                color: isActive ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? AppColors.primaryGreen : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileStep(AppLocalizations l10n, bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Enter your registered mobile number',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 24),
        CustomTextField(
          controller: _mobileController,
          label: l10n.get('mobile'),
          keyboardType: TextInputType.phone,
          prefixIcon: const Icon(Icons.phone_outlined),
        ),
        const SizedBox(height: 24),
        CustomButton(
          text: l10n.get('send_otp'),
          onPressed: _sendOTP,
          isLoading: isLoading,
        ),
      ],
    );
  }

  Widget _buildOtpStep(AppLocalizations l10n, bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Enter the 4-digit OTP sent to your mobile',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 24),
        CustomTextField(
          controller: _otpController,
          label: l10n.get('enter_otp'),
          keyboardType: TextInputType.number,
          prefixIcon: const Icon(Icons.pin_outlined),
        ),
        const SizedBox(height: 24),
        CustomButton(
          text: l10n.get('verify'),
          onPressed: _verifyOTP,
          isLoading: isLoading,
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _sendOTP,
          child: const Text('Resend OTP'),
        ),
      ],
    );
  }

  Widget _buildPasswordStep(AppLocalizations l10n, bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Enter your new password',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 24),
        CustomTextField(
          controller: _newPasswordController,
          label: l10n.get('new_password'),
          obscureText: _obscurePassword,
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _confirmPasswordController,
          label: l10n.get('confirm_password'),
          obscureText: true,
          prefixIcon: const Icon(Icons.lock_outline),
        ),
        const SizedBox(height: 24),
        CustomButton(
          text: l10n.get('reset_password'),
          onPressed: _resetPassword,
          isLoading: isLoading,
        ),
      ],
    );
  }
}
