import 'package:flutter/material.dart';
import 'app_theme.dart';
import '../diagnostic/diagnostic_screen.dart';
import '../map/map_screen.dart';
import '../maintenance/maintenance_dashboard.dart';
import '../profile/profile_screen.dart';

/// Écran principal de l'application avec navigation par onglets
///
/// Contient les 4 sections principales :
/// - Diagnostic : analyse des symptômes avec IA
/// - Carte     : garages et stations à proximité
/// - Entretien : rappels et historique
/// - Profil    : infos véhicule et déconnexion
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  /// Les 4 écrans correspondant aux onglets
  static final List<Widget> _screens = [
    const DiagnosticScreen(),
    const MapScreen(),
    const MaintenanceDashboard(),
    const ProfileScreen(),
  ];

  /// Configuration des onglets (icônes + labels)
  static const List<_TabConfig> _tabs = [
    _TabConfig(
      icon: Icons.medical_services_outlined,
      activeIcon: Icons.medical_services_rounded,
      label: 'Diagnostic',
    ),
    _TabConfig(
      icon: Icons.map_outlined,
      activeIcon: Icons.map_rounded,
      label: 'Carte',
    ),
    _TabConfig(
      icon: Icons.build_outlined,
      activeIcon: Icons.build_rounded,
      label: 'Entretien',
    ),
    _TabConfig(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profil',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack permet de garder l'état de chaque écran
      // (sinon, changer d'onglet réinitialise tout)
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_tabs.length, (index) {
              return _buildTabItem(index);
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(int index) {
    final tab = _tabs[index];
    final isSelected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _currentIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryBlueLight
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? tab.activeIcon : tab.icon,
                color: isSelected
                    ? AppTheme.primaryBlue
                    : AppTheme.textSecondary,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                tab.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? AppTheme.primaryBlue
                      : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Configuration d'un onglet de la BottomNavBar
class _TabConfig {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _TabConfig({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}