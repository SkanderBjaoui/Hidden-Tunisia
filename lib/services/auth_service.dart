import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import 'app_exception.dart';

/// Everything related to authentication (Supabase Auth, email + password).
/// The session is saved on the phone by supabase_flutter, so the user stays
/// logged in when the app is reopened.
class AuthService {
  GoTrueClient get _auth => Supabase.instance.client.auth;

  User? get currentUser => _auth.currentUser;

  Stream<AuthState> get authChanges => _auth.onAuthStateChange;

  /// Creates an account. Returns true if the user is signed in right away,
  /// or false when Supabase requires the e-mail to be confirmed first.
  Future<bool> signUp({
    required String email,
    required String password,
    required String username,
  }) {
    return guardBackend(() async {
      final response = await _auth
          .signUp(
            email: email.trim(),
            password: password,
            // Read by the database trigger that creates the profile row.
            data: {'username': username.trim()},
          )
          // Sending the confirmation e-mail can be slow: never wait forever.
          .timeout(const Duration(seconds: 30));
      return response.session != null;
    });
  }

  Future<void> signIn({required String email, required String password}) {
    return guardBackend(() async {
      await _auth
          .signInWithPassword(email: email.trim(), password: password)
          .timeout(const Duration(seconds: 30));
    });
  }

  Future<void> signOut() => guardBackend(() => _auth.signOut());

  /// Sends the "reset your password" e-mail.
  Future<void> sendPasswordReset(String email) {
    return guardBackend(
      () => _auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: SupabaseConfig.authRedirect,
      ),
    );
  }

  /// Sets a new password for the signed-in (or recovering) user.
  Future<void> updatePassword(String newPassword) {
    return guardBackend(
      () => _auth.updateUser(UserAttributes(password: newPassword)),
    );
  }
}
