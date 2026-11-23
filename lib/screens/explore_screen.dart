import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/place.dart';
import '../providers/place_provider.dart';
import '../utils/app_colors.dart';
import '../utils/ui.dart';
import '../widgets/category_chip.dart';
import '../widgets/place_card.dart';
import '../widgets/surprise_dialog.dart';
import 'add_place_screen.dart';
import 'place_details_screen.dart';

/// Main discovery page. StatefulWidget because the selected category and the
/// search text change while the user interacts with the screen.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _searchController = TextEditingController();
  PlaceCategory? _selectedCategory; // null means "All"
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openDetails(Place place) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => PlaceDetailsScreen(place: place)));
  }

  void _surpriseMe() {
    final place = context.read<PlaceProvider>().pickSurprise();
    if (place == null) {
      showMessage(context, 'No places to surprise you with yet.');
      return;
    }
    showDialog<void>(
      context: context,
      builder: (_) => SurpriseDialog(initialPlace: place),
    );
  }

  /// Local filtering: category + text in name, city or description.
  List<Place> _filter(List<Place> all) {
    final q = _query.trim().toLowerCase();
    return all.where((p) {
      final matchesCategory =
          _selectedCategory == null || p.category == _selectedCategory;
      final matchesText =
          q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.city.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q);
      return matchesCategory && matchesText;
    }).toList();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
    context.read<PlaceProvider>().clearOnlineResults();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlaceProvider>();
    final results = _filter(provider.places);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : provider.loadError != null && provider.places.isEmpty
            ? _buildLoadError(provider)
            // Pull down to reload the places from Supabase.
            : RefreshIndicator(
                onRefresh: provider.refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 18),
                    _buildSearchBar(),
                    const SizedBox(height: 14),
                    _buildCategories(),
                    const SizedBox(height: 16),
                    _buildSurpriseBanner(),
                    const SizedBox(height: 22),
                    ..._buildOnlineResults(provider),
                    const Text(
                      'Hidden Gems',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.forest,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (results.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text(
                            'No places match your search.',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ),
                      )
                    else
                      ...results.map(
                        (place) => PlaceCard(
                          place: place,
                          isFavorite: provider.isFavorite(place.id),
                          onTap: () => _openDetails(place),
                          onFavorite: () => toggleFavoriteWithFeedback(
                            context,
                            provider,
                            place,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  /// Shown when Supabase could not be reached and nothing is loaded yet.
  Widget _buildLoadError(PlaceProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 56,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(provider.loadError!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: provider.refresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.forest,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.travel_explore_rounded, color: Colors.white),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Hidden Tunisia',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.forest,
            ),
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'Add a place',
          style: IconButton.styleFrom(backgroundColor: AppColors.light),
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const AddPlaceScreen())),
          icon: const Icon(
            Icons.add_location_alt_rounded,
            color: AppColors.forest,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Discover the Tunisia you haven't seen yet.",
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textMuted,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          onChanged: (value) => setState(() => _query = value),
          // Pressing "search" on the keyboard also queries Nominatim.
          onSubmitted: (value) =>
              context.read<PlaceProvider>().searchOnline(value),
          decoration: InputDecoration(
            hintText: 'Search places, cities...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: _clearSearch,
                  ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          CategoryChip(
            label: 'All',
            selected: _selectedCategory == null,
            onTap: () => setState(() => _selectedCategory = null),
          ),
          ...PlaceCategory.values.map(
            (c) => CategoryChip(
              label: c.label,
              icon: c.icon,
              selected: _selectedCategory == c,
              onTap: () => setState(() => _selectedCategory = c),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurpriseBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.forest, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mystery Destination',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Let luck choose your next adventure.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: _surpriseMe,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.forest,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Text(
              'Surprise Me!',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  /// Search button + results coming from the Nominatim API.
  List<Widget> _buildOnlineResults(PlaceProvider provider) {
    final canSearch = _query.trim().length >= 3;
    if (!canSearch &&
        provider.onlineResults.isEmpty &&
        provider.apiError == null) {
      return [];
    }
    return [
      if (canSearch)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: provider.isSearching
                ? null
                : () => provider.searchOnline(_query),
            icon: const Icon(Icons.public_rounded),
            label: Text('Search "${_query.trim()}" on OpenStreetMap'),
          ),
        ),
      if (provider.isSearching)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: CircularProgressIndicator()),
        ),
      if (provider.apiError != null)
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.wifi_off_rounded, color: Colors.orange),
              const SizedBox(width: 10),
              Expanded(child: Text(provider.apiError!)),
            ],
          ),
        ),
      if (provider.onlineResults.isNotEmpty) ...[
        const Text(
          'From OpenStreetMap',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        ...provider.onlineResults.map(
          (place) => PlaceCard(
            place: place,
            isFavorite: provider.isFavorite(place.id),
            onTap: () => _openDetails(place),
            onFavorite: () =>
                toggleFavoriteWithFeedback(context, provider, place),
          ),
        ),
        const SizedBox(height: 10),
      ],
    ];
  }
}
