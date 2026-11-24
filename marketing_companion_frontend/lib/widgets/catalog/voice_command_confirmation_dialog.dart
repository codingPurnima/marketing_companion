import 'package:flutter/material.dart';
import '../../services/speech_service.dart';
import '../../l10n/ui_text.dart';

class VoiceCommandConfirmationDialog extends StatefulWidget {
  final String title;
  final bool publish;
  final SpeechService speechService;

  const VoiceCommandConfirmationDialog({
    super.key,
    required this.title,
    required this.publish,
    required this.speechService,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required bool publish,
    required SpeechService speechService,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => VoiceCommandConfirmationDialog(
        title: title,
        publish: publish,
        speechService: speechService,
      ),
    );
  }

  @override
  State<VoiceCommandConfirmationDialog> createState() =>
      _VoiceCommandConfirmationDialogState();
}

class _VoiceCommandConfirmationDialogState
    extends State<VoiceCommandConfirmationDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final action = widget.publish ? 'publish' : 'archive';
      widget.speechService.speak(
        '${widget.title}. Are you sure you want to $action this product?',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Text(
        UiText.isHindi(context)
            ? widget.publish
                  ? 'क्या आप इस उत्पाद को प्रकाशित करना चाहते हैं?'
                  : 'क्या आप इस उत्पाद को आर्काइव करना चाहते हैं?'
            : widget.publish
            ? 'Are you sure you want to publish this product?'
            : 'Are you sure you want to archive this product?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(UiText.get(context, 'cancel')),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            UiText.get(context, widget.publish ? 'publish' : 'archive'),
          ),
        ),
      ],
    );
  }
}
