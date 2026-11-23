import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/app_exception.dart';
import '../utils/validators.dart';
import '../widgets/auth_layout.dart';
import '../widgets/custom_button.dart';

/// Shown when the user opens the reset link from the e-mail: they choose a
/// new password. AuthGate displays this screen while isRecovering is true.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<AuthProvider>().updatePassword(
        _passwordController.text,
      );
      messenger.showSnackBar(
        const SnackBar(content: Text('Password updated successfully.')),
      );
      return; // AuthGate switches to the app
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Choose a new password',
      subtitle: 'Pick something you have not used before.',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            if (_error != null) FormErrorBox(message: _error!),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: authInputDecoration(
                'New password',
                Icons.lock_rounded,
              ),
              validator: Validators.password,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmController,
              obscureText: true,
              decoration: authInputDecoration(
                'Confirm new password',
                Icons.lock_outline_rounded,
              ),
              validator: Validators.confirmation(
                () => _passwordController.text,
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              label: 'Save password',
              icon: Icons.check_rounded,
              loading: _loading,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
