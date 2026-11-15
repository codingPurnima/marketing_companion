import 'package:flutter/material.dart';

class VoiceCommandConfirmationDialog extends StatelessWidget {
  final String title;
  final bool publish;

  const VoiceCommandConfirmationDialog({
    super.key,
    required this.title,
    required this.publish,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required bool publish,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => VoiceCommandConfirmationDialog(
        title: title,
        publish: publish,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(
        publish
            ? 'Are you sure you want to publish this product?'
            : 'Are you sure you want to archive this product?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(publish ? 'Publish' : 'Archive'),
        ),
      ],
    );
  }
}