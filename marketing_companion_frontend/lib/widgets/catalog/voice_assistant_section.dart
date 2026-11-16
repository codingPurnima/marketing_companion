import 'package:flutter/material.dart';

class VoiceAssistantSection extends StatelessWidget {
  final TextEditingController controller;
  final bool loading;
  final bool speechAvailable;
  final bool isListening;
  final String speechMessage;
  final VoidCallback onStartListening;
  final VoidCallback onStopListening;
  final VoidCallback onSubmit;

  const VoiceAssistantSection({
    super.key,
    required this.controller,
    required this.loading,
    required this.speechAvailable,
    required this.isListening,
    required this.speechMessage,
    required this.onStartListening,
    required this.onStopListening,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Material(
        elevation: 8,
        color: Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.mic, size: 19),
                  const SizedBox(width: 8),
                  Text(
                    'Artisan Voice Assistant',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const Spacer(),
                  if (isListening)
                    const Text(
                      'Listening…',
                      style: TextStyle(color: Colors.red),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      minLines: 1,
                      maxLines: 3,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) {
                        if (!loading) onSubmit();
                      },
                      decoration: const InputDecoration(
                        hintText: 'Try “Show my products” or “Edit blue vase”',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: isListening ? 'Stop listening' : 'Speak',
                    onPressed: !speechAvailable || loading
                        ? null
                        : isListening
                            ? onStopListening
                            : onStartListening,
                    icon: Icon(isListening ? Icons.stop : Icons.mic),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Run command',
                    onPressed: loading || controller.text.trim().isEmpty
                        ? null
                        : onSubmit,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
              if (speechMessage.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  speechMessage,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}