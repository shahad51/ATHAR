import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/localization/app_localizations.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';
import '../../widgets/widgets.dart';

class EmployeeAddReportScreen extends StatefulWidget {
  const EmployeeAddReportScreen({super.key});

  @override
  State<EmployeeAddReportScreen> createState() =>
      _EmployeeAddReportScreenState();
}

class _EmployeeAddReportScreenState extends State<EmployeeAddReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _colorController = TextEditingController();
  final _locationController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  String? _selectedItemType;
  String _reportType = 'found';
  File? _imageFile;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _colorController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final l10n = AppLocalizations.of(context)!;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(l10n.get('take_photo')),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(l10n.get('choose_gallery')),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    final pickedFile = await picker.pickImage(source: source, maxWidth: 1024);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _submitReport() async {
    final l10n = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) return;

    if (_reportType == 'found' && _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.get('image_required')),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.userId;

    if (userId == null) {
      setState(() => _isSubmitting = false);
      return;
    }

    final reportsProvider = context.read<ReportsProvider>();
    String? reportId;

    if (_reportType == 'found') {
      reportId = await reportsProvider.submitFoundReport(
        userId: userId,
        itemType: _selectedItemType!,
        itemColor: _colorController.text,
        itemLocation: _locationController.text,
        imageFile: _imageFile!,
        isCenterSubmitted: true,
      );
    } else {
      reportId = await reportsProvider.submitLostReport(
        userId: userId,
        itemType: _selectedItemType!,
        itemColor: _colorController.text,
        itemLocation: _locationController.text,
        imageFile: _imageFile,
        isCenterSubmitted: true,
      );
    }

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (reportId != null) {
      // Get the reference ID from the created report
      final report = await _firestoreService.getReportById(reportId);
      final referenceId = report?.referenceId ?? 'N/A';

      _resetForm();

      // Show success with Reference ID
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success),
              SizedBox(width: 8),
              Text('Report Submitted'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('The report has been successfully submitted.'),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.primaryGreen.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reference ID:',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 4),
                    SelectableText(
                      referenceId,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Please provide this Reference ID to the user so they can track their report.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _colorController.clear();
    _locationController.clear();
    setState(() {
      _selectedItemType = null;
      _imageFile = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Submit Report on Behalf of Pilgrim',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            _buildReportTypeSelector(l10n),
            const SizedBox(height: 24),
            _buildImagePicker(l10n),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: _selectedItemType,
              decoration: InputDecoration(
                labelText: l10n.get('item_type'),
                prefixIcon: const Icon(Icons.category_outlined),
              ),
              items: AppConstants.itemTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) => setState(() => _selectedItemType = value),
              validator: (value) =>
                  value == null ? l10n.get('missing_fields_submit') : null,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _colorController,
              label: l10n.get('item_color'),
              hint: l10n.get('enter_color'),
              prefixIcon: const Icon(Icons.color_lens_outlined),
              validator: (value) => value?.isEmpty == true
                  ? l10n.get('missing_fields_submit')
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _locationController.text.isEmpty
                  ? null
                  : _locationController.text,
              decoration: InputDecoration(
                labelText: l10n.get('item_location'),
                prefixIcon: const Icon(Icons.location_on_outlined),
              ),
              items: AppConstants.hajjLocations.map((loc) {
                return DropdownMenuItem(value: loc, child: Text(loc));
              }).toList(),
              onChanged: (value) => _locationController.text = value ?? '',
              validator: (value) =>
                  value == null ? l10n.get('missing_fields_submit') : null,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: l10n.get('submit'),
              onPressed: _submitReport,
              isLoading: _isSubmitting,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTypeSelector(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: _buildTypeOption(
            l10n.get('found'),
            Icons.check_circle_outline,
            _reportType == 'found',
            () => setState(() => _reportType = 'found'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTypeOption(
            l10n.get('lost'),
            Icons.search_off,
            _reportType == 'lost',
            () => setState(() => _reportType = 'lost'),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeOption(
      String label, IconData icon, bool isSelected, VoidCallback onTap) {
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
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color:
                  isSelected ? AppColors.primaryGreen : AppColors.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color:
                    isSelected ? AppColors.primaryGreen : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker(AppLocalizations l10n) {
    final isRequired = _reportType == 'found';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${l10n.get('upload_image')}${isRequired ? ' *' : ' (Optional)'}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickImage,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(
                color: isRequired && _imageFile == null
                    ? AppColors.error
                    : AppColors.divider,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _imageFile != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          _imageFile!,
                          width: double.infinity,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          radius: 18,
                          child: IconButton(
                            icon: const Icon(Icons.close,
                                color: Colors.white, size: 18),
                            onPressed: () => setState(() => _imageFile = null),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_a_photo_outlined,
                          size: 40, color: AppColors.textHint),
                      const SizedBox(height: 8),
                      Text(
                        l10n.get('take_photo'),
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
