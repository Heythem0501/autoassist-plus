import 'package:flutter/material.dart';
import '../core/app_theme.dart';

/// Écran des Termes et Conditions d'utilisation
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Termes et conditions'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('1. Acceptation des conditions'),
            _buildParagraph(
              'En utilisant l\'application AutoAssist+, vous acceptez sans réserve '
              'les présentes conditions générales d\'utilisation. Si vous n\'acceptez '
              'pas ces conditions, veuillez ne pas utiliser l\'application.',
            ),
            _buildSectionTitle('2. Description du service'),
            _buildParagraph(
              'AutoAssist+ est une application mobile qui propose :\n'
              '• Un diagnostic automobile assisté par intelligence artificielle\n'
              '• Une localisation des garages, dépanneurs et stations-service\n'
              '• Un suivi personnalisé de l\'entretien du véhicule\n'
              '• Des rappels automatiques pour les entretiens à venir',
            ),
            _buildSectionTitle('3. Responsabilité'),
            _buildParagraph(
              'Le diagnostic fourni par l\'intelligence artificielle est à titre '
              'indicatif uniquement et ne remplace en aucun cas l\'expertise d\'un '
              'mécanicien qualifié. L\'utilisateur est seul responsable des '
              'décisions prises sur la base des informations fournies par l\'application.',
            ),
            _buildSectionTitle('4. Données personnelles'),
            _buildParagraph(
              'Les données collectées (email, informations du véhicule, historique '
              'des entretiens et diagnostics) sont stockées de manière sécurisée '
              'sur les serveurs Firebase (Google Cloud). Elles sont utilisées '
              'uniquement pour le bon fonctionnement de l\'application et ne sont '
              'jamais transmises à des tiers à des fins commerciales.',
            ),
            _buildSectionTitle('5. Géolocalisation'),
            _buildParagraph(
              'L\'application utilise la géolocalisation pour afficher les garages '
              'et services à proximité. Cette fonctionnalité est facultative et '
              'peut être désactivée dans les paramètres Android. La position GPS '
              'n\'est jamais enregistrée sur nos serveurs.',
            ),
            _buildSectionTitle('6. Notifications'),
            _buildParagraph(
              'L\'application envoie des notifications locales pour rappeler les '
              'entretiens à effectuer. Ces notifications sont générées localement '
              'par votre appareil et n\'utilisent aucun service de notification '
              'push externe.',
            ),
            _buildSectionTitle('7. Propriété intellectuelle'),
            _buildParagraph(
              'L\'application AutoAssist+ et son contenu sont la propriété '
              'intellectuelle de ses auteurs : Heythem Ramdani et Taha Mazouz. '
              'Toute reproduction, modification ou distribution sans autorisation '
              'préalable est interdite.',
            ),
            _buildSectionTitle('8. Limitation de responsabilité'),
            _buildParagraph(
              'AutoAssist+ est fourni en l\'état, sans garantie d\'aucune sorte. '
              'Les auteurs ne sauraient être tenus responsables des dommages directs '
              'ou indirects résultant de l\'utilisation de l\'application.',
            ),
            _buildSectionTitle('9. Modifications'),
            _buildParagraph(
              'Ces conditions peuvent être modifiées à tout moment. Les utilisateurs '
              'seront informés des changements importants via l\'application.',
            ),
            _buildSectionTitle('10. Contact'),
            _buildParagraph(
              'Pour toute question concernant ces conditions, vous pouvez nous '
              'contacter par email :\n'
              'haythem.ramdani@gmail.com\n'
              'mazouzt12@gmail.com',
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                '© 2026 AutoAssist+ — Projet de fin d\'études Master 2',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppTheme.primaryBlue,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13.5,
          height: 1.5,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }
}