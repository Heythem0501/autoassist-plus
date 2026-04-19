import 'package:cloud_firestore/cloud_firestore.dart';

/// Types de carburant supportés
enum FuelType {
  essence,
  diesel,
  gpl;

  String get label {
    switch (this) {
      case FuelType.essence:
        return 'Essence';
      case FuelType.diesel:
        return 'Diesel';
      case FuelType.gpl:
        return 'GPL';
    }
  }

  String get emoji {
    switch (this) {
      case FuelType.essence:
        return '⛽';
      case FuelType.diesel:
        return '🛢️';
      case FuelType.gpl:
        return '💨';
    }
  }

  /// Convertit une chaîne de Firestore en FuelType
  static FuelType fromString(String value) {
    return FuelType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => FuelType.essence,
    );
  }
}

/// Modèle représentant le véhicule d'un utilisateur
class Vehicle {
  final String brand;           // Marque (ex: Peugeot)
  final String model;           // Modèle (ex: 208)
  final int year;               // Année (ex: 2020)
  final FuelType fuelType;      // Essence, Diesel ou GPL
  final int currentMileage;     // Kilométrage actuel (en km)
  final DateTime createdAt;     // Date de création du profil véhicule
  final DateTime updatedAt;     // Date de dernière modification

  Vehicle({
    required this.brand,
    required this.model,
    required this.year,
    required this.fuelType,
    required this.currentMileage,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convertit le véhicule en Map pour l'envoyer à Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'brand': brand,
      'model': model,
      'year': year,
      'fuelType': fuelType.name,
      'currentMileage': currentMileage,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Reconstruit un objet Vehicle depuis un document Firestore
  factory Vehicle.fromFirestore(Map<String, dynamic> data) {
    return Vehicle(
      brand: data['brand'] as String? ?? '',
      model: data['model'] as String? ?? '',
      year: data['year'] as int? ?? DateTime.now().year,
      fuelType: FuelType.fromString(data['fuelType'] as String? ?? 'essence'),
      currentMileage: data['currentMileage'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Crée une copie du véhicule avec certains champs modifiés
  /// (utile pour la modification sans recréer tout l'objet)
  Vehicle copyWith({
    String? brand,
    String? model,
    int? year,
    FuelType? fuelType,
    int? currentMileage,
    DateTime? updatedAt,
  }) {
    return Vehicle(
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      fuelType: fuelType ?? this.fuelType,
      currentMileage: currentMileage ?? this.currentMileage,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Affichage lisible pour le débogage
  @override
  String toString() {
    return '$brand $model ($year) - ${fuelType.label} - $currentMileage km';
  }
}