import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/place.dart';

/// Error with a friendly message for the user.
class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}

/// Talks to the free OpenStreetMap services:
///  - Nominatim: search a place by name (geocoding)
///  - Overpass: find points of interest around a coordinate
class ApiService {
  // The OSM usage policy requires an identifying User-Agent.
  static const _headers = {'User-Agent': 'HiddenTunisiaStudentApp/1.0'};
  static const _timeout = Duration(seconds: 12);
  // Public servers: never send more than one request per second.
  static const _minGap = Duration(seconds: 1);

  DateTime _lastRequest = DateTime.fromMillisecondsSinceEpoch(0);
  // Simple cache so the same query is not sent twice.
  final Map<String, List<Place>> _cache = {};

  /// Waits if the previous request was less than one second ago.
  Future<void> _throttle() async {
    final wait = _minGap - DateTime.now().difference(_lastRequest);
    if (!wait.isNegative) await Future<void>.delayed(wait);
    _lastRequest = DateTime.now();
  }

  /// Sends a request and converts every possible failure to [ApiException].
  Future<dynamic> _getJson(Uri uri) async {
    await _throttle();
    try {
      final response = await http.get(uri, headers: _headers).timeout(_timeout);
      if (response.statusCode == 429) {
        throw const ApiException(
          'Too many requests. Please wait a moment and try again.',
        );
      }
      if (response.statusCode != 200) {
        throw ApiException(
          'The map server is unavailable (error ${response.statusCode}).',
        );
      }
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const ApiException(
        'No internet connection. Showing saved places only.',
      );
    } on http.ClientException {
      throw const ApiException(
        'No internet connection. Showing saved places only.',
      );
    } on TimeoutException {
      throw const ApiException('The server took too long to answer.');
    } on FormatException {
      throw const ApiException('The server sent an unexpected answer.');
    }
  }

  /// Nominatim: searches Tunisia for [query] and returns app Places.
  Future<List<Place>> searchPlaces(String query) async {
    final key = 'search:${query.trim().toLowerCase()}';
    final cached = _cache[key];
    if (cached != null) return cached;

    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': query.trim(),
      'format': 'jsonv2',
      'countrycodes': 'tn',
      'addressdetails': '1',
      'limit': '8',
    });
    final data = await _getJson(uri) as List<dynamic>;

    final places = data.map((item) {
      final json = item as Map<String, dynamic>;
      final address = (json['address'] as Map<String, dynamic>?) ?? {};
      final displayName = json['display_name'] as String? ?? 'Unknown place';
      final name = (json['name'] as String?)?.isNotEmpty == true
          ? json['name'] as String
          : displayName.split(',').first;
      final city =
          (address['city'] ??
                  address['town'] ??
                  address['village'] ??
                  address['state'] ??
                  'Tunisia')
              .toString();
      final osmId = 'osm-${json['osm_type']}-${json['osm_id']}';
      return Place(
        id: osmId,
        sourceId: osmId,
        name: name,
        city: city,
        description: 'Found with OpenStreetMap search. $displayName',
        category: _categoryFromOsm(
          '${json['category'] ?? ''}',
          '${json['type'] ?? ''}',
        ),
        latitude: double.parse('${json['lat']}'),
        longitude: double.parse('${json['lon']}'),
        address: displayName,
        baseRating: 4.0,
        isOnline: true,
      );
    }).toList();

    _cache[key] = places;
    return places;
  }

  /// Overpass: viewpoints, beaches, cafés and historic sites near a point.
  Future<List<Place>> fetchNearbyPlaces(
    double lat,
    double lng, {
    int radiusMeters = 15000,
  }) async {
    // Round the coordinates so nearby requests hit the cache.
    final key =
        'near:${lat.toStringAsFixed(2)},${lng.toStringAsFixed(2)},$radiusMeters';
    final cached = _cache[key];
    if (cached != null) return cached;

    final query =
        '''
[out:json][timeout:20];
(
  node["tourism"="viewpoint"]["name"](around:$radiusMeters,$lat,$lng);
  node["natural"="beach"]["name"](around:$radiusMeters,$lat,$lng);
  node["amenity"="cafe"]["name"](around:$radiusMeters,$lat,$lng);
  node["historic"]["name"](around:$radiusMeters,$lat,$lng);
);
out body 25;
''';
    final uri = Uri.https('overpass-api.de', '/api/interpreter', {
      'data': query,
    });
    final data = await _getJson(uri) as Map<String, dynamic>;
    final elements = (data['elements'] as List<dynamic>?) ?? [];

    final places = elements.map((e) {
      final json = e as Map<String, dynamic>;
      final tags = (json['tags'] as Map<String, dynamic>?) ?? {};
      final category = tags['tourism'] == 'viewpoint'
          ? PlaceCategory.viewpoints
          : tags['natural'] == 'beach'
          ? PlaceCategory.beaches
          : tags['amenity'] == 'cafe'
          ? PlaceCategory.cafes
          : PlaceCategory.historical;
      final osmId = 'osm-node-${json['id']}';
      return Place(
        id: osmId,
        sourceId: osmId,
        name: tags['name'].toString(),
        city: (tags['addr:city'] ?? 'Near you').toString(),
        description: (tags['description'] ?? 'A spot found on OpenStreetMap.')
            .toString(),
        category: category,
        latitude: (json['lat'] as num).toDouble(),
        longitude: (json['lon'] as num).toDouble(),
        isOnline: true,
      );
    }).toList();

    _cache[key] = places;
    return places;
  }

  /// Guesses an app category from OpenStreetMap's class/type.
  PlaceCategory _categoryFromOsm(String osmClass, String osmType) {
    if (osmType == 'beach') return PlaceCategory.beaches;
    if (osmType == 'cafe') return PlaceCategory.cafes;
    if (osmType == 'restaurant') return PlaceCategory.restaurants;
    if (osmType == 'viewpoint') return PlaceCategory.viewpoints;
    if (osmClass == 'historic' || osmType == 'archaeological_site') {
      return PlaceCategory.historical;
    }
    return PlaceCategory.nature;
  }
}
