import 'package:flutter/material.dart';
import '../core/app_theme.dart';

/// Définition d'un type d'entretien avec ses intervalles
class MaintenanceTypeDefinition {
  final String id;                    // Identifiant unique interne
  final String label;                 // Nom affiché
  final String description;           // Description courte
  final IconData icon;                // Icône représentative
  final int? intervalKm;              // Intervalle en km (null si pas basé sur km)
  final int? intervalDays;            // Intervalle en jours (null si pas basé sur temps)

  const MaintenanceTypeDefinition({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
    this.intervalKm,
    this.intervalDays,
  });
}

/// Catalogue des 13 types d'entretien supportés
///
/// Intervalles basés sur les recommandations constructeurs génériques
/// pour les véhicules récents (essence et diesel).
class MaintenanceConstants {
  static const List<MaintenanceTypeDefinition> types = [
    MaintenanceTypeDefinition(
      id: 'oil_change',
      label: 'Vidange huile moteur',
      description: 'Huile + filtre à huile',
      icon: Icons.oil_barrel_rounded,
      intervalKm: 5000,
      intervalDays: 180,
    ),
    MaintenanceTypeDefinition(
      id: 'air_filter',
      label: 'Filtre à air',
      description: 'Filtre d\'admission moteur',
      icon: Icons.air_rounded,
      intervalKm: 15000,
      intervalDays: 365,
    ),
    MaintenanceTypeDefinition(
      id: 'spark_plugs',
      label: 'Bougies d\'allumage',
      description: 'Bougies pour moteur essence',
      icon: Icons.electric_bolt_rounded,
      intervalKm: 30000,
      intervalDays: 730,
    ),
    MaintenanceTypeDefinition(
      id: 'timing_belt',
      label: 'Courroie de distribution',
      description: 'Courroie + galets + pompe à eau',
      icon: Icons.settings_rounded,
      intervalKm: 80000,
      intervalDays: 1825,
    ),
    MaintenanceTypeDefinition(
      id: 'gearbox_oil',
      label: 'Vidange boîte de vitesses',
      description: 'Huile de boîte manuelle/auto',
      icon: Icons.settings_applications_rounded,
      intervalKm: 60000,
      intervalDays: 1095,
    ),
    MaintenanceTypeDefinition(
      id: 'coolant',
      label: 'Liquide de refroidissement',
      description: 'Antigel du circuit moteur',
      icon: Icons.water_drop_rounded,
      intervalKm: 40000,
      intervalDays: 730,
    ),
    MaintenanceTypeDefinition(
      id: 'brake_pads',
      label: 'Plaquettes de frein',
      description: 'Plaquettes avant et arrière',
      icon: Icons.do_disturb_on_rounded,
      intervalKm: 30000,
      intervalDays: 730,
    ),
    MaintenanceTypeDefinition(
      id: 'brake_fluid',
      label: 'Liquide de frein',
      description: 'Liquide hydraulique DOT 4',
      icon: Icons.opacity_rounded,
      intervalDays: 730,
    ),
    MaintenanceTypeDefinition(
      id: 'tires',
      label: 'Pneus',
      description: 'Rotation ou remplacement',
      icon: Icons.tire_repair_rounded,
      intervalKm: 10000,
      intervalDays: 365,
    ),
    MaintenanceTypeDefinition(
      id: 'washer_fluid',
      label: 'Liquide lave-glace',
      description: 'Réservoir lave-vitre',
      icon: Icons.wash_rounded,
      intervalDays: 180,
    ),
    MaintenanceTypeDefinition(
      id: 'cabin_filter',
      label: 'Filtre d\'habitacle',
      description: 'Filtre à pollen',
      icon: Icons.air_rounded,
      intervalKm: 15000,
      intervalDays: 365,
    ),
    MaintenanceTypeDefinition(
      id: 'ac_recharge',
      label: 'Recharge climatisation',
      description: 'Gaz R134a / R1234yf',
      icon: Icons.ac_unit_rounded,
      intervalDays: 730,
    ),
    MaintenanceTypeDefinition(
      id: 'oil_filter',
      label: 'Filtre à huile',
      description: 'Filtre à huile seul',
      icon: Icons.filter_alt_rounded,
      intervalKm: 5000,
      intervalDays: 180,
    ),
  ];

  /// Retourne un type par son ID, ou null si non trouvé
  static MaintenanceTypeDefinition? getById(String id) {
    try {
      return types.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}

/// Niveau d'urgence d'un entretien
enum MaintenanceUrgency {
  ok,       // Pas urgent (plus de 30j et plus de 1000km)
  soon,     // Bientôt (< 30j ou < 1000km)
  overdue;  // Dépassé

  Color get color {
    switch (this) {
      case MaintenanceUrgency.ok:
        return AppTheme.severityGreen;
      case MaintenanceUrgency.soon:
        return AppTheme.severityOrange;
      case MaintenanceUrgency.overdue:
        return AppTheme.severityRed;
    }
  }

  IconData get icon {
    switch (this) {
      case MaintenanceUrgency.ok:
        return Icons.check_circle_rounded;
      case MaintenanceUrgency.soon:
        return Icons.schedule_rounded;
      case MaintenanceUrgency.overdue:
        return Icons.error_rounded;
    }
  }

  String get label {
    switch (this) {
      case MaintenanceUrgency.ok:
        return 'OK';
      case MaintenanceUrgency.soon:
        return 'Bientôt';
      case MaintenanceUrgency.overdue:
        return 'Dépassé';
    }
  }
}