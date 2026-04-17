import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import 'diagnostic_model.dart';

/// Carte affichant une cause probable du diagnostic
///
/// Affiche :
/// - Icône colorée selon la gravité (vert/orange/rouge)
/// - Nom de la cause
/// - Barre de progression animée montrant le pourcentage
/// - Badge de gravité textuel
class DiagnosticResultCard extends StatelessWidget {
  final DiagnosticCause cause;

  /// Numéro de la cause (1, 2, 3...) pour affichage visuel
  final int rank;

  const DiagnosticResultCard({
    super.key,
    required this.cause,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    final color = cause.severity.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== LIGNE HAUTE : rank + icône + titre + badge =====
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Numéro de rang (1, 2, 3...)
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Titre de la cause + icône
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          cause.severity.icon,
                          color: color,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            cause.cause,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cause.severity.shortMessage,
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Badge de pourcentage
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${cause.probability}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ===== BARRE DE PROGRESSION =====
          _buildProgressBar(color),
        ],
      ),
    );
  }

  /// Barre de progression animée montrant le pourcentage
  Widget _buildProgressBar(Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Stack(
        children: [
          // Fond gris
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: AppTheme.borderGrey,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          // Barre de progression colorée avec animation
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: cause.probability / 100),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return FractionallySizedBox(
                widthFactor: value.clamp(0.0, 1.0),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.7),
                        color,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}