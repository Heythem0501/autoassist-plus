import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/app_theme.dart';
import '../core/main_screen.dart';
import '../vehicle/vehicle_service.dart';
import '../vehicle/vehicle_info_screen.dart';
import 'auth_service.dart';
import 'login_screen.dart';

/// Widget racine qui route l'utilisateur selon :
/// 1. Son état d'authentification Firebase
/// 2. La présence ou non d'un véhicule enregistré
///
/// Parcours :
/// - Non connecté                → LoginScreen
/// - Connecté sans voiture        → VehicleInfoScreen (onboarding)
/// - Connecté avec voiture        → MainScreen (4 onglets)
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginScreen();
        }

        return const _VehicleCheckWrapper();
      },
    );
  }
}

// =============================================================================
// Wrapper : vérifie si le user a un véhicule, sinon onboarding
// =============================================================================

class _VehicleCheckWrapper extends StatelessWidget {
  const _VehicleCheckWrapper();

  @override
  Widget build(BuildContext context) {
    final vehicleService = VehicleService();

    return FutureBuilder<bool>(
      future: vehicleService.hasVehicle(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        final hasVehicle = snapshot.data ?? false;
        if (!hasVehicle) {
          return const VehicleInfoScreen();
        }

        // Véhicule présent → affichage de l'app principale à 4 onglets
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