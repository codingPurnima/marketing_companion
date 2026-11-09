import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isSignUp = false;
  bool loading = false;
  String message = '';

  Future<void> authenticate() async {
    setState(() {
      loading = true;
      message = '';
    });

    try {
      final email = emailController.text.trim();
      final password = passwordController.text;

      if (isSignUp) {
        final response = await supabase.auth.signUp(
          email: email,
          password: password,
        );

        if (response.session == null) {
          message = 'Account created. Check your email to confirm it.';
        }
      } else {
        await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
      }
    } catch (e) {
      message = e is AuthException ? e.message : 'Authentication failed.';
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Artisan Catalog')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            isSignUp ? 'Create account' : 'Sign in',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: loading ? null : authenticate,
            child: Text(
              loading
                  ? 'Please wait...'
                  : isSignUp
                  ? 'Create account'
                  : 'Sign in',
            ),
          ),
          TextButton(
            onPressed: () => setState(() {
              isSignUp = !isSignUp;
              message = '';
            }),
            child: Text(
              isSignUp
                  ? 'Already registered? Sign in'
                  : 'New artisan? Create an account',
            ),
          ),
          if (message.isNotEmpty) SelectableText(message),
        ],
      ),
    );
  }
}
