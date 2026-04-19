import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../vehicle/vehicle_model.dart';
import '../vehicle/vehicle_service.dart';
import 'add_maintenance_screen.dart';
import 'maintenance_constants.dart';
import 'maintenance_history_screen.dart';
import 'maintenance_model.dart';
import 'maintenance_service.dart';
import 'maintenance_type_card.dart';

/// Dashboard principal de l'onglet Entretien
class MaintenanceDashboard extends StatefulWidget {
  const MaintenanceDashboard({super.key});

  @override
  State<MaintenanceDashboard> createState() => _MaintenanceDashboardState();
}

class _MaintenanceDashboardState extends State<MaintenanceDashboard> {
  final _vehicleService = VehicleService();
  final _maintenanceService = MaintenanceService();

  Vehicle? _vehicle;
  Map<String, MaintenanceRecord?> _latestByType = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final vehicle = await _vehicleService.getVehicle();
    final latest = await _maintenanceService.getLatestByType();

    if (!mounted) return;

    setState(() {
      _vehicle = vehicle;
      _latestByType = latest;
      _isLoading = false;
    });
  }

  void _onTypeCardTap(MaintenanceTypeDefinition type) {
    if (_vehicle == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddMaintenanceScreen(
          preselectedType: type,
          currentMileage: _vehicle!.currentMileage,
        ),
      ),
    ).then((_) => _loadData());
  }

  void _openAddScreen() {
    if (_vehicle == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddMaintenanceScreen(
          currentMileage: _vehicle!.currentMileage,
        ),
      ),
    ).then((_) => _loadData());
  }

  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MaintenanceHistoryScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entretien de ma voiture'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Historique',
            onPressed: _openHistory,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _vehicle == null ? null : _openAddScreen,
        backgroundColor: AppTheme.accentOrange,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Ajouter',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _vehicle == null
              ? _buildNoVehicleState()
              : _buildDashboard(),
    );
  }

  Widget _buildDashboard() {
    final mileage = _vehicle!.currentMileage;

    // Compter les urgences
    int overdueCount = 0;
    int soonCount = 0;
    for (final entry in _latestByType.entries) {
      if (entry.value != null) {
        final urg = entry.value!.computeUrgency(currentMileage: mileage);
        if (urg == MaintenanceUrgency.overdue) overdueCount++;
        if (urg == MaintenanceUrgency.soon) soonCount++;
      }
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          _buildSummaryCard(overdueCount, soonCount),
          const SizedBox(height: 20),
          _buildSectionTitle('Tous les entretiens'),
          const SizedBox(height: 8),
          ...MaintenanceConstants.types.map((type) {
            return MaintenanceTypeCard(
              typeDef: type,
              lastRecord: _latestByType[type.id],
              currentMileage: mileage,
              onTap: () => _onTypeCardTap(type),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(int overdue, int soon) {
    final total = MaintenanceConstants.types.length;
    final done = _latestByType.values.where((v) => v != null).length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryBlue, AppTheme.primaryBlueDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_vehicle!.brand} ${_vehicle!.model}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '${_vehicle!.year} · ${_vehicle!.currentMileage} km',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryMetric(
                  label: 'Dépassés',
                  value: overdue.toString(),
                  color: AppTheme.severityRed,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSummaryMetric(
                  label: 'Bientôt',
                  value: soon.toString(),
                  color: AppTheme.severityOrange,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSummaryMetric(
                  label: 'Suivis',
                  value: '$done/$total',
                  color: AppTheme.severityGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetric({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color == AppTheme.severityGreen
                  ? Colors.white
                  : color.withValues(alpha: 0.95),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppTheme.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildNoVehicleState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.directions_car_outlined,
                size: 60, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            const Text(
              'Aucun véhicule enregistré',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text(
              'Rendez-vous dans l\'onglet Profil pour ajouter votre voiture.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}