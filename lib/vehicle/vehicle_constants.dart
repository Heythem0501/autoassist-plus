/// Constantes liées aux véhicules
///
/// Liste des marques automobiles les plus courantes en Algérie,
/// basée sur les parts de marché du marché algérien.
class VehicleConstants {
  /// Marques principales (ordre alphabétique)
  static const List<String> carBrands = [
    'Audi',
    'BMW',
    'Chery',
    'Chevrolet',
    'Citroën',
    'Dacia',
    'Fiat',
    'Ford',
    'Geely',
    'Honda',
    'Hyundai',
    'Isuzu',
    'JAC',
    'Kia',
    'Mazda',
    'Mercedes-Benz',
    'Mitsubishi',
    'Nissan',
    'Opel',
    'Peugeot',
    'Renault',
    'Seat',
    'Škoda',
    'Suzuki',
    'Toyota',
    'Volkswagen',
    'Autre',
  ];

  /// Année minimale acceptée pour un véhicule
  static const int minYear = 1980;

  /// Kilométrage maximum acceptable (garde-fou contre les fautes de frappe)
  static const int maxMileage = 1000000;
}