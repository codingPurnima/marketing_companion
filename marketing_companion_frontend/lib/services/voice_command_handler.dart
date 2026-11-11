
import '../utils/product_matcher.dart';
import 'voice_command_service.dart';

class VoiceCommandHandler {
  final VoiceCommandService commandService;

  VoiceCommandHandler({
    required this.commandService,
  });

  VoiceCommand parse(String input) {
    return commandService.parse(input);
  }

  List<Map<String, dynamic>> findMatches({
    required String productName,
    required VoiceCommandType commandType,
    required List<dynamic> drafts,
    required List<dynamic> archivedProducts,
  }) {
    final sourceProducts = switch (commandType) {
      VoiceCommandType.republish => archivedProducts,
      VoiceCommandType.find => [...drafts, ...archivedProducts],
      _ => drafts,
    };

    return findMatchingProducts(
      productName,
      source: sourceProducts,
    );
  }

  bool hasAmbiguousMatches(List<Map<String, dynamic>> matches) {
    if (matches.length < 2) return false;

    return (matches[0]['_matchScore'] as double) -
            (matches[1]['_matchScore'] as double) <
        0.15;
  }

  bool canExecute({
    required VoiceCommandType commandType,
    required String? status,
  }) {
    return switch (commandType) {
      VoiceCommandType.publish => status == 'draft',
      VoiceCommandType.archive => status == 'published',
      VoiceCommandType.republish => status == 'archived',
      _ => true,
    };
  }
}
