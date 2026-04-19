import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'place_model.dart';

/// Service de recherche de lieux via Nominatim (OpenStreetMap)
///
/// Nominatim est l'API officielle d'OpenStreetMap — stable et fiable.
/// Pour chaque type de lieu, plusieurs requêtes sont lancées en parallèle
/// afin de couvrir un maximum de variantes linguistiques.
class OverpassService {
  static const String _nominatimUrl =
      'https://nominatim.openstreetmap.org/search';

  static const int _timeoutSeconds = 15;
  static const int defaultRadiusMeters = 10000;

  /// Recherche des lieux d'un type donné autour d'une position
  ///
  /// Lance plusieurs requêtes en parallèle avec différents mots-clés
  /// (français, anglais) et fusionne les résultats sans doublons.
  Future<List<Place>> searchNearby({
    required double userLat,
    required double userLng,
    required PlaceType type,
    int radiusMeters = defaultRadiusMeters,
  }) async {
    final queries = _getSearchQueries(type);

    if (kDebugMode) {
      debugPrint('🔍 Nominatim: ${queries.length} recherches pour $type');
    }

    // Lancer toutes les recherches en parallèle
    final futures = queries.map((q) => _searchSingleQuery(
          query: q,
          userLat: userLat,
          userLng: userLng,
          type: type,
          radiusMeters: radiusMeters,
        ));

    final allResults = await Future.wait(futures, eagerError: false);

    // Fusionner tous les résultats et dédupliquer par ID
    final seen = <String>{};
    final mergedPlaces = <Place>[];
    for (final list in allResults) {
      for (final place in list) {
        if (!seen.contains(place.id)) {
          seen.add(place.id);
          mergedPlaces.add(place);
        }
      }
    }

    // Filtrer par rayon réel
    mergedPlaces.removeWhere((p) => p.distanceMeters > radiusMeters);

    // Trier par distance croissante
    mergedPlaces.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

    if (kDebugMode) {
      debugPrint('🔍 Nominatim: ${mergedPlaces.length} lieux apres fusion');
    }

    // Limiter à 30 résultats
    if (mergedPlaces.length > 30) {
      return mergedPlaces.sublist(0, 30);
    }

    return mergedPlaces;
  }

  /// Effectue une seule recherche Nominatim avec un mot-clé donné
  Future<List<Place>> _searchSingleQuery({
    required String query,
    required double userLat,
    required double userLng,
    required PlaceType type,
    required int radiusMeters,
  }) async {
    final radiusDegrees = radiusMeters / 111000.0;
    final minLat = userLat - radiusDegrees;
    final maxLat = userLat + radiusDegrees;
    final minLng = userLng - radiusDegrees;
    final maxLng = userLng + radiusDegrees;

    final uri = Uri.parse(_nominatimUrl).replace(queryParameters: {
      'q': query,
      'format': 'json',
      'limit': '20',
      'bounded': '1',
      'viewbox': '$minLng,$minLat,$maxLng,$maxLat',
      'addressdetails': '1',
      'extratags': '1',
    });

    try {
      final response = await http.get(
        uri,
        headers: const {
          'User-Agent':
              'AutoAssistPlus/1.0 (Flutter; haythem.ramdani@gmail.com)',
          'Accept-Language': 'fr,ar,en',
        },
      ).timeout(Duration(seconds: _timeoutSeconds));

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as List<dynamic>;

      final places = <Place>[];
      for (final item in data) {
        try {
          final map = item as Map<String, dynamic>;
          final place = _parseResult(map, type, userLat, userLng);
          if (place != null) places.add(place);
        } catch (_) {
          continue;
        }
      }
      return places;
    } catch (_) {
      return [];
    }
  }

  /// Liste de requêtes de recherche selon le type de lieu
  /// Plusieurs variantes pour maximiser les résultats sur OSM
  List<String> _getSearchQueries(PlaceType type) {
    switch (type) {
      case PlaceType.garage:
        return [
          'garage',
          'car repair',
          'mechanic',
          'atelier mécanique',
          'auto repair',
        ];
      
      case PlaceType.stationService:
        return [
          'station service',
          'fuel station',
          'gas station',
          'essence',
          'carburant',
        ];
    }
  }

  /// Convertit un résultat Nominatim en Place
  Place? _parseResult(
    Map<String, dynamic> result,
    PlaceType type,
    double userLat,
    double userLng,
  ) {
    final latStr = result['lat'] as String?;
    final lonStr = result['lon'] as String?;
    if (latStr == null || lonStr == null) return null;

    final lat = double.tryParse(latStr);
    final lng = double.tryParse(lonStr);
    if (lat == null || lng == null) return null;

    // Nom
    final shortName = result['name'] as String?;
    final displayName = result['display_name'] as String? ?? '';
    String name = shortName ?? displayName.split(',').first.trim();
    if (name.isEmpty || name.length < 2) name = 'Sans nom';

    // Adresse
    String? address;
    final addressData = result['address'] as Map<String, dynamic>?;
    if (addressData != null) {
      final parts = <String>[];
      if (addressData['road'] != null) parts.add(addressData['road'] as String);
      final city = addressData['city'] as String? ??
          addressData['town'] as String? ??
          addressData['village'] as String?;
      if (city != null) parts.add(city);
      if (parts.isNotEmpty) address = parts.join(', ');
    }

    // Téléphone
    String? phone;
    final extratags = result['extratags'] as Map<String, dynamic>?;
    if (extratags != null) {
      phone = extratags['phone'] as String? ??
          extratags['contact:phone'] as String?;
    }

    // Distance Haversine
    final distance = _haversineDistance(userLat, userLng, lat, lng);

    final osmId = result['osm_id']?.toString() ?? '${lat}_$lng';

    return Place(
      id: 'nominatim_$osmId',
      name: name,
      location: LatLng(lat, lng),
      type: type,
      address: address,
      phone: phone,
      distanceMeters: distance,
    );
  }

  /// Distance Haversine entre 2 points GPS (en mètres)
  double _haversineDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371000.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double deg) => deg * math.pi / 180;
}

/// Exception métier
class OverpassException implements Exception {
  final String message;
  OverpassException(this.message);

  @override
  String toString() => message;
}