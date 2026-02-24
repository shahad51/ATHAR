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

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _itemTypeController = TextEditingController();
  final _colorController = TextEditingController();
  final _locationController = TextEditingController();
  
  File? _searchImage;
  String? _selectedItemType;
  List<ReportMatch> _results = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _itemTypeController.dispose();
    _colorController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _searchByAttributes() async {
    setState(() => _isSearching = true);

    final reportsProvider = context.read<ReportsProvider>();
    final results = await reportsProvider.searchForMatches(
      itemType: _selectedItemType ?? '',
      itemColor: _colorController.text,
      itemLocation: _locationController.text,
    );

    setState(() {
      _results = results;
      _isSearching = false;
    });
  }

  Future<void> _searchByImage() async {
    if (_searchImage == null) return;

    setState(() => _isSearching = true);

    final reportsProvider = context.read<ReportsProvider>();
    final results = await reportsProvider.searchForMatches(
      itemType: '',
      itemColor: '',
      itemLocation: '',
      imageFile: _searchImage,
    );

    setState(() {
      _results = results;
      _isSearching = false;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
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
      setState(() => _searchImage = File(pickedFile.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryGreen,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(text: l10n.get('attribute_search')),
            Tab(text: l10n.get('image_search')),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAttributeSearch(l10n),
              _buildImageSearch(l10n),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttributeSearch(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _colorController,
            label: l10n.get('item_color'),
            hint: l10n.get('enter_color'),
            prefixIcon: const Icon(Icons.color_lens_outlined),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _locationController,
            label: l10n.get('item_location'),
            hint: l10n.get('select_location'),
            prefixIcon: const Icon(Icons.location_on_outlined),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: l10n.get('search'),
            onPressed: _searchByAttributes,
            isLoading: _isSearching,
            icon: Icons.search,
          ),
          const SizedBox(height: 24),
          _buildResults(l10n),
        ],
      ),
    );
  }

  Widget _buildImageSearch(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: _pickImage,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.divider, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _searchImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(_searchImage!, fit: BoxFit.cover),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 64,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.get('upload_image'),
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: l10n.get('search'),
            onPressed: _searchImage != null ? _searchByImage : null,
            isLoading: _isSearching,
            icon: Icons.search,
          ),
          const SizedBox(height: 24),
          _buildResults(l10n),
        ],
      ),
    );
  }

  Widget _buildResults(AppLocalizations l10n) {
    if (_isSearching) {
      return const ShimmerListLoading(itemCount: 3);
    }

    if (_results.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.search_off,
        title: l10n.get('no_matches'),
        subtitle: 'Try adjusting your search criteria',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_results.length} results found',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _results.length,
          itemBuilder: (context, index) {
            final match = _results[index];
            return _buildMatchCard(match, l10n);
          },
        ),
      ],
    );
  }

  Widget _buildMatchCard(ReportMatch match, AppLocalizations l10n) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            if (match.report.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  match.report.imageUrl!,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 80,
                    height: 80,
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
                  const SizedBox(height: 4),
                  Text(
                    '${match.report.itemColor} • ${match.report.itemLocation}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryGold.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${l10n.get('confidence_score')}: ${(match.confidenceScore * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryGoldDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
