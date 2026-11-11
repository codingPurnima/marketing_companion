
import 'package:flutter/material.dart';

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
          '1. Generate catalog',
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
                decoration: const InputDecoration(
                  labelText: 'Describe your product',
                  hintText:
                      'I make handmade blue pottery bowls. Each costs 500 rupees...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: isListening ? 'Stop recording' : 'Start voice input',
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
          child: const Text('Generate Catalog'),
        ),
      ],
    );
  }
}
