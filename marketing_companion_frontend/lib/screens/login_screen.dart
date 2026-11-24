import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../l10n/generated/app_localizations.dart';

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

  bool obscurePassword = true;

  Future<void> authenticate() async {
    setState(() {
      loading = true;
      message = '';
    });

    final l10n = AppLocalizations.of(context)!;

    try {
      final email = emailController.text.trim();
      final password = passwordController.text;

      if (isSignUp) {
        final response = await supabase.auth.signUp(
          email: email,
          password: password,
        );

        if (response.session == null) {
          message = l10n.accountCreatedCheckEmail;
        }
      } else {
        await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
      }
    } catch (e) {
      message = e is AuthException
          ? e.message
          : l10n.authenticationFailed;
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            isSignUp ? l10n.createAccount : l10n.signIn,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: l10n.email,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: passwordController,
            obscureText: obscurePassword,
            decoration: InputDecoration(
              labelText: l10n.password,
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    obscurePassword = !obscurePassword;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: loading ? null : authenticate,
            child: Text(
              loading
                  ? l10n.pleaseWait
                  : isSignUp
                      ? l10n.createAccount
                      : l10n.signIn,
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                isSignUp = !isSignUp;
                message = '';
              });
            },
            child: Text(
              isSignUp
                  ? l10n.alreadyRegistered
                  : l10n.newArtisanCreateAccount,
            ),
          ),
          if (message.isNotEmpty)
            SelectableText(message),
        ],
      ),
    );
  }
}