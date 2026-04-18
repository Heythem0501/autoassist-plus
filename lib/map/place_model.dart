import 'dart:math';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../core/app_theme.dart';

/// Type de lieu recherché
enum PlaceType {
  garage,
  depanneur,
  stationService;

  String get label {
    switch (this) {
      case PlaceType.garage:
        return 'Garages';
      case PlaceType.depanneur:
        return 'Dépanneurs';
      case PlaceType.stationService:
        return 'Stations-service';
    }
  }

  String get singular {
    switch (this) {
      case PlaceType.garage:
        return 'Garage';
      case PlaceType.depanneur:
        return 'Dépanneur';
      case PlaceType.stationService:
        return 'Station-service';
    }
  }

  IconData get icon {
    switch (this) {
      case PlaceType.garage:
        return Icons.build_circle_rounded;
      case PlaceType.depanneur:
        return Icons.car_crash_rounded;
      case PlaceType.stationService:
        return Icons.local_gas_station_rounded;
    }
  }

  Color get color {
    switch (this) {
      case PlaceType.garage:
        return AppTheme.primaryBlue;
      case PlaceType.depanneur:
        return AppTheme.severityRed;
      case PlaceType.stationService:
        return AppTheme.accentOrange;
    }
  }

  /// Tags OpenStreetMap à rechercher via l'API Overpass
  String get overpassQuery {
    switch (this) {
      case PlaceType.garage:
        return '"shop"="car_repair"';
      case PlaceType.depanneur:
        return '"amenity"="vehicle_inspection"';
      case PlaceType.stationService:
        return '"amenity"="fuel"';
    }
  }
}

/// Un lieu trouvé via l'API Overpass
class Place {
  final String id;
  final String name;
  final LatLng location;
  final PlaceType type;
  final String? address;
  final String? phone;
  final double distanceMeters;

  Place({
    required this.id,
    required this.name,
    required this.location,
    required this.type,
    required this.distanceMeters,
    this.address,
    this.phone,
  });

  /// Construit un Place depuis un élément JSON Overpass
  factory Place.fromOverpassElement({
    required Map<String, dynamic> element,
    required PlaceType type,
    required double userLat,
    required double userLng,
  }) {
    final tags = element['tags'] as Map<String, dynamic>? ?? {};

    // Coordonnées : node = lat/lon directement, way/relation = center
    double lat;
    double lng;
    if (element['lat'] != null && element['lon'] != null) {
      lat = (element['lat'] as num).toDouble();
      lng = (element['lon'] as num).toDouble();
    } else if (element['center'] != null) {
      final center = element['center'] as Map<String, dynamic>;
      lat = (center['lat'] as num).toDouble();
      lng = (center['lon'] as num).toDouble();
    } else {
      lat = 0;
      lng = 0;
    }

    // Construire l'adresse depuis les tags
    final addrParts = <String>[];
    if (tags['addr:street'] != null) addrParts.add(tags['addr:street']);
    if (tags['addr:city'] != null) addrParts.add(tags['addr:city']);
    final address = addrParts.isEmpty ? null : addrParts.join(', ');

    // Distance depuis la position user
    final distance = _haversineDistance(userLat, userLng, lat, lng);

    return Place(
      id: '${element['type']}_${element['id']}',
      name: (tags['name'] as String?)?.trim() ?? 'Sans nom',
      location: LatLng(lat, lng),
      type: type,
      address: address,
      phone: tags['phone'] as String? ?? tags['contact:phone'] as String?,
      distanceMeters: distance,
    );
  }

  /// Formule de Haversine en mètres
  static double _haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371000.0; // rayon de la Terre en mètres
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRadians(double deg) => deg * pi / 180;
}