import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/app_theme.dart';

/// Niveau de gravité d'une cause diagnostique
enum Severity {
  vert,     // Faible — surveiller
  orange,   // Moyen — consulter bientôt
  rouge;    // Élevé — urgent

  /// Couleur associée
  Color get color {
    switch (this) {
      case Severity.vert:
        return AppTheme.severityGreen;
      case Severity.orange:
        return AppTheme.severityOrange;
      case Severity.rouge:
        return AppTheme.severityRed;
    }
  }

  /// Icône associée
  IconData get icon {
    switch (this) {
      case Severity.vert:
        return Icons.check_circle_rounded;
      case Severity.orange:
        return Icons.warning_rounded;
      case Severity.rouge:
        return Icons.error_rounded;
    }
  }

  /// Libellé court
  String get label {
    switch (this) {
      case Severity.vert:
        return 'Faible';
      case Severity.orange:
        return 'Moyen';
      case Severity.rouge:
        return 'Urgent';
    }
  }

  /// Message associé
  String get shortMessage {
    switch (this) {
      case Severity.vert:
        return 'À surveiller';
      case Severity.orange:
        return 'À consulter bientôt';
      case Severity.rouge:
        return 'Consulter rapidement';
    }
  }

  /// Convertit une chaîne en Severity (tolérant aux variations)
  static Severity fromString(String value) {
    final lower = value.toLowerCase().trim();
    switch (lower) {
      case 'vert':
      case 'green':
      case 'faible':
      case 'low':
        return Severity.vert;
      case 'orange':
      case 'moyen':
      case 'medium':
        return Severity.orange;
      case 'rouge':
      case 'red':
      case 'urgent':
      case 'high':
        return Severity.rouge;
      default:
        return Severity.orange;
    }
  }
}

/// Une cause probable identifiée par l'IA
class DiagnosticCause {
  final String cause;       // Description (ex: "Turbo défectueux")
  final int probability;    // Probabilité en % (0-100)
  final Severity severity;  // Niveau de gravité

  DiagnosticCause({
    required this.cause,
    required this.probability,
    required this.severity,
  });

  /// Construit depuis un JSON retourné par Gemini
  factory DiagnosticCause.fromJson(Map<String, dynamic> json) {
    return DiagnosticCause(
      cause: json['cause'] as String? ?? 'Cause inconnue',
      probability: (json['probabilite'] as num?)?.toInt() ?? 0,
      severity: Severity.fromString(json['gravite'] as String? ?? 'orange'),
    );
  }

  Map<String, dynamic> toJson() => {
        'cause': cause,
        'probabilite': probability,
        'gravite': severity.name,
      };
}

/// Résultat complet d'un diagnostic
class DiagnosticResult {
  final String symptoms;               // Symptômes décrits par l'utilisateur
  final List<DiagnosticCause> causes;  // Causes triées par probabilité
  final String recommendation;         // Recommandation générale
  final DateTime createdAt;            // Date du diagnostic

  DiagnosticResult({
    required this.symptoms,
    required this.causes,
    required this.recommendation,
    required this.createdAt,
  });

  /// Gravité maximale du diagnostic
  Severity get maxSeverity {
    if (causes.isEmpty) return Severity.vert;
    final indices = causes.map((c) => c.severity.index).toList();
    final maxIdx = indices.reduce((a, b) => a > b ? a : b);
    return Severity.values[maxIdx];
  }

  /// Cause la plus probable (la première après tri)
  DiagnosticCause? get topCause {
    if (causes.isEmpty) return null;
    return causes.first;
  }

  /// Construit depuis un JSON Gemini + les symptômes
  factory DiagnosticResult.fromGeminiJson({
    required Map<String, dynamic> json,
    required String symptoms,
  }) {
    final causesList = (json['causes'] as List<dynamic>?)
            ?.map((c) => DiagnosticCause.fromJson(c as Map<String, dynamic>))
            .toList() ??
        [];

    // Trier par probabilité décroissante
    causesList.sort((a, b) => b.probability.compareTo(a.probability));

    return DiagnosticResult(
      symptoms: symptoms,
      causes: causesList,
      recommendation: json['recommandation'] as String? ??
          'Consultez un mécanicien qualifié.',
      createdAt: DateTime.now(),
    );
  }

  /// Convertit en Map pour Firestore (historique)
  Map<String, dynamic> toFirestore() => {
        'symptoms': symptoms,
        'causes': causes.map((c) => c.toJson()).toList(),
        'recommendation': recommendation,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}