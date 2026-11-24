import 'package:flutter/material.dart';
import '../../services/speech_service.dart';
import '../../l10n/ui_text.dart';

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
      title: Text(UiText.get(context, 'signOutConfirmTitle')),
      content: Text(UiText.get(context, 'signOutConfirm')),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(UiText.get(context, 'cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(UiText.get(context, 'signOut')),
        ),
      ],
    );
  }
}
