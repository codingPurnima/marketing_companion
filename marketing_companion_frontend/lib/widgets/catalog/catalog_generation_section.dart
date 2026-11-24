import 'package:flutter/material.dart';
import '../../l10n/ui_text.dart';

class CatalogGenerationSection extends StatelessWidget {
  final TextEditingController inputController;
  final bool loading;
  final bool speechAvailable;
  final bool isListening;
  final String speechMessage;
  final VoidCallback onGenerate;
  final VoidCallback onStartListening;
  final VoidCallback onStopListening;

  const CatalogGenerationSection({
    super.key,
    required this.inputController,
    required this.loading,
    required this.speechAvailable,
    required this.isListening,
    required this.speechMessage,
    required this.onGenerate,
    required this.onStartListening,
    required this.onStopListening,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          UiText.get(context, 'speakGenerate'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: inputController,
                minLines: 3,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: UiText.get(context, 'describeProduct'),
                  hintText: UiText.isHindi(context)
                      ? 'मैं हाथ से मिट्टी के बर्तन बनाता हूँ। प्रत्येक की कीमत 500 रुपये है...'
                      : 'I make handmade blue pottery bowls. Each costs 500 rupees...',
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: isListening
                  ? UiText.get(context, 'stopRecording')
                  : UiText.get(context, 'startInput'),
              onPressed: !speechAvailable
                  ? null
                  : isListening
                  ? onStopListening
                  : onStartListening,
              icon: Icon(isListening ? Icons.stop : Icons.mic),
            ),
          ],
        ),
        if (speechMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              speechMessage,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: loading || inputController.text.trim().isEmpty
              ? null
              : onGenerate,
          child: Text(UiText.get(context, 'generateCatalog')),
        ),
      ],
    );
  }
}
