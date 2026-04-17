import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/app_theme.dart';
import '../vehicle/vehicle_service.dart';
import '../vehicle/vehicle_info_screen.dart';
import 'auth_service.dart';
import 'login_screen.dart';

/// Widget racine qui route automatiquement l'utilisateur selon :
/// 1. Son état d'authentification Firebase
/// 2. La présence ou non d'un véhicule enregistré dans Firestore
///
/// Parcours :
/// - Non connecté         → LoginScreen
/// - Connecté sans voiture → VehicleInfoScreen (onboarding)
/// - Connecté avec voiture → HomeScreen
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // État 1 : chargement initial
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        // État 2 : non connecté
        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginScreen();
        }

        // État 3 : connecté → vérifier si un véhicule existe
        return const _VehicleCheckWrapper();
      },
    );
  }
}

// =============================================================================
// WRAPPER : vérifie si le user connecté a déjà renseigné sa voiture
// =============================================================================

class _VehicleCheckWrapper extends StatelessWidget {
  const _VehicleCheckWrapper();

  @override
  Widget build(BuildContext context) {
    final vehicleService = VehicleService();

    return FutureBuilder<bool>(
      future: vehicleService.hasVehicle(),
      builder: (context, snapshot) {
        // Chargement en cours
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        // Pas de véhicule → onboarding
        final hasVehicle = snapshot.data ?? false;
        if (!hasVehicle) {
          return const VehicleInfoScreen();
        }

        // Véhicule présent → accueil
        return const HomeScreen();
      },
    );
  }
}

// =============================================================================
// SPLASH SCREEN
// =============================================================================

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.directions_car_rounded,
                size: 70,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'AutoAssist',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  TextSpan(
                    text: '+',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentOrange,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// ÉCRAN D'ACCUEIL TEMPORAIRE (mis à jour pour afficher la voiture)
// =============================================================================

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final vehicleService = VehicleService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('AutoAssist+'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Se déconnecter',
            onPressed: () async {
              await AuthService().signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.severityGreen.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 80,
                  color: AppTheme.severityGreen,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Bienvenue ! 👋',
                style: Theme.of(context).textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Vous êtes connecté en tant que :',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                user?.email ?? 'utilisateur',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryBlue,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // ===== Carte avec le véhicule enregistré =====
              StreamBuilder(
                stream: vehicleService.getVehicleStream(),
                builder: (context, snapshot) {
                  final vehicle = snapshot.data;
                  if (vehicle == null) {
                    return const SizedBox.shrink();
                  }

                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlueLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.directions_car_rounded,
                          size: 40,
                          color: AppTheme.primaryBlue,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${vehicle.brand} ${vehicle.model}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${vehicle.year} · ${vehicle.fuelType.label} · ${vehicle.currentMileage} km',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.accentOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.construction_rounded,
                      size: 32,
                      color: AppTheme.accentOrange,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Phase 4 validée ✓',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: AppTheme.accentOrange),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Prochaines phases :\nDiagnostic IA · Carte · Entretien',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}