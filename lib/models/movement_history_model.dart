import 'package:cloud_firestore/cloud_firestore.dart';

class LocationEntry {
  final String location;
  final double lat;
  final double lng;
  final DateTime timestamp;
  final String transportMethod;

  LocationEntry({
    required this.location,
    required this.lat,
    required this.lng,
    required this.timestamp,
    required this.transportMethod,
  });

  factory LocationEntry.fromJson(Map<String, dynamic> json) {
    final coordinates = json['coordinates'] as Map<String, dynamic>?;
    return LocationEntry(
      location: json['location'] ?? '',
      lat: (coordinates?['lat'] ?? 0.0).toDouble(),
      lng: (coordinates?['lng'] ?? 0.0).toDouble(),
      timestamp: json['timestamp'] is Timestamp
          ? (json['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      transportMethod: json['transportMethod'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'location': location,
      'coordinates': {
        'lat': lat,
        'lng': lng,
      },
      'timestamp': Timestamp.fromDate(timestamp),
      'transportMethod': transportMethod,
    };
  }
}

class MovementHistoryModel {
  final String id;
  final String userId;
  final List<LocationEntry> entries;
  final bool isManualEntry;
  final bool gpsPermissionGranted;

  MovementHistoryModel({
    required this.id,
    required this.userId,
    required this.entries,
    this.isManualEntry = false,
    this.gpsPermissionGranted = false,
  });

  factory MovementHistoryModel.fromJson(Map<String, dynamic> json, String docId) {
    final entriesList = json['entries'] as List<dynamic>? ?? [];
    return MovementHistoryModel(
      id: docId,
      userId: json['userId'] ?? '',
      entries: entriesList.map((e) => LocationEntry.fromJson(e)).toList(),
      isManualEntry: json['isManualEntry'] ?? false,
      gpsPermissionGranted: json['gpsPermissionGranted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'entries': entries.map((e) => e.toJson()).toList(),
      'isManualEntry': isManualEntry,
      'gpsPermissionGranted': gpsPermissionGranted,
    };
  }

  MovementHistoryModel copyWith({
    String? id,
    String? userId,
    List<LocationEntry>? entries,
    bool? isManualEntry,
    bool? gpsPermissionGranted,
  }) {
    return MovementHistoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      entries: entries ?? this.entries,
      isManualEntry: isManualEntry ?? this.isManualEntry,
      gpsPermissionGranted: gpsPermissionGranted ?? this.gpsPermissionGranted,
    );
  }

  bool hasVisitedLocation(String locationName) {
    final normalizedSearch = locationName.toLowerCase().trim();
    return entries.any((entry) {
      final normalizedEntry = entry.location.toLowerCase().trim();
      return normalizedEntry.contains(normalizedSearch) ||
          normalizedSearch.contains(normalizedEntry);
    });
  }
}
