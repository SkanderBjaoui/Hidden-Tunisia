/// Supabase connection settings.
///
/// The values are NOT written in the code. They are passed when running:
///   flutter run --dart-define-from-file=env.json
/// Only the public "anon" key belongs here. Never use the service_role key
/// in a mobile app: it bypasses all security rules.
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

  /// Where Supabase sends the user back after clicking the reset-password
  /// e-mail link. Must also be added in Dashboard > Authentication > URL
  /// Configuration > Redirect URLs, and matches AndroidManifest.xml.
  static const String authRedirect =
      'io.supabase.hiddentunisia://login-callback/';

  static const String imageBucket = 'place-images';
}
