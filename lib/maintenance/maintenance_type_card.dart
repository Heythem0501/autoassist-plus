import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/app_theme.dart';
import 'maintenance_constants.dart';
import 'maintenance_model.dart';

/// Card affichant le statut d'un type d'entretien
///
/// - Si jamais effectué : affiche un bouton "Ajouter"
/// - Si déjà effectué : affiche les infos + prochaine échéance + urgence
class MaintenanceTypeCard extends StatelessWidget {
  final MaintenanceTypeDefinition typeDef;
  final MaintenanceRecord? lastRecord;
  final int currentMileage;
  final VoidCallback? onTap;

  const MaintenanceTypeCard({
    super.key,
    required this.typeDef,
    required this.currentMileage,
    this.lastRecord,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasRecord = lastRecord != null;
    final urgency = hasRecord
        ? lastRecord!.computeUrgency(currentMileage: currentMileage)
        : MaintenanceUrgency.ok;

    final borderColor = hasRecord ? urgency.color : AppTheme.borderGrey;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: borderColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(typeDef.icon, color: borderColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        typeDef.label,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      if (hasRecord)
                        _buildStatusLine(urgency)
                      else
                        const Text(
                          'Jamais effectué',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (hasRecord)
                  _buildUrgencyBadge(urgency)
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlueLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded,
                            size: 14, color: AppTheme.primaryBlue),
                        SizedBox(width: 4),
                        Text(
                          'Ajouter',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusLine(MaintenanceUrgency urgency) {
    final df = DateFormat('dd/MM/yyyy');
    final parts = <String>[];

    if (lastRecord!.nextDueDate != null) {
      parts.add('Prochain : ${df.format(lastRecord!.nextDueDate!)}');
    }
    if (lastRecord!.nextDueMileage != null) {
      parts.add('${lastRecord!.nextDueMileage} km');
    }

    return Text(
      parts.isEmpty
          ? 'Fait le ${df.format(lastRecord!.performedAt)}'
          : parts.join(' · '),
      style: TextStyle(
        fontSize: 12,
        color: urgency.color,
        fontWeight: FontWeight.w500,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildUrgencyBadge(MaintenanceUrgency urgency) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: urgency.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(urgency.icon, size: 14, color: urgency.color),
          const SizedBox(width: 4),
          Text(
            urgency.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: urgency.color,
            ),
          ),
        ],
      ),
    );
  }
}