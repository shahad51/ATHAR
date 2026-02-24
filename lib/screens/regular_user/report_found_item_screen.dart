import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';
import '../../widgets/widgets.dart';

class ReportFoundItemScreen extends StatefulWidget {
  const ReportFoundItemScreen({super.key});

  @override
  State<ReportFoundItemScreen> createState() => _ReportFoundItemScreenState();
}

class _ReportFoundItemScreenState extends State<ReportFoundItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _colorController = TextEditingController();
  final _locationController = TextEditingController();

  String? _selectedItemType;
  File? _imageFile;
  bool _isSubmitting = false;
  bool _showMap = false;

  LocationModel? _nearestCenter;
  Map<String, dynamic>? _routeData;
  LatLng? _userLocation;

  final GpsService _gpsService = GpsService();
  final MapsService _mapsService = MapsService();
  final FirestoreService _firestoreService = FirestoreService();

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

    if (_imageFile == null) {
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
    final reportId = await reportsProvider.submitFoundReport(
      userId: userId,
      itemType: _selectedItemType!,
      itemColor: _colorController.text,
      itemLocation: _locationController.text,
      imageFile: _imageFile!,
    );

    if (reportId != null && authProvider.currentUser?.role == UserRole.regular) {
      await _findNearestCenter();
    }

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (reportId != null) {
      if (_nearestCenter != null && authProvider.currentUser?.role == UserRole.regular) {
        setState(() => _showMap = true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.get('report_submitted')),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _findNearestCenter() async {
    final position = await _gpsService.getCurrentPosition();
    if (position == null) return;

    _userLocation = LatLng(position.latitude, position.longitude);
    _nearestCenter = await _firestoreService.getNearestLocation(
      position.latitude,
      position.longitude,
    );

    if (_nearestCenter != null) {
      _routeData = await _mapsService.getDirections(
        position.latitude,
        position.longitude,
        _nearestCenter!.lat,
        _nearestCenter!.lng,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('report_found')),
      ),
      body: _showMap ? _buildMapView(l10n) : _buildForm(l10n),
    );
  }

  Widget _buildForm(AppLocalizations l10n) {
    return SingleChildScrollView(
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
                labelText: l10n.get('item_type'),
                prefixIcon: const Icon(Icons.category_outlined),
              ),
              items: AppConstants.itemTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) => setState(() => _selectedItemType = value),
              validator: (value) => value == null ? l10n.get('missing_fields_submit') : null,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _colorController,
              label: l10n.get('item_color'),
              hint: l10n.get('enter_color'),
              prefixIcon: const Icon(Icons.color_lens_outlined),
              validator: (value) => value?.isEmpty == true ? l10n.get('missing_fields_submit') : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _locationController.text.isEmpty ? null : _locationController.text,
              decoration: InputDecoration(
                labelText: l10n.get('item_location'),
                prefixIcon: const Icon(Icons.location_on_outlined),
              ),
              items: AppConstants.hajjLocations.map((loc) {
                return DropdownMenuItem(value: loc, child: Text(loc));
              }).toList(),
              onChanged: (value) => _locationController.text = value ?? '',
              validator: (value) => value == null ? l10n.get('missing_fields_submit') : null,
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

  Widget _buildImagePicker(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${l10n.get('upload_image')} *',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickImage,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(
                color: _imageFile == null ? AppColors.error : AppColors.divider,
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
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white),
                            onPressed: _pickImage,
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_a_photo_outlined,
                        size: 48,
                        color: AppColors.textHint,
                      ),
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

  Widget _buildMapView(AppLocalizations l10n) {
    return Column(
      children: [
        Expanded(
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _userLocation ?? const LatLng(21.4225, 39.8262),
              zoom: 14,
            ),
            markers: {
              if (_userLocation != null)
                Marker(
                  markerId: const MarkerId('user'),
                  position: _userLocation!,
                  infoWindow: const InfoWindow(title: 'Your Location'),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                ),
              if (_nearestCenter != null)
                Marker(
                  markerId: const MarkerId('center'),
                  position: LatLng(_nearestCenter!.lat, _nearestCenter!.lng),
                  infoWindow: InfoWindow(title: _nearestCenter!.name),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                ),
            },
            polylines: _routeData != null
                ? {_mapsService.createRoutePolyline(_routeData!['polyline'])}
                : {},
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.get('nearest_center'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _nearestCenter?.name ?? 'Unknown',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      Icons.directions_walk,
                      _routeData?['distance'] ?? '--',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoChip(
                      Icons.access_time,
                      _routeData?['duration'] ?? '--',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: l10n.get('done'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.get('report_submitted')),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: AppColors.primaryGreen),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
