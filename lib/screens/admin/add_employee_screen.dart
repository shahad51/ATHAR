import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/utils/validators.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';

class AddEmployeeScreen extends StatefulWidget {
  const AddEmployeeScreen({super.key});

  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleAddEmployee() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final l10n = AppLocalizations.of(context)!;

    final result = await authProvider.register(
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      mobile: _mobileController.text,
      username: _usernameController.text,
      password: _passwordController.text,
      accountType: 'employee',
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.get('employee_created')),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else {
      String errorMessage;
      switch (result['error']) {
        case 'username_exists':
          errorMessage = l10n.get('username_exists');
          break;
        case 'mobile_exists':
          errorMessage = l10n.get('mobile_exists');
          break;
        default:
          errorMessage = l10n.get('failed_create_employee');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('add_employee')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.person_add,
                size: 64,
                color: AppColors.primaryGreen,
              ),
              const SizedBox(height: 24),
              Text(
                l10n.get('create_employee_account'),
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.get('fill_employee_details'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
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
                validator: (v) =>
                    Validators.validateName(v, l10n.get('last_name')),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _mobileController,
                label: l10n.get('mobile'),
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(Icons.phone_outlined),
                validator: Validators.validateMobile,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _usernameController,
                label: l10n.get('username'),
                prefixIcon: const Icon(Icons.alternate_email),
                validator: Validators.validateUsername,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _passwordController,
                label: l10n.get('password'),
                obscureText: _obscurePassword,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword
                      ? Icons.visibility_off
                      : Icons.visibility),
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
                validator: (v) => Validators.validateConfirmPassword(
                    v, _passwordController.text),
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: l10n.get('create_employee_account'),
                onPressed: _handleAddEmployee,
                isLoading: _isLoading,
                icon: Icons.person_add,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
