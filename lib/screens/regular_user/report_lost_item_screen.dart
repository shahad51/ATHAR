import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';
import '../../widgets/widgets.dart';

class ReportLostItemScreen extends StatefulWidget {
  const ReportLostItemScreen({super.key});

  @override
  State<ReportLostItemScreen> createState() => _ReportLostItemScreenState();
}

class _ReportLostItemScreenState extends State<ReportLostItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _colorController = TextEditingController();

  String? _selectedItemType;
  String? _selectedLocation;
  File? _imageFile;
  bool _isSearching = false;
  bool _isSubmitting = false;

  List<ReportMatch> _matches = [];
  String? _selectedMatchId;
  bool _hasSearched = false;

  final FirestoreService _firestoreService = FirestoreService();

  @override
  void dispose() {
    _colorController.dispose();
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

  Future<void> _searchForMatches() async {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = context.read<AuthProvider>();

    if (_selectedItemType == null ||
        _colorController.text.isEmpty ||
        _selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.get('missing_fields_search')),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // GPS validation for regular users
    if (authProvider.currentUser?.role == UserRole.regular) {
      final userId = authProvider.currentUser?.userId;
      if (userId != null) {
        final movementHistory =
            await _firestoreService.getMovementHistory(userId);
        if (movementHistory != null &&
            !movementHistory.hasVisitedLocation(_selectedLocation!)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.get('invalid_location')),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }
      }
    }

    setState(() => _isSearching = true);

    final reportsProvider = context.read<ReportsProvider>();
    final matches = await reportsProvider.searchForMatches(
      itemType: _selectedItemType!,
      itemColor: _colorController.text,
      itemLocation: _selectedLocation!,
      imageFile: _imageFile,
    );

    setState(() {
      _matches = matches;
      _isSearching = false;
      _hasSearched = true;
    });
  }

  Future<void> _submitReport() async {
    final l10n = AppLocalizations.of(context)!;

    if (_selectedItemType == null ||
        _colorController.text.isEmpty ||
        _selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.get('missing_fields_submit')),
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
    final reportId = await reportsProvider.submitLostReport(
      userId: userId,
      itemType: _selectedItemType!,
      itemColor: _colorController.text,
      itemLocation: _selectedLocation!,
      imageFile: _imageFile,
      matchedReportId: _selectedMatchId,
    );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (reportId != null) {
      // Get the reference ID from the created report
      final report = await _firestoreService.getReportById(reportId);
      final referenceId = report?.referenceId ?? 'N/A';

      String message = l10n.get('report_submitted');

      if (_selectedMatchId != null &&
          authProvider.currentUser?.role == UserRole.regular) {
        final matchedReport = _matches.firstWhere(
          (m) => m.report.reportId == _selectedMatchId,
        );
        if (matchedReport.report.nearestCenterName != null) {
          message =
              '${l10n.get('center_holding_item')}: ${matchedReport.report.nearestCenterName}';
        }
      } else if (_selectedMatchId == null &&
          authProvider.currentUser?.role == UserRole.regular) {
        message = l10n.get('no_match_found');
      }

      // Show success dialog with Reference ID
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
              Text(message),
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
                      'Your Reference ID:',
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
                'Save this Reference ID to track your report later.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('report_lost')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImagePicker(l10n),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: _selectedItemType,
                decoration: InputDecoration(
                  labelText: '${l10n.get('item_type')} *',
                  prefixIcon: const Icon(Icons.category_outlined),
                ),
                items: AppConstants.itemTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) => setState(() => _selectedItemType = value),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _colorController,
                label: '${l10n.get('item_color')} *',
                hint: l10n.get('enter_color'),
                prefixIcon: const Icon(Icons.color_lens_outlined),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedLocation,
                decoration: InputDecoration(
                  labelText: '${l10n.get('item_location')} *',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                ),
                items: AppConstants.hajjLocations.map((loc) {
                  return DropdownMenuItem(value: loc, child: Text(loc));
                }).toList(),
                onChanged: (value) => setState(() => _selectedLocation = value),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: l10n.get('search'),
                onPressed: _searchForMatches,
                isLoading: _isSearching,
                icon: Icons.search,
                isOutlined: true,
              ),
              if (_hasSearched) ...[
                const SizedBox(height: 24),
                _buildMatchesSection(l10n),
              ],
              const SizedBox(height: 24),
              CustomButton(
                text: l10n.get('submit'),
                onPressed: _submitReport,
                isLoading: _isSubmitting,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${l10n.get('upload_image')} (${l10n.get('other')})',
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
              border: Border.all(color: AppColors.divider, width: 2),
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
                      const Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 40,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Optional: Add image for better matching',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildMatchesSection(AppLocalizations l10n) {
    if (_matches.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.search_off, size: 48, color: AppColors.textHint),
              const SizedBox(height: 12),
              Text(
                l10n.get('no_matches'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.get('no_match_found'),
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${l10n.get('select_match')} (${_matches.length} found)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _matches.length,
          itemBuilder: (context, index) {
            final match = _matches[index];
            final isSelected = _selectedMatchId == match.report.reportId;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color:
                      isSelected ? AppColors.primaryGreen : Colors.transparent,
                  width: 2,
                ),
              ),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedMatchId =
                        isSelected ? null : match.report.reportId;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      if (match.report.imageUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            match.report.imageUrl!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 60,
                              height: 60,
                              color: AppColors.background,
                              child: const Icon(Icons.image),
                            ),
                          ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              match.report.itemType,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              '${match.report.itemColor} • ${match.report.itemLocation}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryGold.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${(match.confidenceScore * 100).toStringAsFixed(0)}% match',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.secondaryGoldDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle,
                            color: AppColors.primaryGreen),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
