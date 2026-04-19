import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_theme.dart';
import 'location_service.dart';
import 'place_model.dart';

/// Bottom sheet affichant les détails d'un lieu
///
/// Propose 2 actions :
/// - Itinéraire (ouvre Google Maps / Waze / app GPS par défaut)
/// - Appeler (si numéro de téléphone disponible)
class PlaceDetailsSheet extends StatelessWidget {
  final Place place;

  const PlaceDetailsSheet({super.key, required this.place});

  /// Affiche le bottom sheet
  static Future<void> show(BuildContext context, Place place) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PlaceDetailsSheet(place: place),
    );
  }

  /// Ouvre l'application de navigation GPS avec l'itinéraire
  Future<void> _openDirections() async {
    final lat = place.location.latitude;
    final lng = place.location.longitude;
    final name = Uri.encodeComponent(place.name);

    // geo: URI = standard Android qui ouvre Google Maps / Waze / Maps.me etc.
    final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng($name)');
    if (await canLaunchUrl(geoUri)) {
      await launchUrl(geoUri, mode: LaunchMode.externalApplication);
      return;
    }

    // Fallback : ouvrir Google Maps dans le navigateur
    final webUri =
        Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    await launchUrl(webUri, mode: LaunchMode.externalApplication);
  }

  /// Lance un appel téléphonique
  Future<void> _callPhone() async {
    if (place.phone == null) return;
    final telUri = Uri(scheme: 'tel', path: place.phone);
    if (await canLaunchUrl(telUri)) {
      await launchUrl(telUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = place.type.color;

    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.3,
      maxChildSize: 0.75,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barre de drag
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppTheme.borderGrey,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // En-tête : icône + nom + badge type
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      place.type.icon,
                      color: typeColor,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: typeColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                place.type.singular,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: typeColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.near_me_rounded,
                                  size: 12,
                                  color: AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  LocationService.formatDistance(
                                      place.distanceMeters),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Adresse (si disponible)
              if (place.address != null) ...[
                _buildInfoRow(
                  icon: Icons.location_on_rounded,
                  label: 'Adresse',
                  value: place.address!,
                ),
                const SizedBox(height: 12),
              ],

              // Téléphone (si disponible)
              if (place.phone != null) ...[
                _buildInfoRow(
                  icon: Icons.phone_rounded,
                  label: 'Téléphone',
                  value: place.phone!,
                ),
                const SizedBox(height: 12),
              ],

              // Coordonnées GPS (toujours affichées)
              _buildInfoRow(
                icon: Icons.my_location_rounded,
                label: 'Coordonnées',
                value:
                    '${place.location.latitude.toStringAsFixed(5)}, ${place.location.longitude.toStringAsFixed(5)}',
              ),

              const SizedBox(height: 24),

              // Bouton principal : Itinéraire
              ElevatedButton.icon(
                onPressed: _openDirections,
                icon: const Icon(Icons.directions_rounded),
                label: const Text('Itinéraire'),
              ),

              // Bouton secondaire : Appeler (si téléphone dispo)
              if (place.phone != null) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _callPhone,
                  icon: const Icon(Icons.call_rounded),
                  label: const Text('Appeler'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.severityGreen,
                    side: const BorderSide(color: AppTheme.severityGreen),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}