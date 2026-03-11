import 'package:flutter/material.dart';
import '../services/gps_service.dart';

class PermissionMonitor extends StatefulWidget {
  final Widget child;
  final Function(bool hasPermission)? onPermissionChanged;

  const PermissionMonitor({
    super.key,
    required this.child,
    this.onPermissionChanged,
  });

  @override
  State<PermissionMonitor> createState() => _PermissionMonitorState();
}

class _PermissionMonitorState extends State<PermissionMonitor> with WidgetsBindingObserver {
  final GpsService _gpsService = GpsService();
  bool? _previousPermissionState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came back to foreground - check if permission changed
      _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    final hasPermission = await _gpsService.checkPermission();
    
    if (_previousPermissionState != null && _previousPermissionState != hasPermission) {
      // Permission state changed
      widget.onPermissionChanged?.call(hasPermission);
      
      if (!hasPermission && mounted) {
        // Permission was revoked - show warning
        _showPermissionRevokedDialog();
      }
    }
    
    _previousPermissionState = hasPermission;
  }

  void _showPermissionRevokedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Location Access Changed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Location permission has been disabled.'),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Text(
                'Matching accuracy and nearby center suggestions will be reduced until location access is enabled.',
                style: TextStyle(fontSize: 13, color: Colors.orange.shade900),
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Your previously stored location data has been preserved.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
