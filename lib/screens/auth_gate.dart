import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'home_shell.dart';
import 'login_screen.dart';
import 'reset_password_screen.dart';

/// Decides what to show: the app (logged in), the login screen (logged out)
/// or the new-password screen (reset link opened). It rebuilds by itself
/// whenever the Supabase session changes.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.isRecovering) return const ResetPasswordScreen();
    if (auth.isLoggedIn) return const HomeShell();
    return const LoginScreen();
  }
}
