import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/models.dart';
import '../core/constants/app_colors.dart';

class MapsService {
  static const String _apiKey = 'YOUR_GOOGLE_MAPS_API_KEY';

  Future<Map<String, dynamic>?> getDirections(
    double originLat,
    double originLng,
    double destLat,
    double destLng,
  ) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=$originLat,$originLng'
        '&destination=$destLat,$destLng'
        '&mode=driving'
        '&key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];

          return {
            'distance': leg['distance']['text'],
            'duration': leg['duration']['text'],
            'polyline': route['overview_polyline']['points'],
            'startAddress': leg['start_address'],
            'endAddress': leg['end_address'],
          };
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  List<LatLng> decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  RouteMetadata? createRouteMetadata(Map<String, dynamic>? directionsData) {
    if (directionsData == null) return null;

    return RouteMetadata(
      distance: directionsData['distance'] ?? '',
      duration: directionsData['duration'] ?? '',
      polyline: directionsData['polyline'] ?? '',
    );
  }

  Set<Marker> createLocationMarkers(List<LocationModel> locations) {
    return locations.map((location) {
      return Marker(
        markerId: MarkerId(location.locationId),
        position: LatLng(location.lat, location.lng),
        infoWindow: InfoWindow(
          title: location.name,
          snippet:
              location.type == LocationType.center ? 'Center' : 'Deposit Point',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          location.type == LocationType.center
              ? BitmapDescriptor.hueBlue
              : BitmapDescriptor.hueGreen,
        ),
      );
    }).toSet();
  }

  Polyline createRoutePolyline(String encodedPolyline) {
    final points = decodePolyline(encodedPolyline);
    return Polyline(
      polylineId: const PolylineId('route'),
      points: points,
      color: AppColors.primaryGreen,
      width: 5,
    );
  }
}
