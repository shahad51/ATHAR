import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';
import '../../widgets/widgets.dart';

class GpsTrackingDialog extends StatefulWidget {
  const GpsTrackingDialog({super.key});

  @override
  State<GpsTrackingDialog> createState() => _GpsTrackingDialogState();
}

class _GpsTrackingDialogState extends State<GpsTrackingDialog> {
  final GpsService _gpsService = GpsService();
  bool _isLoading = false;
  int _step = 0; // 0: question, 1: GPS setup, 2: manual entry

  final List<_ManualEntry> _manualEntries = [];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _step == 0
            ? _buildQuestion(l10n)
            : _step == 1
                ? _buildGpsSetup(l10n)
                : _buildManualEntry(l10n),
      ),
    );
  }

  Widget _buildQuestion(AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.location_on,
            size: 48,
            color: AppColors.primaryGreen,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.get('gps_tracking_question'),
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: l10n.get('yes'),
                onPressed: () => setState(() => _step = 1),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomButton(
                text: l10n.get('no'),
                onPressed: () => setState(() => _step = 2),
                isOutlined: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGpsSetup(AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.gps_fixed, size: 64, color: AppColors.primaryGreen),
        const SizedBox(height: 24),
        Text(
          'Enable GPS Tracking',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Text(
          'Allow location access to automatically track your movement during pilgrimage.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        CustomButton(
          text: 'Enable Location',
          onPressed: _enableGps,
          isLoading: _isLoading,
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => setState(() => _step = 2),
          child: const Text('Enter manually instead'),
        ),
      ],
    );
  }

  Future<void> _enableGps() async {
    setState(() => _isLoading = true);

    final userId = context.read<AuthProvider>().currentUser?.userId;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final success = await _gpsService.startTracking(userId);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              AppLocalizations.of(context)!.get('tracking_setup_complete')),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('Location Access Denied'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Location permission was denied.'),
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
                'You can still use the app with manual location entry.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _step = 2);
              },
              child: Text('Enter Manually'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildManualEntry(AppLocalizations l10n) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Enter Your Visited Locations',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ..._manualEntries.asMap().entries.map((entry) {
            return _buildEntryCard(entry.key, entry.value, l10n);
          }),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _addEntry,
            icon: const Icon(Icons.add),
            label: Text(l10n.get('add_location')),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: l10n.get('save'),
            onPressed: _manualEntries.isEmpty ? null : _saveManualEntries,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildEntryCard(int index, _ManualEntry entry, AppLocalizations l10n) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Location ${index + 1}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: AppColors.error),
                  onPressed: () =>
                      setState(() => _manualEntries.removeAt(index)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: entry.location.isEmpty ? null : entry.location,
              decoration: InputDecoration(
                labelText: l10n.get('location_name'),
                isDense: true,
              ),
              items: AppConstants.hajjLocations.map((loc) {
                return DropdownMenuItem(value: loc, child: Text(loc));
              }).toList(),
              onChanged: (value) {
                setState(() => entry.location = value ?? '');
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(entry),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: l10n.get('date'),
                        isDense: true,
                      ),
                      child: Text(
                        entry.date != null
                            ? '${entry.date!.day}/${entry.date!.month}/${entry.date!.year}'
                            : 'Select',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectTime(entry),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: l10n.get('time'),
                        isDense: true,
                      ),
                      child: Text(
                        entry.time != null
                            ? '${entry.time!.hour}:${entry.time!.minute.toString().padLeft(2, '0')}'
                            : 'Select',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: entry.transport.isEmpty ? null : entry.transport,
              decoration: InputDecoration(
                labelText: l10n.get('transport_method'),
                isDense: true,
              ),
              items: AppConstants.transportMethods.map((t) {
                return DropdownMenuItem(value: t, child: Text(t));
              }).toList(),
              onChanged: (value) {
                setState(() => entry.transport = value ?? '');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addEntry() {
    setState(() {
      _manualEntries.add(_ManualEntry());
    });
  }

  Future<void> _selectDate(_ManualEntry entry) async {
    final date = await showDatePicker(
      context: context,
      initialDate: entry.date ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => entry.date = date);
    }
  }

  Future<void> _selectTime(_ManualEntry entry) async {
    final time = await showTimePicker(
      context: context,
      initialTime: entry.time ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => entry.time = time);
    }
  }

  Future<void> _saveManualEntries() async {
    setState(() => _isLoading = true);

    final userId = context.read<AuthProvider>().currentUser?.userId;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final entries = _manualEntries
        .where((e) => e.location.isNotEmpty && e.date != null)
        .map((e) {
      final dateTime = DateTime(
        e.date!.year,
        e.date!.month,
        e.date!.day,
        e.time?.hour ?? 12,
        e.time?.minute ?? 0,
      );
      return LocationEntry(
        location: e.location,
        lat: 0,
        lng: 0,
        timestamp: dateTime,
        transportMethod: e.transport,
      );
    }).toList();

    await _gpsService.saveManualEntries(userId, entries);

    if (!mounted) return;

    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(AppLocalizations.of(context)!.get('tracking_setup_complete')),
        backgroundColor: AppColors.success,
      ),
    );
    Navigator.pop(context);
  }
}

class _ManualEntry {
  String location = '';
  DateTime? date;
  TimeOfDay? time;
  String transport = '';
}
