import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/app_exception.dart';
import '../utils/validators.dart';
import '../widgets/auth_layout.dart';
import '../widgets/custom_button.dart';

/// Asks for the email and sends a reset link through Supabase Auth.
class ForgotPasswordScreen extends StatefulWidget {
  final String initialEmail;

  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController = TextEditingController(
    text: widget.initialEmail,
  );
  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().sendPasswordReset(
        _emailController.text,
      );
      if (mounted) setState(() => _sent = true);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      showBack: true,
      title: 'Forgot password?',
      subtitle:
          "Enter your email and we'll send you a link to choose a new one.",
      child: _sent
          ? Column(
              children: [
                const Icon(
                  Icons.mark_email_read_rounded,
                  size: 64,
                  color: Colors.green,
                ),
                const SizedBox(height: 12),
                Text(
                  'If an account exists for ${_emailController.text.trim()}, '
                  'a reset link is on its way. Open it on this phone.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                CustomButton(
                  label: 'Back to login',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            )
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  if (_error != null) FormErrorBox(message: _error!),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: authInputDecoration(
                      'Email',
                      Icons.email_rounded,
                    ),
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    label: 'Send reset link',
                    icon: Icons.send_rounded,
                    loading: _loading,
                    onPressed: _send,
                  ),
                ],
              ),
            ),
    );
  }
}
