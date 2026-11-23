import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/place_provider.dart';
import '../services/app_exception.dart';
import '../services/location_service.dart';
import '../utils/app_colors.dart';
import '../utils/ui.dart';
import '../utils/validators.dart';
import '../widgets/custom_button.dart';
import 'add_place_screen.dart';

/// Profile page: account information from Supabase, statistics, a GPS demo
/// and shortcuts. StatefulWidget because it shows the GPS result once it is
/// received.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final LocationService _locationService = LocationService();
  String _locationText = 'Location not checked yet';
  bool _loading = false;

  Future<void> _checkLocation() async {
    setState(() => _loading = true);
    try {
      final p = await _locationService.getCurrentLocation();
      _locationText =
          'Lat ${p.latitude.toStringAsFixed(5)}, Lng ${p.longitude.toStringAsFixed(5)}';
    } on LocationException catch (e) {
      _locationText = e.message;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _editUsername() async {
    final provider = context.read<PlaceProvider>();
    final newName = await showDialog<String>(
      context: context,
      builder: (_) => _UsernameDialog(initial: provider.username),
    );
    if (newName == null || newName == provider.username || !mounted) return;
    try {
      await provider.updateUsername(newName);
      if (mounted) showMessage(context, 'Username updated.');
    } on AppException catch (e) {
      if (mounted) showMessage(context, e.message);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to log in again to use the app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      // AuthGate returns to the login screen automatically.
      await context.read<AuthProvider>().signOut();
    } on AppException catch (e) {
      if (mounted) showMessage(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlaceProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.forest,
                    child: Text(
                      provider.username[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 36,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          provider.username,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.forest,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Edit username',
                        onPressed: _editUsername,
                        icon: const Icon(Icons.edit_rounded, size: 18),
                      ),
                    ],
                  ),
                  Text(
                    auth.email,
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _Stat(value: provider.favorites.length, label: 'Saved'),
                _Stat(value: provider.userPlaceCount, label: 'Places added'),
                _Stat(value: provider.userReviewCount, label: 'Reviews'),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.gps_fixed_rounded, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text(
                        'My GPS position',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _locationText,
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 12),
                  CustomButton(
                    label: 'Get my location',
                    icon: Icons.my_location_rounded,
                    outlined: true,
                    loading: _loading,
                    onPressed: _checkLocation,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            CustomButton(
              label: 'Add a Place',
              icon: Icons.add_location_alt_rounded,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddPlaceScreen()),
              ),
            ),
            const SizedBox(height: 12),
            CustomButton(
              label: 'Log out',
              icon: Icons.logout_rounded,
              outlined: true,
              onPressed: _logout,
            ),
            const SizedBox(height: 24),
            const Center(
              child: Text(
                'Hidden Tunisia · Map data © OpenStreetMap contributors',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog asking for a new username (it owns its controller and form key).
class _UsernameDialog extends StatefulWidget {
  final String initial;

  const _UsernameDialog({required this.initial});

  @override
  State<_UsernameDialog> createState() => _UsernameDialogState();
}

class _UsernameDialogState extends State<_UsernameDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit username'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          validator: Validators.username,
          decoration: const InputDecoration(labelText: 'Username'),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(_controller.text.trim());
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final int value;
  final String label;

  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.light,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.forest,
              ),
            ),
            Text(label, style: const TextStyle(color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
