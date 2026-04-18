import 'package:geolocator/geolocator.dart';

/// Service de géolocalisation
///
/// Responsabilités :
/// - Vérifier si le GPS est activé
/// - Demander les permissions de localisation
/// - Obtenir la position courante de l'utilisateur
/// - Calculer les distances entre points GPS
class LocationService {
  /// Position par défaut : Alger (Place des Martyrs)
  /// Utilisée si l'utilisateur refuse la géolocalisation
  static const double defaultLatitude = 36.7819;
  static const double defaultLongitude = 3.0567;

  // ==========================================================================
  // OBTENIR LA POSITION
  // ==========================================================================

  /// Récupère la position GPS actuelle de l'utilisateur
  ///
  /// Retourne la [Position] en cas de succès.
  /// Lance une [LocationException] avec un message clair en cas d'erreur :
  /// - GPS désactivé
  /// - Permission refusée
  /// - Permission refusée définitivement
  /// - Timeout (signal GPS faible)
  Future<Position> getCurrentPosition() async {
    // 1. Vérifier si le service GPS est activé sur l'appareil
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException(
        'Le GPS est désactivé. Activez-le dans les paramètres de votre téléphone.',
      );
    }

    // 2. Vérifier le statut actuel de la permission
    LocationPermission permission = await Geolocator.checkPermission();

    // 3. Si refusée, demander la permission
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationException(
          'Permission de localisation refusée.',
        );
      }
    }

    // 4. Si refusée définitivement, l'utilisateur doit aller dans les paramètres
    if (permission == LocationPermission.deniedForever) {
      throw LocationException(
        'Permission refusée définitivement. Activez-la dans les paramètres de l\'application.',
      );
    }

    // 5. Récupérer la position avec un timeout
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (e) {
      throw LocationException(
        'Impossible d\'obtenir votre position. Vérifiez votre GPS.',
      );
    }
  }

  // ==========================================================================
  // CALCUL DE DISTANCE
  // ==========================================================================

  /// Calcule la distance en mètres entre deux points GPS
  /// (formule de Haversine implémentée dans Geolocator)
  static double distanceBetween({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Formatte une distance en mètres en texte lisible
  /// Exemples : "350 m", "1.2 km", "15 km"
  static String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    } else if (distanceInMeters < 10000) {
      final km = (distanceInMeters / 1000).toStringAsFixed(1);
      return '$km km';
    } else {
      final km = (distanceInMeters / 1000).round();
      return '$km km';
    }
  }
}

/// Exception métier du service de localisation
class LocationException implements Exception {
  final String message;
  LocationException(this.message);

  @override
  String toString() => message;
}