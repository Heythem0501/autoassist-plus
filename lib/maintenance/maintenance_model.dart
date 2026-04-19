import 'package:cloud_firestore/cloud_firestore.dart';
import 'maintenance_constants.dart';

/// Un entretien effectué par l'utilisateur (historique)
class MaintenanceRecord {
  final String id;                // ID Firestore (vide lors de création)
  final String typeId;            // Référence au type d'entretien
  final DateTime performedAt;     // Date à laquelle l'entretien a été fait
  final int mileageAtService;     // Kilométrage lors de l'entretien
  final String? notes;            // Notes libres de l'utilisateur

  MaintenanceRecord({
    required this.id,
    required this.typeId,
    required this.performedAt,
    required this.mileageAtService,
    this.notes,
  });

  /// Définition complète du type d'entretien (ou null si type inconnu)
  MaintenanceTypeDefinition? get typeDefinition =>
      MaintenanceConstants.getById(typeId);

  /// Calcule la date d'échéance prochaine
  DateTime? get nextDueDate {
    final def = typeDefinition;
    if (def == null || def.intervalDays == null) return null;
    return performedAt.add(Duration(days: def.intervalDays!));
  }

  /// Calcule le kilométrage d'échéance prochain
  int? get nextDueMileage {
    final def = typeDefinition;
    if (def == null || def.intervalKm == null) return null;
    return mileageAtService + def.intervalKm!;
  }

  /// Calcule le niveau d'urgence en fonction du km actuel et de la date
  MaintenanceUrgency computeUrgency({
    required int currentMileage,
    DateTime? now,
  }) {
    final nowDate = now ?? DateTime.now();
    final def = typeDefinition;
    if (def == null) return MaintenanceUrgency.ok;

    // Distance restante en jours
    int? daysRemaining;
    if (nextDueDate != null) {
      daysRemaining = nextDueDate!.difference(nowDate).inDays;
    }

    // Distance restante en km
    int? kmRemaining;
    if (nextDueMileage != null) {
      kmRemaining = nextDueMileage! - currentMileage;
    }

    // Détection de dépassement
    final daysOverdue = daysRemaining != null && daysRemaining < 0;
    final kmOverdue = kmRemaining != null && kmRemaining < 0;
    if (daysOverdue || kmOverdue) return MaintenanceUrgency.overdue;

    // Détection de "bientôt"
    final daysSoon = daysRemaining != null && daysRemaining <= 30;
    final kmSoon = kmRemaining != null && kmRemaining <= 1000;
    if (daysSoon || kmSoon) return MaintenanceUrgency.soon;

    return MaintenanceUrgency.ok;
  }

  /// Construit depuis Firestore
  factory MaintenanceRecord.fromFirestore(
    String docId,
    Map<String, dynamic> data,
  ) {
    return MaintenanceRecord(
      id: docId,
      typeId: data['typeId'] as String? ?? '',
      performedAt: (data['performedAt'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      mileageAtService: (data['mileageAtService'] as num?)?.toInt() ?? 0,
      notes: data['notes'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'typeId': typeId,
        'performedAt': Timestamp.fromDate(performedAt),
        'mileageAtService': mileageAtService,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
        'createdAt': FieldValue.serverTimestamp(),
      };
}