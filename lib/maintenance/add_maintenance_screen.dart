import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../core/app_theme.dart';
import '../notifications/notification_service.dart';
import 'maintenance_constants.dart';
import 'maintenance_model.dart';
import 'maintenance_service.dart';

/// Écran d'ajout d'un entretien effectué
class AddMaintenanceScreen extends StatefulWidget {
  final MaintenanceTypeDefinition? preselectedType;
  final int currentMileage;

  const AddMaintenanceScreen({
    super.key,
    this.preselectedType,
    required this.currentMileage,
  });

  @override
  State<AddMaintenanceScreen> createState() => _AddMaintenanceScreenState();
}

class _AddMaintenanceScreenState extends State<AddMaintenanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mileageController = TextEditingController();
  final _notesController = TextEditingController();
  final _service = MaintenanceService();
  final _notifService = NotificationService();

  MaintenanceTypeDefinition? _selectedType;
  DateTime _performedAt = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.preselectedType;
    _mileageController.text = widget.currentMileage.toString();
  }

  @override
  void dispose() {
    _mileageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _performedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('fr'),
    );
    if (picked != null) {
      setState(() => _performedAt = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedType == null) {
      _showError('Veuillez sélectionner un type d\'entretien');
      return;
    }

    setState(() => _isLoading = true);

    final record = MaintenanceRecord(
      id: '',
      typeId: _selectedType!.id,
      performedAt: _performedAt,
      mileageAtService: int.parse(_mileageController.text),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    final error = await _service.addRecord(record);

    if (!mounted) return;

    if (error != null) {
      setState(() => _isLoading = false);
      _showError(error);
      return;
    }

    // Programmer une notification de rappel si possible
    await _scheduleReminder(record);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('✅ Entretien enregistré avec succès !'),
        backgroundColor: AppTheme.severityGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
    );

    Navigator.pop(context);
  }

  /// Programme une notification 7 jours avant l'échéance (si applicable)
  Future<void> _scheduleReminder(MaintenanceRecord record) async {
    final dueDate = record.nextDueDate;
    if (dueDate == null) return;

    final reminderDate = dueDate.subtract(const Duration(days: 7));
    if (reminderDate.isBefore(DateTime.now())) return;

    // ID basé sur le hash du typeId (stable)
    final notifId = record.typeId.hashCode;

    await _notifService.scheduleMaintenanceReminder(
      id: notifId,
      title: '🔧 Rappel d\'entretien',
      body:
          '${_selectedType!.label} à prévoir bientôt (dans 7 jours environ).',
      scheduledDate: reminderDate,
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.severityRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMMM yyyy', 'fr');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un entretien'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Type d'entretien
                Text(
                  'Type d\'entretien',
                  style: _labelStyle(),
                ),
                const SizedBox(height: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _pickType(context),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderGrey),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _selectedType?.icon ?? Icons.build_rounded,
                          color: AppTheme.primaryBlue,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedType?.label ??
                                'Sélectionner un type...',
                            style: TextStyle(
                              fontSize: 14,
                              color: _selectedType == null
                                  ? AppTheme.textSecondary
                                  : AppTheme.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down_rounded,
                            color: AppTheme.textSecondary),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Date
                Text('Date de l\'entretien', style: _labelStyle()),
                const SizedBox(height: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderGrey),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            color: AppTheme.primaryBlue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            df.format(_performedAt),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppTheme.textSecondary),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Kilométrage
                Text('Kilométrage lors de l\'entretien',
                    style: _labelStyle()),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _mileageController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(7),
                  ],
                  decoration: const InputDecoration(
                    hintText: 'ex: 85000',
                    prefixIcon: Icon(Icons.speed_outlined,
                        color: AppTheme.primaryBlue),
                    suffixText: 'km',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Kilométrage requis';
                    }
                    final km = int.tryParse(value);
                    if (km == null) return 'Valeur invalide';
                    if (km < 0) return 'Doit être positif';
                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // Notes
                Text('Notes (optionnel)', style: _labelStyle()),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    hintText: 'ex: Huile 5W30 Total Quartz...',
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 50),
                      child: Icon(Icons.notes_rounded,
                          color: AppTheme.primaryBlue),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Bouton enregistrer
                ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text('Enregistrer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TextStyle _labelStyle() => const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary,
        letterSpacing: 0.3,
      );

  /// Affiche le sélecteur de type d'entretien
  Future<void> _pickType(BuildContext context) async {
    final selected = await showModalBottomSheet<MaintenanceTypeDefinition>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppTheme.borderGrey,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Choisir un type d\'entretien',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: MaintenanceConstants.types.length,
                itemBuilder: (_, i) {
                  final t = MaintenanceConstants.types[i];
                  return ListTile(
                    leading: Icon(t.icon, color: AppTheme.primaryBlue),
                    title: Text(t.label),
                    subtitle: Text(t.description),
                    onTap: () => Navigator.pop(context, t),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (selected != null) {
      setState(() => _selectedType = selected);
    }
  }
}