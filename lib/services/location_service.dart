import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

/// Error with a message that is safe to show to the user.
class LocationException implements Exception {
  final String message;
  const LocationException(this.message);

  @override
  String toString() => message;
}

/// The "bridge" to native Android features:
///  - GPS through the Geolocator plugin (platform channel under the hood)
///  - the native maps app through the url_launcher plugin
class LocationService {
  /// Asks for permission if needed, then returns the current GPS position.
  Future<LatLng> getCurrentLocation() async {
    // 1. Is the GPS switched on?
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw const LocationException(
        'Location services are turned off. Please enable GPS.',
      );
    }

    // 2. Do we have permission? If not, ask the user.
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationException('Location permission was denied.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        'Location permission is permanently denied. '
        'Enable it in the phone settings.',
      );
    }

    // 3. Read latitude and longitude.
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return LatLng(position.latitude, position.longitude);
    } catch (_) {
      throw const LocationException(
        'Could not get your position. Try again outside or near a window.',
      );
    }
  }

  /// Opens the native maps app with directions to the destination.
  Future<void> openDirections({
    required double latitude,
    required double longitude,
    required String label,
  }) async {
    // "geo:" is the Android way to open any installed maps application.
    final geoUri = Uri.parse(
      'geo:$latitude,$longitude?q=$latitude,$longitude(${Uri.encodeComponent(label)})',
    );
    // Fallback: Google Maps in the browser (also works on emulators without maps).
    final webUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude',
    );

    try {
      if (await launchUrl(geoUri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // ignore and try the fallback below
    }
    try {
      if (await launchUrl(webUri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // handled below
    }
    throw const LocationException('No maps application could be opened.');
  }
}
