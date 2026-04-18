import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/app_theme.dart';
import 'location_service.dart';
import 'overpass_service.dart';
import 'place_details_sheet.dart';
import 'place_model.dart';

/// Écran Carte — Géolocalisation + recherche de lieux à proximité
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _locationService = LocationService();
  final _overpassService = OverpassService();
  final _mapController = MapController();

  // État de l'écran
  LatLng? _userLocation;
  bool _isLoadingLocation = true;
  String? _locationError;

  PlaceType? _selectedType;
  List<Place> _places = [];
  bool _isSearching = false;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
  }

  // ==========================================================================
  // CHARGEMENT DE LA POSITION
  // ==========================================================================

  /// Récupère la position GPS de l'utilisateur au lancement
  Future<void> _loadUserLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      final position = await _locationService.getCurrentPosition();
      if (!mounted) return;

      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });

      // Centre la carte sur la position
      _mapController.move(_userLocation!, 14);
    } on LocationException catch (e) {
      if (!mounted) return;
      setState(() {
        _locationError = e.message;
        _isLoadingLocation = false;
        // Position de fallback : Alger
        _userLocation = const LatLng(
          LocationService.defaultLatitude,
          LocationService.defaultLongitude,
        );
      });
    }
  }

  // ==========================================================================
  // RECHERCHE DE LIEUX
  // ==========================================================================

  /// Lance une recherche de lieux du type sélectionné autour de la position
  Future<void> _searchPlaces(PlaceType type) async {
    if (_userLocation == null) return;

    setState(() {
      _selectedType = type;
      _isSearching = true;
      _searchError = null;
      _places = [];
    });

    try {
      final results = await _overpassService.searchNearby(
        userLat: _userLocation!.latitude,
        userLng: _userLocation!.longitude,
        type: type,
      );

      if (!mounted) return;
      setState(() {
        _places = results;
        _isSearching = false;
      });

      // Ouvre la liste en bas automatiquement si des résultats
      if (results.isNotEmpty) {
        _showResultsBottomSheet();
      }
    } on OverpassException catch (e) {
      if (!mounted) return;
      setState(() {
        _searchError = e.message;
        _isSearching = false;
      });
    }
  }

  /// Affiche la liste des lieux trouvés dans un bottom sheet
  void _showResultsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
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
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(
                      _selectedType!.icon,
                      color: _selectedType!.color,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${_places.length} ${_selectedType!.label.toLowerCase()}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _places.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 20, endIndent: 20),
                  itemBuilder: (_, index) {
                    final place = _places[index];
                    return _buildPlaceListItem(place, index);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Item de la liste des lieux
  Widget _buildPlaceListItem(Place place, int index) {
    return InkWell(
      onTap: () {
        Navigator.pop(context); // Ferme la liste
        // Centre la carte sur le lieu
        _mapController.move(place.location, 16);
        // Ouvre les détails
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;
          PlaceDetailsSheet.show(context, place);
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: place.type.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: place.type.color,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (place.address != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      place.address!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlueLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                LocationService.formatDistance(place.distanceMeters),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // BUILD PRINCIPAL
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Garages à proximité'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_rounded),
            tooltip: 'Recentrer sur ma position',
            onPressed: _userLocation == null
                ? null
                : () => _mapController.move(_userLocation!, 14),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Cas 1 : chargement de la position
    if (_isLoadingLocation) {
      return const _LoadingView(message: 'Détection de votre position...');
    }

    // Cas 2 : carte + contrôles
    return Stack(
      children: [
        _buildMap(),
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: _buildTypeSelector(),
        ),
        if (_locationError != null)
          Positioned(
            top: 80,
            left: 12,
            right: 12,
            child: _buildInfoBanner(
              _locationError!,
              icon: Icons.warning_amber_rounded,
              color: AppTheme.severityOrange,
            ),
          ),
        if (_searchError != null)
          Positioned(
            top: 80,
            left: 12,
            right: 12,
            child: _buildInfoBanner(
              _searchError!,
              icon: Icons.error_outline_rounded,
              color: AppTheme.severityRed,
            ),
          ),
        if (_places.isNotEmpty)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: _buildResultsBadge(),
          ),
        if (_isSearching)
          const Positioned.fill(
            child: _SearchOverlay(),
          ),
      ],
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _userLocation!,
        initialZoom: 14,
        minZoom: 5,
        maxZoom: 18,
      ),
      children: [
        // Couche de tuiles OpenStreetMap
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'dz.autoassist.autoassist_plus',
          maxZoom: 19,
        ),

        // Marqueur de la position utilisateur (bleu)
        MarkerLayer(
          markers: [
            Marker(
              point: _userLocation!,
              width: 40,
              height: 40,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),

        // Marqueurs des lieux trouvés
        if (_places.isNotEmpty)
          MarkerLayer(
            markers: _places.map((place) => _buildPlaceMarker(place)).toList(),
          ),
      ],
    );
  }

  Marker _buildPlaceMarker(Place place) {
    return Marker(
      point: place.location,
      width: 42,
      height: 50,
      alignment: Alignment.topCenter,
      child: GestureDetector(
        onTap: () => PlaceDetailsSheet.show(context, place),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: place.type.color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                place.type.icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            // Petit triangle pointeur
            CustomPaint(
              size: const Size(10, 6),
              painter: _TrianglePainter(color: place.type.color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: PlaceType.values.map((type) {
          final isSelected = _selectedType == type;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: _isSearching ? null : () => _searchPlaces(type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? type.color.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          type.icon,
                          color: isSelected ? type.color : AppTheme.textSecondary,
                          size: 22,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          type.label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? type.color
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInfoBanner(
    String message, {
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsBadge() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _showResultsBottomSheet,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _selectedType!.color,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _selectedType!.color.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_selectedType!.icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                '${_places.length} ${_selectedType!.label.toLowerCase()} trouvés',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_upward_rounded,
                  color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// WIDGETS UTILITAIRES
// =============================================================================

class _LoadingView extends StatelessWidget {
  final String message;
  const _LoadingView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.primaryBlue),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchOverlay extends StatelessWidget {
  const _SearchOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.3),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppTheme.primaryBlue),
              SizedBox(height: 14),
              Text(
                'Recherche en cours...',
                style: TextStyle(
                  fontSize: 14,
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

/// Petit triangle pointeur sous les marqueurs
class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}