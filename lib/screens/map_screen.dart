import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/place.dart';
import '../providers/place_provider.dart';
import '../services/location_service.dart';
import '../utils/app_colors.dart';
import '../widgets/category_chip.dart';
import '../widgets/place_image.dart';
import 'place_details_screen.dart';

/// Interactive OpenStreetMap. StatefulWidget: it keeps the selected filter,
/// the selected marker, the user position and the map controller.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();

  static const _tunisiaCenter = LatLng(34.0, 9.5);

  // Quick-jump regions so the user can explore the whole country.
  static const _regions = <String, (LatLng, double)>{
    'All Tunisia': (_tunisiaCenter, 6.0),
    'Tunis & Cap Bon': (LatLng(36.8, 10.5), 9.0),
    'North-West': (LatLng(36.9, 8.9), 8.5),
    'Centre': (LatLng(35.6, 10.1), 8.5),
    'South': (LatLng(33.4, 9.0), 7.0),
    'Djerba': (LatLng(33.8, 10.85), 10.0),
  };

  PlaceCategory? _selectedCategory; // null = show all categories
  Place? _selectedPlace;
  LatLng? _userPosition;
  bool _locating = false;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  /// Uses the GPS (native bridge) and moves the map to the user.
  Future<void> _goToMyLocation() async {
    setState(() => _locating = true);
    try {
      final position = await _locationService.getCurrentLocation();
      if (!mounted) return;
      setState(() => _userPosition = position);
      _mapController.move(position, 13);
    } on LocationException catch (e) {
      if (mounted) _showMessage(e.message);
    }
    if (mounted) setState(() => _locating = false);
  }

  /// Overpass API: load extra spots around the centre of the map.
  Future<void> _loadNearby() async {
    final center = _mapController.camera.center;
    final error = await context.read<PlaceProvider>().loadNearby(
      center.latitude,
      center.longitude,
    );
    if (error != null && mounted) _showMessage(error);
  }

  void _openDetails(Place place) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => PlaceDetailsScreen(place: place)));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlaceProvider>();
    final allPlaces = [...provider.places, ...provider.onlineResults];
    final visible = allPlaces
        .where(
          (p) => _selectedCategory == null || p.category == _selectedCategory,
        )
        .toList();

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _tunisiaCenter,
              initialZoom: 6,
              minZoom: 5,
              maxZoom: 18,
              // Tapping the map (not a marker) closes the preview.
              onTap: (_, _) => setState(() => _selectedPlace = null),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.hidden_tunisia',
              ),
              MarkerLayer(
                markers: [
                  for (final place in visible)
                    Marker(
                      point: LatLng(place.latitude, place.longitude),
                      width: 44,
                      height: 44,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedPlace = place),
                        child: _MarkerIcon(
                          place: place,
                          selected: _selectedPlace?.id == place.id,
                        ),
                      ),
                    ),
                  if (_userPosition != null)
                    Marker(
                      point: _userPosition!,
                      width: 30,
                      height: 30,
                      child: const Icon(
                        Icons.my_location_rounded,
                        color: Colors.blue,
                        size: 30,
                      ),
                    ),
                ],
              ),
              const SimpleAttributionWidget(
                source: Text('© OpenStreetMap contributors'),
              ),
            ],
          ),
          // Filters + regions at the top
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _buildChipRow([
                  CategoryChip(
                    label: 'All',
                    selected: _selectedCategory == null,
                    onTap: () => setState(() => _selectedCategory = null),
                  ),
                  for (final c in PlaceCategory.values)
                    CategoryChip(
                      label: c.label,
                      icon: c.icon,
                      selected: _selectedCategory == c,
                      onTap: () => setState(() {
                        _selectedCategory = c;
                        _selectedPlace = null;
                      }),
                    ),
                ]),
                const SizedBox(height: 6),
                _buildChipRow([
                  for (final entry in _regions.entries)
                    ActionChip(
                      avatar: const Icon(Icons.map_rounded, size: 16),
                      label: Text(entry.key),
                      backgroundColor: AppColors.light,
                      side: BorderSide.none,
                      onPressed: () =>
                          _mapController.move(entry.value.$1, entry.value.$2),
                    ),
                ]),
              ],
            ),
          ),
          // Buttons on the right
          Positioned(
            right: 16,
            bottom: _selectedPlace == null ? 24 : 150,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'nearby',
                  tooltip: 'Find nearby spots (OpenStreetMap)',
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.forest,
                  onPressed: provider.isSearching ? null : _loadNearby,
                  child: provider.isSearching
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.travel_explore_rounded),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: 'gps',
                  tooltip: 'My location',
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  onPressed: _locating ? null : _goToMyLocation,
                  child: _locating
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.gps_fixed_rounded),
                ),
              ],
            ),
          ),
          // Preview card of the selected marker
          if (_selectedPlace != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _PlacePreview(
                place: _selectedPlace!,
                onTap: () => _openDetails(_selectedPlace!),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChipRow(List<Widget> chips) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: chips
            .map(
              (c) =>
                  Padding(padding: const EdgeInsets.only(right: 8), child: c),
            )
            .toList(),
      ),
    );
  }
}

/// Pin drawn for each place on the map.
class _MarkerIcon extends StatelessWidget {
  final Place place;
  final bool selected;

  const _MarkerIcon({required this.place, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: selected ? AppColors.forest : AppColors.primary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
      ),
      child: Icon(place.category.icon, color: Colors.white, size: 22),
    );
  }
}

/// Small card shown when a marker is tapped.
class _PlacePreview extends StatelessWidget {
  final Place place;
  final VoidCallback onTap;

  const _PlacePreview({required this.place, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 100,
          child: Row(
            children: [
              PlaceImage(
                url: place.imageUrl,
                width: 100,
                height: 100,
                fallbackIcon: place.category.icon,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        place.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${place.category.label} · ${place.city}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 18,
                            color: AppColors.star,
                          ),
                          Text(place.rating.toStringAsFixed(1)),
                          const Spacer(),
                          const Text(
                            'Details',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
