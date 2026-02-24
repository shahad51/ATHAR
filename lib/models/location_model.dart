import 'package:cloud_firestore/cloud_firestore.dart';

enum LocationType { center, deposit }

class LocationModel {
  final String locationId;
  final String name;
  final LocationType type;
  final double lat;
  final double lng;
  final bool isActive;

  LocationModel({
    required this.locationId,
    required this.name,
    required this.type,
    required this.lat,
    required this.lng,
    this.isActive = true,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    final coordinates = json['coordinates'] as Map<String, dynamic>?;
    return LocationModel(
      locationId: json['locationId'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] == 'deposit' ? LocationType.deposit : LocationType.center,
      lat: (coordinates?['lat'] ?? 0.0).toDouble(),
      lng: (coordinates?['lng'] ?? 0.0).toDouble(),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'locationId': locationId,
      'name': name,
      'type': type.name,
      'coordinates': {
        'lat': lat,
        'lng': lng,
      },
      'isActive': isActive,
    };
  }

  LocationModel copyWith({
    String? locationId,
    String? name,
    LocationType? type,
    double? lat,
    double? lng,
    bool? isActive,
  }) {
    return LocationModel(
      locationId: locationId ?? this.locationId,
      name: name ?? this.name,
      type: type ?? this.type,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      isActive: isActive ?? this.isActive,
    );
  }
}
