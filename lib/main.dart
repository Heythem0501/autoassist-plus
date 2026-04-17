import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  // Requis pour initialiser les plugins avant runApp
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation de Firebase avec les options générées par FlutterFire
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AutoAssist+',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
      ),
      home: const FirebaseTestScreen(),
    );
  }
}

// Écran temporaire pour tester la connexion Firebase
class FirebaseTestScreen extends StatelessWidget {
  const FirebaseTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isFirebaseReady = Firebase.apps.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        title: const Text('AutoAssist+ - Test Firebase'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isFirebaseReady ? Icons.check_circle : Icons.error,
                size: 120,
                color: isFirebaseReady ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 24),
              Text(
                isFirebaseReady
                    ? '✅ Firebase connecté avec succès !'
                    : '❌ Firebase non connecté',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Projet : ${isFirebaseReady ? Firebase.app().options.projectId : "inconnu"}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              const Text(
                'AutoAssist+ 🚗',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFFF97316),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}