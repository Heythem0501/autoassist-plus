import 'dart:convert';
import 'package:http/http.dart' as http;
import 'place_model.dart';

/// Service d'appel à l'API Overpass (OpenStreetMap)
///
/// Permet de rechercher des points d'intérêt (garages, stations-service,
/// dépanneurs) autour d'une position géographique.
///
/// Documentation : https://wiki.openstreetmap.org/wiki/Overpass_API
class OverpassService {
  /// Liste des serveurs Overpass publics
  /// L'app essaie chaque serveur dans l'ordre jusqu'à obtenir une réponse
  static const List<String> _endpoints = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
    'https://overpass.private.coffee/api/interpreter',
  ];

  /// Timeout pour l'appel API (Overpass peut être lent)
  static const int _timeoutSeconds = 25;

  /// Rayon de recherche par défaut (en mètres)
  static const int defaultRadiusMeters = 10000; // 10 km

  // ==========================================================================
  // RECHERCHE PRINCIPALE
  // ==========================================================================

  /// Recherche des lieux d'un type donné autour d'une position
  ///
  /// [userLat] / [userLng] : position de l'utilisateur
  /// [type] : type de lieu recherché (garage, dépanneur, station-service)
  /// [radiusMeters] : rayon de recherche en mètres (défaut 10 km)
  ///
  /// Recherche des lieux d'un type donné autour d'une position
  ///
  /// Tente chaque serveur Overpass l'un après l'autre en cas d'échec,
  /// garantissant une meilleure disponibilité du service.
  Future<List<Place>> searchNearby({
    required double userLat,
    required double userLng,
    required PlaceType type,
    int radiusMeters = defaultRadiusMeters,
  }) async {
    final query = _buildQuery(
      lat: userLat,
      lng: userLng,
      type: type,
      radiusMeters: radiusMeters,
    );

    // Essaie chaque serveur Overpass l'un après l'autre
    http.Response? response;
    Exception? lastError;

    for (final endpoint in _endpoints) {
      try {
        response = await http
            .post(
              Uri.parse(endpoint),
              headers: {'Content-Type': 'application/x-www-form-urlencoded'},
              body: {'data': query},
            )
            .timeout(const Duration(seconds: _timeoutSeconds));

        // Succès → on sort de la boucle
        if (response.statusCode == 200) break;

        // 429 : inutile d'essayer un autre serveur tout de suite
        if (response.statusCode == 429) {
          throw OverpassException(
            'Trop de requêtes. Réessayez dans quelques minutes.',
          );
        }

        // Autres erreurs : on essaie le serveur suivant
        response = null;
      } on OverpassException {
        rethrow;
      } catch (e) {
        lastError = Exception(e.toString());
        response = null;
        continue;
      }
    }

    // Si aucun serveur n'a répondu
    if (response == null) {
      throw OverpassException(
        'Tous les serveurs Overpass sont indisponibles. Vérifiez votre connexion ou réessayez plus tard.',
      );
    }

    // Vérification du code HTTP final
    if (response.statusCode != 200) {
      throw OverpassException(
        'Erreur de recherche (code ${response.statusCode}).',
      );
    }

    // Parsing du JSON
    late List<dynamic> elements;
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      elements = body['elements'] as List<dynamic>? ?? [];
    } catch (e) {
      throw OverpassException('Réponse invalide du service.');
    }

    // Conversion en Place
    final places = <Place>[];
    for (final element in elements) {
      try {
        final place = Place.fromOverpassElement(
          element: element as Map<String, dynamic>,
          type: type,
          userLat: userLat,
          userLng: userLng,
        );
        if (place.location.latitude != 0 && place.location.longitude != 0) {
          places.add(place);
        }
      } catch (e) {
        continue;
      }
    }

    // Tri par distance croissante
    places.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

    return places;
  }
  // ==========================================================================
  // CONSTRUCTION DE LA REQUÊTE OVERPASS QL
  // ==========================================================================

  /// Construit une requête Overpass QL pour chercher les POI d'un type
  /// dans un rayon donné autour d'une position.
  ///
  /// Overpass QL est le langage de requête d'Overpass API.
  /// Doc : https://wiki.openstreetmap.org/wiki/Overpass_API/Overpass_QL
  String _buildQuery({
    required double lat,
    required double lng,
    required PlaceType type,
    required int radiusMeters,
  }) {
    final tagFilter = type.overpassQuery;

    // Récupère nodes, ways ET relations (certains garages sont mappés
    // comme des ways représentant des bâtiments)
    return '''
[out:json][timeout:25];
(
  node[$tagFilter](around:$radiusMeters,$lat,$lng);
  way[$tagFilter](around:$radiusMeters,$lat,$lng);
  relation[$tagFilter](around:$radiusMeters,$lat,$lng);
);
out center tags;
''';
  }
}

/// Exception métier du service Overpass
class OverpassException implements Exception {
  final String message;
  OverpassException(this.message);

  @override
  String toString() => message;
}