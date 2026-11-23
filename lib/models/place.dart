import 'package:flutter/material.dart';

import 'review.dart';

/// The categories used by the filters and the Add Place form.
enum PlaceCategory {
  cafes('Cafés', Icons.local_cafe_rounded),
  nature('Nature', Icons.park_rounded),
  beaches('Beaches', Icons.beach_access_rounded),
  historical('Historical', Icons.account_balance_rounded),
  restaurants('Restaurants', Icons.restaurant_rounded),
  viewpoints('Viewpoints', Icons.landscape_rounded);

  final String label;
  final IconData icon;
  const PlaceCategory(this.label, this.icon);
}

/// A destination shown in the app.
class Place {
  final String id;
  final String name;
  final String city;
  final String description;
  final PlaceCategory category;
  final String imageUrl; // may be empty: the UI then shows a placeholder
  final double baseRating; // rating given when the place was created
  final double latitude;
  final double longitude;
  final String address;
  final String? createdBy; // user id of the creator (null for seed data)
  final String? sourceId; // OpenStreetMap id when imported from the API
  final bool isOnline; // true when it comes from Nominatim / Overpass and is not stored yet
  final List<Review> reviews;

  Place({
    required this.id,
    required this.name,
    required this.city,
    required this.description,
    required this.category,
    required this.latitude,
    required this.longitude,
    this.imageUrl = '',
    this.baseRating = 4.0,
    this.address = '',
    this.createdBy,
    this.sourceId,
    this.isOnline = false,
    List<Review>? reviews,
  }) : reviews = reviews ?? [];

  /// Average of the base rating and every review rating.
  double get rating {
    if (reviews.isEmpty) return baseRating;
    final total = reviews.fold<int>(0, (sum, r) => sum + r.rating);
    return (total + baseRating) / (reviews.length + 1);
  }

  /// Text shown under the map/details header (address or coordinates).
  String get addressOrCoordinates => address.isNotEmpty
      ? address
      : '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';

  /// Builds a Place from a row of the `places` table. The optional nested
  /// `reviews` list comes from select('*, reviews(*, profiles(username))').
  factory Place.fromMap(Map<String, dynamic> map) {
    final reviewRows = (map['reviews'] as List<dynamic>?) ?? [];
    final reviews =
        reviewRows
            .map((r) => Review.fromMap(r as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date)); // newest first
    return Place(
      id: map['id'] as String,
      name: map['name'] as String,
      city: map['city'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: PlaceCategory.values.firstWhere(
        (c) => c.name == map['category'],
        orElse: () => PlaceCategory.nature,
      ),
      imageUrl: map['image_url'] as String? ?? '',
      baseRating: (map['base_rating'] as num?)?.toDouble() ?? 4.0,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      address: map['address'] as String? ?? '',
      createdBy: map['created_by'] as String?,
      sourceId: map['source_id'] as String?,
      reviews: reviews,
    );
  }
}
