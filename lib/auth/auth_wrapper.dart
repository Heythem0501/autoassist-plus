import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/app_theme.dart';
import '../core/main_screen.dart';
import '../vehicle/vehicle_model.dart';
import '../vehicle/vehicle_service.dart';
import '../vehicle/vehicle_info_screen.dart';
import 'auth_service.dart';
import 'login_screen.dart';

/// Widget racine qui route l'utilisateur selon :
/// 1. Son état d'authentification Firebase (temps réel via StreamBuilder)
/// 2. La présence d'un véhicule enregistré (temps réel via StreamBuilder)
///
/// Parcours :
/// - Non connecté                → LoginScreen
/// - Connecté sans voiture        → VehicleInfoScreen (onboarding)
/// - Connecté avec voiture        → MainScreen (4 onglets)
///
/// L'utilisation de StreamBuilder garantit que les transitions
/// se font automatiquement en temps réel sans redémarrage de l'app.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        if (!authSnapshot.hasData || authSnapshot.data == null) {
          return const LoginScreen();
        }

        return const _VehicleCheckWrapper();
      },
    );
  }
}

// =============================================================================
// Wrapper : vérifie si le user a un véhicule via StreamBuilder
// =============================================================================

class _VehicleCheckWrapper extends StatelessWidget {
  const _VehicleCheckWrapper();

  @override
  Widget build(BuildContext context) {
    final vehicleService = VehicleService();

    return StreamBuilder<Vehicle?>(
      stream: vehicleService.getVehicleStream(),
      builder: (context, vehicleSnapshot) {
        // Pendant le chargement initial
        if (vehicleSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        // Pas de véhicule → onboarding
        if (!vehicleSnapshot.hasData || vehicleSnapshot.data == null) {
          return const VehicleInfoScreen();
        }

        // Véhicule présent → app principale
        return const MainScreen();
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Image.asset(
                  'assets/images/logo_blue.png',
                  color: Colors.white,
                  colorBlendMode: BlendMode.srcIn,
                ),
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