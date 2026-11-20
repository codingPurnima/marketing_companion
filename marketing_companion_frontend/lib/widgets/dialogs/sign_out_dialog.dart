import 'package:flutter/material.dart';
import '../../services/speech_service.dart';

class SignOutDialog extends StatefulWidget {
  final SpeechService speechService;

  const SignOutDialog({super.key, required this.speechService});

  @override
  State<SignOutDialog> createState() => _SignOutDialogState();
}

class _SignOutDialogState extends State<SignOutDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.speechService.speak(
        'Are you sure you want to sign out of your account?',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sign out?'),
      content: const Text('Are you sure you want to sign out of your account?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Sign out'),
        ),
      ],
    );
  }
}
