
import '../utils/product_matcher.dart';

enum VoiceCommandType {
  listProducts,
  saveDraft,
  listArchived,
  find,
  edit,
  republish,
  publish,
  archive,
  unknown,
}

class VoiceCommand {
  final VoiceCommandType type;
  final String? productName;

  const VoiceCommand(this.type, {this.productName});
}

class VoiceCommandService {
  VoiceCommand parse(String input) {
    final command = normalizeVoiceText(input);

    if (command.isEmpty) {
      return const VoiceCommand(VoiceCommandType.unknown);
    }

    const productListCommands = {
      'show my products',
      'show me my products',
      'list my products',
      'load my products',
      'show my catalog',
      'show me my catalog',
      'list my catalog',
    };

    if (productListCommands.contains(command)) {
      return const VoiceCommand(VoiceCommandType.listProducts);
    }

    const saveDraftCommands = {
      'save this draft',
      'save draft',
      'save my draft',
      'save product as draft',
      'save this product as draft',
    };

    if (saveDraftCommands.contains(command)) {
      return const VoiceCommand(VoiceCommandType.saveDraft);
    }

    const archivedProductCommands = {
      'show archived products',
      'show my archived products',
      'load archived products',
      'load my archived products',
      'show archived items',
      'load archived items',
    };

    if (archivedProductCommands.contains(command)) {
      return const VoiceCommand(VoiceCommandType.listArchived);
    }

    final commandPrefixes = <VoiceCommandType, List<String>>{
      VoiceCommandType.find: [
        'find my product',
        'find the product',
        'find product',
        'find my',
        'find',
      ],
      VoiceCommandType.edit: [
        'edit my product',
        'edit the product',
        'edit product',
        'edit my',
        'edit',
      ],
      VoiceCommandType.republish: [
        'republish archived product',
        'republish my archived product',
        'republish the archived product',
        'republish archived',
        'republish product',
        'republish my',
        'republish',
      ],
      VoiceCommandType.publish: [
        'publish my draft',
        'publish the draft',
        'publish draft',
        'publish my product',
        'publish the product',
        'publish product',
        'publish my',
        'publish',
      ],
      VoiceCommandType.archive: [
        'archive my product',
        'archive the product',
        'archive product',
        'archive my',
        'archive',
      ],
    };

    // Unpublish is treated as archive.
    final unpublishName = extractProductName(command, [
      'unpublish my product',
      'unpublish the product',
      'unpublish product',
      'unpublish my',
      'unpublish',
    ]);

    if (unpublishName != null) {
      return VoiceCommand(
        VoiceCommandType.archive,
        productName: unpublishName,
      );
    }

    for (final entry in commandPrefixes.entries) {
      final productName = extractProductName(command, entry.value);

      if (productName != null && productName.isNotEmpty) {
        return VoiceCommand(
          entry.key,
          productName: productName,
        );
      }
    }

    return const VoiceCommand(VoiceCommandType.unknown);
  }
}
