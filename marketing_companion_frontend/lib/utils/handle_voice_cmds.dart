import 'package:flutter/material.dart';

import '../services/speech_service.dart';
import '../services/voice_command_handler.dart';
import '../services/voice_command_service.dart';
import '../widgets/catalog/voice_command_confirmation_dialog.dart';
import '../models/voice_command_result.dart';

Future<void> processVoiceCommand({
  required BuildContext context,
  required TextEditingController voiceInputController,
  required VoiceCommandHandler voiceCommandHandler,
  required SpeechService speechService,
  required Future<void> Function(Future<void> Function() action) runAction,
  required Future<void> Function() loadDrafts,
  required Future<void> Function() saveDraft,
  required Future<void> Function(Map<String, dynamic> product)
  startEditingProduct,
  required Future<void> Function(String productId, bool publish)
  updatePublication,
  required Future<void> Function(String productId) publishArchivedProduct,
  required bool mounted,
  required bool isEditorMode,
  required List<dynamic> drafts,
  required List<dynamic> archivedProducts,
  required void Function(String message) updateMessage,
  required void Function(String? productId) updateVoiceMatchedProductId,
  required void Function() goHome,
  VoiceCommand? interpretedCommand,
  required Future<bool> Function(
    Map<String, dynamic> product,
    VoiceCommandUpdates updates,
  )
  applyProductUpdates,
  required List<dynamic> Function() getDrafts,
  required List<dynamic> Function() getArchivedProducts,
  required void Function() openAddProduct,
}) async {
  final voiceCommand =
      interpretedCommand ??
      voiceCommandHandler.parse(voiceInputController.text.trim());

  if (voiceCommand.type == VoiceCommandType.unknown) {
    updateMessage('I could not understand that command. Please try again.');
    return;
  }

  voiceInputController.clear();

  if (voiceCommand.type == VoiceCommandType.addProduct) {
    openAddProduct();

    updateMessage('Add Product is ready.');
    await speechService.speak(
      'Add Product is ready. You can enter the product details now.',
    );
    return;
  }

  if (voiceCommand.type == VoiceCommandType.listProducts) {
    await runAction(loadDrafts);

    if (!mounted) return;

    final currentDrafts = getDrafts();

    final response = currentDrafts.isEmpty
        ? 'You have no products in your catalog yet.'
        : 'You have ${currentDrafts.length} products in your catalog.';

    await speechService.speak(response);
    return;
  }

  if (voiceCommand.type == VoiceCommandType.saveDraft) {
    if (!isEditorMode) {
      await speechService.speak(
        'Please open Add Product or Edit Product before saving.',
      );
      return;
    }

    await saveDraft();

    if (!mounted) return;

    await speechService.speak('Draft saved.');
    return;
  }

  if (voiceCommand.type == VoiceCommandType.listArchived) {
    goHome();
    await runAction(loadDrafts);

    if (!mounted) return;

    final count = getArchivedProducts().length;
    final response = count == 0
        ? 'You have no archived products.'
        : 'You have $count archived products. They are displayed on your home screen. Scroll down to view them';

    await speechService.speak(response);
    return;
  }

  final productName = voiceCommand.productName;

  final action = switch (voiceCommand.type) {
    VoiceCommandType.find => 'find',
    VoiceCommandType.edit => 'edit',
    VoiceCommandType.republish => 'republish',
    VoiceCommandType.publish => 'publish',
    VoiceCommandType.archive => 'archive',
    _ => null,
  };

  if (action == null || productName == null || productName.isEmpty) {
    return;
  }

  await runAction(loadDrafts);

  if (!mounted) return;

  final currentDrafts = getDrafts();
  final currentArchivedProducts = getArchivedProducts();

  final matches = voiceCommandHandler.findMatches(
    productName: productName,
    commandType: voiceCommand.type,
    drafts: currentDrafts,
    archivedProducts: currentArchivedProducts,
  );

  if (matches.isEmpty) {
    updateMessage('No matching product found.');
    await speechService.speak(
      'I could not find a product matching $productName.',
    );
    return;
  }

  if (voiceCommandHandler.hasAmbiguousMatches(matches)) {
    final names = matches
        .take(3)
        .map((product) => product['title'].toString())
        .join(', ');

    updateMessage(
      'Multiple products match: $names. Please specify the product more clearly.',
    );

    await speechService.speak(
      'I found multiple matching products. Please specify which product you mean.',
    );
    return;
  }

  final product = matches.first;
  final productId = product['id'].toString();
  final title = product['title']?.toString() ?? 'this product';
  final status = product['status']?.toString();

  if (action == 'find') {
    goHome();
    updateVoiceMatchedProductId(productId);
    updateMessage('Found product: $title');
    await speechService.speak('I found $title.');
    return;
  }

  if (action == 'edit') {
    final updates = voiceCommand.updates;

    final hasUpdates =
        updates != null &&
        (updates.title != null ||
            updates.description != null ||
            updates.category != null ||
            updates.price != null);

    if (hasUpdates) {
      final success = await applyProductUpdates(product, updates);

      if (!mounted) return;

      if (success) {
        updateVoiceMatchedProductId(productId);
        updateMessage('$title has been updated successfully.');
        await speechService.speak('$title has been updated successfully.');
      } else {
        await speechService.speak(
          'I could not update $title. Please check the details.',
        );
      }

      return;
    }

    await startEditingProduct(product);

    updateVoiceMatchedProductId(productId);
    updateMessage('Loaded $title for editing.');

    await speechService.speak(
      'I have loaded $title. You can now edit its details.',
    );

    return;
  }

  if (!voiceCommandHandler.canExecute(
    commandType: voiceCommand.type,
    status: status,
  )) {
    final response = switch (voiceCommand.type) {
      VoiceCommandType.publish =>
        '$title is not a draft. Only drafts can be published.',
      VoiceCommandType.archive => '$title is not currently published.',
      VoiceCommandType.republish => '$title is not archived.',
      _ => 'This action cannot be performed on $title.',
    };

    updateMessage(response);
    await speechService.speak(response);
    return;
  }

  final publish = action == 'publish' || action == 'republish';

  final confirmed = await VoiceCommandConfirmationDialog.show(
    context: context,
    title: title,
    publish: publish,
    speechService: speechService,
  );

  if (!mounted) return;

  if (confirmed != true) {
    updateMessage('Action cancelled.');
    await speechService.speak('Action cancelled.');
    return;
  }

  try {
    if (action == 'republish') {
      await publishArchivedProduct(productId);
    } else {
      await updatePublication(productId, publish);
      await loadDrafts();
    }

    if (!mounted) return;

    final response = action == 'republish'
        ? '$title has been republished successfully.'
        : publish
        ? '$title has been published successfully.'
        : '$title has been archived successfully.';

    updateVoiceMatchedProductId(productId);
    updateMessage(response);
    await speechService.speak(response);
  } catch (e) {
    if (!mounted) return;

    updateMessage('Could not complete the action: $e');
    await speechService.speak('Sorry, the action could not be completed.');
  }
}

Future<void> manageVoiceListening({
  required bool speechAvailable,
  required bool loading,
  required bool isListening,
  required TextEditingController voiceInputController,
  required Future<void> Function({
    required void Function(String recognizedWords) onResult,
  })
  startListening,
  required Future<void> Function() stopListening,
  required Future<void> Function() onStop,
  required void Function(void Function()) updateState,
}) async {
  if (!speechAvailable || loading || isListening) return;

  voiceInputController.clear();

  await startListening(
    onResult: (recognizedWords) {
      updateState(() {
        voiceInputController.text = recognizedWords;
        voiceInputController.selection = TextSelection.collapsed(
          offset: voiceInputController.text.length,
        );
      });
    },
  );

  await onStop();
}

Future<void> stopVoiceListening({
  required Future<void> Function() stopListening,
  required Future<void> Function() onSubmit,
}) async {
  await stopListening();
  await onSubmit();
}
