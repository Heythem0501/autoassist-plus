import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/app_theme.dart';
import 'maintenance_model.dart';
import 'maintenance_service.dart';

class MaintenanceHistoryScreen extends StatelessWidget {
  const MaintenanceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = MaintenanceService();

    return Scaffold(
      appBar: AppBar(title: const Text('Historique des entretiens')),
      body: StreamBuilder<List<MaintenanceRecord>>(
        stream: service.getRecordsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final records = snapshot.data ?? [];
          if (records.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: records.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final record = records[i];
              return _buildHistoryItem(context, record, service);
            },
          );
        },
      ),
    );
  }

  Widget _buildHistoryItem(
    BuildContext context,
    MaintenanceRecord record,
    MaintenanceService service,
  ) {
    final def = record.typeDefinition;
    final df = DateFormat('dd/MM/yyyy');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderGrey),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlueLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              def?.icon ?? Icons.build_rounded,
              color: AppTheme.primaryBlue,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  def?.label ?? 'Entretien',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 11, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      df.format(record.performedAt),
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.speed_rounded,
                        size: 11, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${record.mileageAtService} km',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                if (record.notes != null && record.notes!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    record.notes!,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppTheme.textPrimary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppTheme.severityRed, size: 20),
            onPressed: () => _confirmDelete(context, record, service),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlueLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.history_rounded,
                  size: 50, color: AppTheme.primaryBlue),
            ),
            const SizedBox(height: 20),
            const Text(
              'Aucun entretien enregistré',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Ajoutez vos entretiens effectués pour suivre les échéances.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    MaintenanceRecord record,
    MaintenanceService service,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer cet entretien ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.severityRed,
              minimumSize: const Size(100, 40),
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await service.deleteRecord(record.id);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}