import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/models.dart';
import 'firestore_service.dart';

class GpsService {
  final FirestoreService _firestoreService = FirestoreService();
  StreamSubscription<Position>? _positionSubscription;
  bool _isTracking = false;

  bool get isTracking => _isTracking;

  Future<bool> checkPermission() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  Future<bool> requestPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }

    return false;
  }

  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await checkPermission();
      if (!hasPermission) {
        final granted = await requestPermission();
        if (!granted) return null;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      return null;
    }
  }

  Future<bool> startTracking(String userId) async {
    try {
      final hasPermission = await checkPermission();
      if (!hasPermission) {
        final granted = await requestPermission();
        if (!granted) return false;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      // Create initial movement history document
      final history = MovementHistoryModel(
        id: userId,
        userId: userId,
        entries: [],
        isManualEntry: false,
        gpsPermissionGranted: true,
      );

      await _firestoreService.saveMovementHistory(history);

      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100, // meters
      );

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen((Position position) async {
        await _saveLocationEntry(userId, position);
      });

      _isTracking = true;
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> stopTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _isTracking = false;
  }

  Future<void> _saveLocationEntry(String userId, Position position) async {
    try {
      final locationName = await _getLocationName(position.latitude, position.longitude);

      final entry = LocationEntry(
        location: locationName,
        lat: position.latitude,
        lng: position.longitude,
        timestamp: DateTime.now(),
        transportMethod: 'GPS',
      );

      await _firestoreService.addLocationEntry(userId, entry);
    } catch (_) {}
  }

  Future<String> _getLocationName(double lat, double lng) async {
    // Check if location is near known Hajj sites
    final hajjSites = {
      'Mina': {'lat': 21.4133, 'lng': 39.8933},
      'Arafat': {'lat': 21.3549, 'lng': 39.9842},
      'Muzdalifah': {'lat': 21.3833, 'lng': 39.9333},
      'Masjid Al-Haram': {'lat': 21.4225, 'lng': 39.8262},
      'Jamarat': {'lat': 21.4200, 'lng': 39.8733},
    };

    for (final entry in hajjSites.entries) {
      final siteLat = entry.value['lat']!;
      final siteLng = entry.value['lng']!;
      
      final distance = Geolocator.distanceBetween(lat, lng, siteLat, siteLng);
      if (distance < 2000) { // Within 2km
        return entry.key;
      }
    }

    return 'Unknown Location';
  }

  Future<void> saveManualEntries(String userId, List<LocationEntry> entries) async {
    try {
      final history = MovementHistoryModel(
        id: userId,
        userId: userId,
        entries: entries,
        isManualEntry: true,
        gpsPermissionGranted: false,
      );

      await _firestoreService.saveMovementHistory(history);
    } catch (_) {}
  }

  double calculateDistanceBetween(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }
}
