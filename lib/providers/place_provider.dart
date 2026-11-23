import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/place.dart';
import '../models/profile.dart';
import '../models/review.dart';
import '../services/api_service.dart';
import '../services/app_exception.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';

/// Holds the app data loaded from Supabase. Screens listen to it with
/// context.watch / Consumer. It reloads itself when the logged-in user
/// changes and when other users change places or reviews (Realtime).
class PlaceProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final DatabaseService _db = DatabaseService();
  final StorageService _storage = StorageService();
  final Random _random = Random();

  List<Place> _places = [];
  final Set<String> _favoriteIds = {};
  final List<String> _recentSurprises = [];

  String? _userId;
  RealtimeChannel? _channel;
  Timer? _reloadTimer;

  bool isLoading = false;
  String? loadError; // shown with a "Retry" button
  Profile? profile;

  // Results of online features (search / nearby).
  List<Place> onlineResults = [];
  bool isSearching = false;
  String? apiError;

  List<Place> get places => List.unmodifiable(_places);

  List<Place> get favorites =>
      _places.where((p) => _favoriteIds.contains(p.id)).toList();

  String get username => profile?.username ?? 'Explorer';

  int get userPlaceCount =>
      _userId == null ? 0 : _places.where((p) => p.createdBy == _userId).length;

  int get userReviewCount => _userId == null
      ? 0
      : _places.fold(
          0,
          (sum, p) => sum + p.reviews.where((r) => r.userId == _userId).length,
        );

  // ---------- Session handling ----------

  /// Called by AuthProvider whenever the logged-in user changes.
  void onUserChanged(String? userId) {
    if (userId == _userId) return;
    _userId = userId;
    // Wait until the current build finishes before notifying listeners.
    Future.microtask(() {
      if (userId == null) {
        _clear();
      } else {
        _start();
      }
    });
  }

  Future<void> _start() async {
    await _loadData(showSpinner: true);
    _subscribeToChanges();
  }

  void _clear() {
    _unsubscribe();
    _reloadTimer?.cancel();
    _places = [];
    _favoriteIds.clear();
    _recentSurprises.clear();
    profile = null;
    onlineResults = [];
    loadError = null;
    isLoading = false;
    notifyListeners();
  }

  /// Realtime: when anyone adds a place or a review, reload (with a short
  /// delay so several changes cause a single reload).
  void _subscribeToChanges() {
    _unsubscribe();
    final client = Supabase.instance.client;
    _channel = client
        .channel('public-changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'places',
          callback: (_) => _scheduleReload(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'reviews',
          callback: (_) => _scheduleReload(),
        )
        .subscribe();
  }

  void _unsubscribe() {
    final channel = _channel;
    if (channel != null) {
      Supabase.instance.client.removeChannel(channel);
      _channel = null;
    }
  }

  void _scheduleReload() {
    _reloadTimer?.cancel();
    _reloadTimer = Timer(const Duration(milliseconds: 600), _loadData);
  }

  /// Fetches places, favorites and the profile from Supabase.
  Future<void> _loadData({bool showSpinner = false}) async {
    if (_userId == null) return;
    if (showSpinner) {
      isLoading = true;
      loadError = null;
      notifyListeners();
    }
    try {
      final places = await _db.fetchPlaces();
      final favorites = await _db.fetchFavoriteIds();
      final loadedProfile = await _db.fetchProfile();
      _places = places;
      _favoriteIds
        ..clear()
        ..addAll(favorites);
      profile = loadedProfile;
      loadError = null;
    } on AppException catch (e) {
      loadError = e.message;
    }
    isLoading = false;
    notifyListeners();
  }

  /// Pull-to-refresh and "Retry" button.
  Future<void> refresh() => _loadData(showSpinner: _places.isEmpty);

  // ---------- Lookups ----------

  /// Returns the up-to-date version of [place] (reviews change over time and
  /// an OpenStreetMap result may have been stored in the database).
  Place resolve(Place place) {
    for (final p in _places) {
      if (p.id == place.id || (p.sourceId != null && p.sourceId == place.id)) {
        return p;
      }
    }
    return place;
  }

  Review? myReviewFor(Place place) {
    for (final r in resolve(place).reviews) {
      if (r.userId == _userId) return r;
    }
    return null;
  }

  // ---------- Favorites ----------

  bool isFavorite(String id) {
    if (_favoriteIds.contains(id)) return true;
    return _places.any((p) => p.sourceId == id && _favoriteIds.contains(p.id));
  }

  /// Saves an OpenStreetMap result in the database (once) so it can be
  /// favorited or reviewed. Database places are returned unchanged.
  Future<Place> _ensureStored(Place place) async {
    if (!place.isOnline) return place;
    final existing = resolve(place);
    if (!existing.isOnline) return existing;
    final stored = await _db.storeOnlinePlace(place);
    _places = [stored, ..._places];
    return stored;
  }

  /// Adds or removes a favorite. The screen updates immediately and the
  /// change is undone if the database refuses it. Returns an error message
  /// or null.
  Future<String?> toggleFavorite(Place place) async {
    try {
      final stored = await _ensureStored(place);
      final wasFavorite = _favoriteIds.contains(stored.id);
      if (wasFavorite) {
        _favoriteIds.remove(stored.id);
      } else {
        _favoriteIds.add(stored.id);
      }
      notifyListeners();
      try {
        if (wasFavorite) {
          await _db.removeFavorite(stored.id);
        } else {
          await _db.addFavorite(stored.id);
        }
      } on AppException {
        // Undo the optimistic change.
        if (wasFavorite) {
          _favoriteIds.add(stored.id);
        } else {
          _favoriteIds.remove(stored.id);
        }
        notifyListeners();
        rethrow;
      }
      return null;
    } on AppException catch (e) {
      return e.message;
    }
  }

  // ---------- Adding places and reviews ----------

  /// Uploads the optional [image] to Supabase Storage, then inserts the
  /// place. Throws AppException with a friendly message on failure.
  Future<void> addPlace({
    required String name,
    required String city,
    required String description,
    required PlaceCategory category,
    required int rating,
    required double latitude,
    required double longitude,
    String imageUrl = '',
    XFile? image,
  }) async {
    var finalUrl = imageUrl;
    if (image != null) finalUrl = await _storage.uploadPlaceImage(image);

    final place = await _db.insertPlace(
      name: name,
      city: city,
      description: description,
      category: category,
      rating: rating,
      latitude: latitude,
      longitude: longitude,
      imageUrl: finalUrl,
    );
    _places = [place, ..._places];
    notifyListeners();
  }

  /// Creates or updates the logged-in user's review. Throws AppException.
  Future<void> addReview(Place place, int rating, String comment) async {
    final stored = await _ensureStored(place);
    await _db.saveReview(placeId: stored.id, rating: rating, comment: comment);
    await _loadData();
  }

  Future<void> updateUsername(String username) async {
    await _db.updateUsername(username);
    await _loadData(); // reviews show the new name too
  }

  // ---------- Mystery destination ----------

  /// Picks a random place, avoiding the last few that were shown.
  /// Returns null when there are no places yet.
  Place? pickSurprise() {
    if (_places.isEmpty) return null;
    var candidates = _places
        .where((p) => !_recentSurprises.contains(p.id))
        .toList();
    if (candidates.isEmpty) {
      _recentSurprises.clear();
      candidates = List.of(_places);
    }
    final pick = candidates[_random.nextInt(candidates.length)];
    _recentSurprises.add(pick.id);
    // Remember at most half of the places so we never run out of choices.
    if (_recentSurprises.length > max(1, _places.length ~/ 2)) {
      _recentSurprises.removeAt(0);
    }
    return pick;
  }

  // ---------- OpenStreetMap API calls ----------

  /// Searches OpenStreetMap (Nominatim). Errors become [apiError].
  Future<void> searchOnline(String query) async {
    if (query.trim().length < 3) return;
    isSearching = true;
    apiError = null;
    notifyListeners();
    try {
      onlineResults = await _api.searchPlaces(query);
    } on ApiException catch (e) {
      apiError = e.message;
      onlineResults = [];
    }
    isSearching = false;
    notifyListeners();
  }

  /// Converts a city name to coordinates (used by the Add Place form).
  /// Falls back to the centre of Tunisia if the API is not reachable.
  Future<(double, double)> geocodeCity(String city) async {
    try {
      final results = await _api.searchPlaces(city);
      if (results.isNotEmpty) {
        return (results.first.latitude, results.first.longitude);
      }
    } on ApiException {
      // use the fallback below
    }
    return (34.0, 9.5);
  }

  void clearOnlineResults() {
    if (onlineResults.isEmpty && apiError == null) return;
    onlineResults = [];
    apiError = null;
    notifyListeners();
  }

  /// Overpass: spots around a coordinate. Returns an error message or null.
  Future<String?> loadNearby(double lat, double lng) async {
    isSearching = true;
    notifyListeners();
    String? error;
    try {
      onlineResults = await _api.fetchNearbyPlaces(lat, lng);
      if (onlineResults.isEmpty) error = 'No extra spots found around here.';
    } on ApiException catch (e) {
      error = e.message;
    }
    isSearching = false;
    notifyListeners();
    return error;
  }

  @override
  void dispose() {
    _reloadTimer?.cancel();
    _unsubscribe();
    super.dispose();
  }
}
