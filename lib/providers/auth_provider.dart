import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';

/// Tells the app who is logged in. It listens to Supabase's auth events, so
/// login, logout, an expired session and the reset-password link are all
/// reflected in the UI automatically.
class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();
  late final StreamSubscription<AuthState> _subscription;

  User? user;

  /// True when the user opened the reset-password link from the e-mail and
  /// must now choose a new password.
  bool isRecovering = false;

  AuthProvider() {
    user = _service.currentUser; // restored from the saved session
    _subscription = _service.authChanges.listen((state) {
      user = state.session?.user;
      if (state.event == AuthChangeEvent.passwordRecovery) {
        isRecovering = true;
      } else if (state.event == AuthChangeEvent.signedOut) {
        isRecovering = false;
      }
      notifyListeners();
    });
  }

  bool get isLoggedIn => user != null;
  String? get userId => user?.id;
  String get email => user?.email ?? '';

  // The methods below throw AppException with a friendly message.

  Future<void> signIn(String email, String password) =>
      _service.signIn(email: email, password: password);

  Future<bool> signUp(String email, String password, String username) =>
      _service.signUp(email: email, password: password, username: username);

  Future<void> signOut() => _service.signOut();

  Future<void> sendPasswordReset(String email) =>
      _service.sendPasswordReset(email);

  Future<void> updatePassword(String newPassword) async {
    await _service.updatePassword(newPassword);
    isRecovering = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
