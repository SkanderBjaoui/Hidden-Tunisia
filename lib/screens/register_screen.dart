import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/app_exception.dart';
import '../utils/validators.dart';
import '../widgets/auth_layout.dart';
import '../widgets/custom_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _hidePassword = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final signedIn = await context.read<AuthProvider>().signUp(
        _emailController.text,
        _passwordController.text,
        _usernameController.text,
      );
      if (signedIn) {
        // Go back to the root: AuthGate now shows the app.
        navigator.popUntil((route) => route.isFirst);
      } else {
        // The project requires e-mail confirmation before the first login.
        navigator.popUntil((route) => route.isFirst);
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Account created! Check your inbox to confirm your email, then log in.',
            ),
            duration: Duration(seconds: 6),
          ),
        );
      }
      return;
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      showBack: true,
      title: 'Create your account',
      subtitle: 'Join the community of Tunisia explorers.',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            if (_error != null) FormErrorBox(message: _error!),
            TextFormField(
              controller: _usernameController,
              textCapitalization: TextCapitalization.words,
              decoration: authInputDecoration('Username', Icons.person_rounded),
              validator: Validators.username,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: authInputDecoration('Email', Icons.email_rounded),
              validator: Validators.email,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _hidePassword,
              decoration: authInputDecoration(
                'Password',
                Icons.lock_rounded,
                suffix: IconButton(
                  icon: Icon(
                    _hidePassword
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                  ),
                  onPressed: () =>
                      setState(() => _hidePassword = !_hidePassword),
                ),
              ),
              validator: Validators.password,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmController,
              obscureText: _hidePassword,
              decoration: authInputDecoration(
                'Confirm password',
                Icons.lock_outline_rounded,
              ),
              validator: Validators.confirmation(
                () => _passwordController.text,
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              label: 'Create account',
              icon: Icons.person_add_rounded,
              loading: _loading,
              onPressed: _register,
            ),
          ],
        ),
      ),
    );
  }
}
