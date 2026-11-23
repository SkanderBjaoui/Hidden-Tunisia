import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'providers/auth_provider.dart';
import 'providers/place_provider.dart';
import 'screens/auth_gate.dart';
import 'utils/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (SupabaseConfig.isConfigured) {
    // Connects to Supabase and restores the saved login session (if any).
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
    );
  }
  runApp(const HiddenTunisiaApp());
}

class HiddenTunisiaApp extends StatelessWidget {
  const HiddenTunisiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final app = MaterialApp(
      title: 'Hidden Tunisia',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          surface: AppColors.background,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.forest,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      ),
      home: SupabaseConfig.isConfigured
          ? const AuthGate()
          : const _SetupRequiredScreen(),
    );

    if (!SupabaseConfig.isConfigured) return app;

    // The providers must be ABOVE MaterialApp: screens opened with
    // Navigator.push (Register, Details, Add Place...) live outside `home`.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // PlaceProvider follows the logged-in user: it loads the data
        // after login and clears it after logout.
        ChangeNotifierProxyProvider<AuthProvider, PlaceProvider>(
          create: (_) => PlaceProvider(),
          update: (_, auth, places) {
            places!.onUserChanged(auth.userId);
            return places;
          },
        ),
      ],
      child: app,
    );
  }
}

/// Shown if the app was started without the Supabase keys.
class _SetupRequiredScreen extends StatelessWidget {
  const _SetupRequiredScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.vpn_key_rounded, size: 56, color: AppColors.primary),
              SizedBox(height: 16),
              Text(
                'Supabase is not configured',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 12),
              Text(
                'Copy env.example.json to env.json, fill in your project URL '
                'and anon key, then run:\n\n'
                'flutter run --dart-define-from-file=env.json',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
