import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/place.dart';
import '../models/profile.dart';
import 'app_exception.dart';

/// All reads and writes on the Supabase PostgreSQL tables.
/// Security is enforced by Row Level Security in the database (see
/// supabase/schema.sql), not only by this code.
class DatabaseService {
  SupabaseClient get _db => Supabase.instance.client;

  static const _placeColumns = '*, reviews(*, profiles(username))';

  String get _userId {
    final id = _db.auth.currentUser?.id;
    if (id == null) throw const AppException('Please log in first.');
    return id;
  }

  // ---------- Places ----------

  /// Every place with its reviews and the reviewers' usernames.
  Future<List<Place>> fetchPlaces() {
    return guardBackend(() async {
      final rows = await _db
          .from('places')
          .select(_placeColumns)
          .order('created_at', ascending: false);
      return rows.map(Place.fromMap).toList();
    });
  }

  Future<Place> insertPlace({
    required String name,
    required String city,
    required String description,
    required PlaceCategory category,
    required int rating,
    required double latitude,
    required double longitude,
    String imageUrl = '',
  }) {
    return guardBackend(() async {
      final row = await _db
          .from('places')
          .insert({
            'name': name,
            'city': city,
            'description': description,
            'category': category.name,
            'base_rating': rating,
            'latitude': latitude,
            'longitude': longitude,
            'image_url': imageUrl.isEmpty ? null : imageUrl,
            'created_by': _userId,
          })
          .select()
          .single();
      return Place.fromMap(row);
    });
  }

  /// Saves a place found through OpenStreetMap into the database (once), so
  /// it can be favorited or reviewed. Returns the stored version.
  Future<Place> storeOnlinePlace(Place place) {
    return guardBackend(() async {
      final existing = await _db
          .from('places')
          .select(_placeColumns)
          .eq('source_id', place.id)
          .maybeSingle();
      if (existing != null) return Place.fromMap(existing);

      final row = await _db
          .from('places')
          .insert({
            'name': place.name,
            'city': place.city,
            'description': place.description,
            'category': place.category.name,
            'base_rating': place.baseRating,
            'latitude': place.latitude,
            'longitude': place.longitude,
            'address': place.address,
            'source_id': place.id,
            'created_by': _userId,
          })
          .select()
          .single();
      return Place.fromMap(row);
    });
  }

  // ---------- Reviews ----------

  /// Creates the user's review of a place, or replaces it if one exists.
  Future<void> saveReview({
    required String placeId,
    required int rating,
    required String comment,
  }) {
    return guardBackend(() async {
      await _db.from('reviews').upsert({
        'place_id': placeId,
        'user_id': _userId,
        'rating': rating,
        'comment': comment,
      }, onConflict: 'place_id,user_id');
    });
  }

  // ---------- Favorites ----------

  Future<Set<String>> fetchFavoriteIds() {
    return guardBackend(() async {
      final rows = await _db
          .from('favorites')
          .select('place_id')
          .eq('user_id', _userId);
      return rows.map((r) => r['place_id'] as String).toSet();
    });
  }

  Future<void> addFavorite(String placeId) {
    return guardBackend(() async {
      await _db.from('favorites').upsert({
        'user_id': _userId,
        'place_id': placeId,
      }, onConflict: 'user_id,place_id');
    });
  }

  Future<void> removeFavorite(String placeId) {
    return guardBackend(() async {
      await _db
          .from('favorites')
          .delete()
          .eq('user_id', _userId)
          .eq('place_id', placeId);
    });
  }

  // ---------- Profile ----------

  Future<Profile?> fetchProfile() {
    return guardBackend(() async {
      final row = await _db
          .from('profiles')
          .select()
          .eq('id', _userId)
          .maybeSingle();
      if (row != null) return Profile.fromMap(row);

      // Safety net: the signup trigger should have created the profile, but
      // if it did not (old account, trigger missing), create it now.
      final user = _db.auth.currentUser!;
      final name = (user.userMetadata?['username'] as String?)?.trim();
      final fallback = (user.email ?? 'explorer').split('@').first;
      final created = await _db
          .from('profiles')
          .upsert({
            'id': user.id,
            'username': (name == null || name.isEmpty) ? fallback : name,
          })
          .select()
          .single();
      return Profile.fromMap(created);
    });
  }

  Future<void> updateUsername(String username) {
    return guardBackend(() async {
      await _db
          .from('profiles')
          .update({'username': username})
          .eq('id', _userId);
    });
  }
}
