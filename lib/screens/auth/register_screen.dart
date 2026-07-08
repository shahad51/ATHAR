import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/utils/validators.dart';
import '../../providers/providers.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentPage = 0;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage == 0) {
      if (_firstNameController.text.isEmpty ||
          _lastNameController.text.isEmpty ||
          _mobileController.text.isEmpty ||
          _emailController.text.isEmpty ||
          _usernameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all fields')),
        );
        return;
      }
      final mobileError =
          Validators.validateSaudiMobile(_mobileController.text);
      if (mobileError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mobileError)),
        );
        return;
      }
      final emailError = Validators.validateEmail(_emailController.text);
      if (emailError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(emailError)),
        );
        return;
      }
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final l10n = AppLocalizations.of(context)!;

    final result = await authProvider.register(
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      mobile: _mobileController.text,
      email: _emailController.text,
      username: _usernameController.text,
      password: _passwordController.text,
      accountType: 'regular',
    );

    if (!mounted) return;

    if (result['success']) {
      final verificationSent = result['email_verification_sent'] == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            verificationSent
                ? 'Registration successful! Please check your email to verify your account before logging in.'
                : 'Registration successful! Please login.',
          ),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: verificationSent ? 6 : 3),
        ),
      );
      Navigator.pop(context);
    } else {
      String errorMessage;
      switch (result['error']) {
        case 'username_exists':
          errorMessage = 'Username already exists';
          break;
        case 'mobile_exists':
          errorMessage = 'Mobile number already registered';
          break;
        default:
          errorMessage = 'Registration failed. Please try again.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLoading = context.watch<AuthProvider>().isLoading;
    final localeProvider = context.watch<LocaleProvider>();
    final isArabic = localeProvider.locale.languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('register')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          _buildLangActionButton(
            'العربية',
            isArabic,
            () => localeProvider.setLocale(const Locale('ar')),
          ),
          _buildLangActionButton(
            'EN',
            !isArabic,
            () => localeProvider.setLocale(const Locale('en')),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildProgressIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  _buildPage1(l10n),
                  _buildPage2(l10n, isLoading),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: _currentPage >= 1
                    ? AppColors.primaryGreen
                    : AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage1(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Personal Information',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          CustomTextField(
            controller: _firstNameController,
            label: l10n.get('first_name'),
            prefixIcon: const Icon(Icons.person_outline),
            validator: (v) =>
                Validators.validateName(v, l10n.get('first_name')),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _lastNameController,
            label: l10n.get('last_name'),
            prefixIcon: const Icon(Icons.person_outline),
            validator: (v) => Validators.validateName(v, l10n.get('last_name')),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _mobileController,
            label: l10n.get('mobile'),
            keyboardType: TextInputType.phone,
            prefixIcon: const Icon(Icons.phone_outlined),
            validator: Validators.validateSaudiMobile,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _emailController,
            label: l10n.get('email'),
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.email_outlined),
            validator: Validators.validateEmail,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _usernameController,
            label: l10n.get('username'),
            prefixIcon: const Icon(Icons.alternate_email),
            validator: Validators.validateUsername,
          ),
          const SizedBox(height: 32),
          CustomButton(
            text: l10n.get('next'),
            onPressed: _nextPage,
            icon: Icons.arrow_forward,
          ),
        ],
      ),
    );
  }

  Widget _buildPage2(AppLocalizations l10n, bool isLoading) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Account Setup',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          CustomTextField(
            controller: _passwordController,
            label: l10n.get('password'),
            obscureText: _obscurePassword,
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: Validators.validatePassword,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _confirmPasswordController,
            label: l10n.get('confirm_password'),
            obscureText: _obscureConfirmPassword,
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscureConfirmPassword
                  ? Icons.visibility_off
                  : Icons.visibility),
              onPressed: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
            validator: (v) =>
                Validators.validateConfirmPassword(v, _passwordController.text),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: l10n.get('back'),
                  onPressed: _previousPage,
                  isOutlined: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomButton(
                  text: l10n.get('register'),
                  onPressed: _handleRegister,
                  isLoading: isLoading,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLangActionButton(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
