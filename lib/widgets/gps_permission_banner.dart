import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../services/gps_service.dart';

class GpsPermissionBanner extends StatefulWidget {
  const GpsPermissionBanner({super.key});

  @override
  State<GpsPermissionBanner> createState() => _GpsPermissionBannerState();
}

class _GpsPermissionBannerState extends State<GpsPermissionBanner> {
  final GpsService _gpsService = GpsService();
  bool _hasPermission = true;
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final hasPermission = await _gpsService.checkPermission();
    if (mounted) {
      setState(() => _hasPermission = hasPermission);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasPermission || _isDismissed) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Location Access Disabled',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Matching accuracy and nearby center suggestions will be reduced until location access is enabled.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => setState(() => _isDismissed = true),
            color: Colors.orange.shade700,
          ),
        ],
      ),
    );
  }
}
