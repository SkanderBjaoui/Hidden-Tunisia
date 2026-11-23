import 'package:flutter/material.dart';

import '../models/place.dart';
import '../providers/place_provider.dart';

/// Shows a short message at the bottom of the screen.
void showMessage(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

/// Toggles a favorite and tells the user if the database refused it.
Future<void> toggleFavoriteWithFeedback(
  BuildContext context,
  PlaceProvider provider,
  Place place,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final error = await provider.toggleFavorite(place);
  if (error != null) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error)));
  }
}
