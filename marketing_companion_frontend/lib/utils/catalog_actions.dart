import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/catalog_service.dart';
import '../services/image_service.dart';
import '../services/speech_service.dart';

Future<void> generateCatalogDraft({
  required CatalogService catalogService,
  required TextEditingController inputController,
  required TextEditingController titleController,
  required TextEditingController descriptionController,
  required TextEditingController categoryController,
  required TextEditingController priceController,
  required Future<void> Function(Future<void> Function() action) runAction,
  required SpeechService speechService,
  required void Function(Map<String, dynamic>? draft) updateGeneratedDraft,
  required void Function(String message) updateMessage,
}) async {
  if (inputController.text.trim().isEmpty) {
    updateMessage('Please describe your product first.');
    return;
  }

  await runAction(() async {
    final result = await catalogService.generateCatalog(
      inputController.text.trim(),
    );

    final draft = Map<String, dynamic>.from(result as Map);

    titleController.text = draft['title']?.toString() ?? '';
    descriptionController.text = draft['description']?.toString() ?? '';
    categoryController.text = draft['category']?.toString() ?? 'other';
    priceController.text = draft['price_inr']?.toString() ?? '';

    updateGeneratedDraft(draft);
    updateMessage('Catalog generated. Review the fields before saving.');
    await speechService.speakCatalogSummary(draft);
  });
}

Future<void> saveCatalogDraft({
  required CatalogService catalogService,
  required ImageService imageService,
  required TextEditingController inputController,
  required TextEditingController titleController,
  required TextEditingController descriptionController,
  required TextEditingController categoryController,
  required TextEditingController priceController,
  required Future<void> Function(Future<void> Function() action) runAction,
  required Future<void> Function() loadDrafts,
  required void Function(String message) updateMessage,
  required void Function(void Function()) updateState,
  required void Function() onProductUpdated,
  required Future<void> Function(String productId) uploadProductImage,
  required String? editingProductId,
  required String? savedProductId,
  required XFile? selectedImage,
  required Uint8List? selectedImageBytes,
  required Map<String, dynamic>? generatedDraft,
  required void Function(String? value) setSavedProductId,
  required void Function(String? value) setEditingProductId,
  required void Function(XFile? value) setSelectedImage,
  required void Function(Uint8List? value) setSelectedImageBytes,
  required void Function(Map<String, dynamic>? value) setGeneratedDraft,
}) async {
  await runAction(() async {
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();
    final category = categoryController.text.trim();
    final priceText = priceController.text.trim();

    if (title.isEmpty || description.isEmpty) {
      throw Exception('Title and description are required.');
    }

    const categories = {
      'pottery',
      'textiles',
      'weaving',
      'woodwork',
      'metalwork',
      'jewelry',
      'paintings',
      'other',
    };

    if (!categories.contains(category)) {
      throw Exception('Choose a valid catalog category.');
    }

    final double? price = priceText.isEmpty ? null : double.tryParse(priceText);

    if (priceText.isNotEmpty && (price == null || price < 0)) {
      throw Exception('Enter a valid non-negative price.');
    }

    if (editingProductId != null) {
      await catalogService.updateDraft(
        productId: editingProductId,
        title: title,
        description: description,
        category: category,
        price: price,
      );

      updateState(() {
        setEditingProductId(null);
        titleController.clear();
        descriptionController.clear();
        categoryController.text = 'other';
        priceController.clear();
        updateMessage('Product updated successfully.');
        onProductUpdated();
      });

      await loadDrafts();
      return;
    }

    var productId = savedProductId;

    if (productId == null) {
      final result = await catalogService.createDraft(
        title: title,
        description: description,
        category: category,
        materials: generatedDraft?['materials'] ?? [],
        tags: generatedDraft?['tags'] ?? [],
        price: price,
      );

      if (result is! Map || result['id'] == null) {
        throw Exception(
          'The draft response did not contain a product ID. '
          'Check the backend response before retrying.',
        );
      }

      productId = result['id'].toString();
      setSavedProductId(productId);
    }

    if (selectedImage != null && selectedImageBytes != null) {
      await uploadProductImage(productId);

      updateState(() {
        setSavedProductId(null);
        setEditingProductId(null);
        inputController.clear();
        titleController.clear();
        descriptionController.clear();
        categoryController.text = 'other';
        priceController.clear();
        setGeneratedDraft(null);
        setSelectedImage(null);
        setSelectedImageBytes(null);
        updateMessage('Draft saved and image uploaded successfully.');
      });
    } else {
      updateState(() {
        setSavedProductId(null);
        setEditingProductId(null);
        inputController.clear();
        titleController.clear();
        descriptionController.clear();
        categoryController.text = 'other';
        priceController.clear();
        setGeneratedDraft(null);
        updateMessage('Draft saved successfully.');
      });
    }

    await loadDrafts();
  });
}

Future<void> loadCatalogDrafts({
  required CatalogService catalogService,
  required ImageService imageService,
  required Future<void> Function() loadArchivedProducts,
  required void Function({
    required List<dynamic> drafts,
    required Map<String, String> draftImageUrls,
    required Map<String, String> draftImagePaths,
    required Map<String, String> draftImageIds,
    required Map<String, Map<String, dynamic>> draftImageComparisons,
  })
  updateCatalogState,
}) async {
  final result = await catalogService.getDrafts();

  final urls = <String, String>{};
  final paths = <String, String>{};
  final imageIds = <String, String>{};
  final comparisons = <String, Map<String, dynamic>>{};

  for (final item in result) {
    if (item is! Map || item['id'] == null) continue;

    final productId = item['id'].toString();

    try {
      final imageRows = await imageService.getProductImages(productId);

      if (imageRows.isEmpty) continue;

      final image = imageRows.first;
      final imageId = image['id'].toString();
      final path = image['storage_path'].toString();

      imageIds[productId] = imageId;
      paths[productId] = path;

      final comparison = await imageService.getImageComparison(imageId);

      if (comparison is Map) {
        final comparisonData = Map<String, dynamic>.from(comparison);
        comparisons[productId] = comparisonData;

        final selectedImage = comparisonData['selected_image']?.toString();

        final selectedUrl = selectedImage == 'enhanced'
            ? comparisonData['enhanced_url']
            : comparisonData['original_url'];

        if (selectedUrl != null) {
          urls[productId] = selectedUrl.toString();
        }
      }
    } catch (e) {
      debugPrint('Could not load image for product $productId: $e');
    }
  }

  await loadArchivedProducts();

  updateCatalogState(
    drafts: result,
    draftImageUrls: urls,
    draftImagePaths: paths,
    draftImageIds: imageIds,
    draftImageComparisons: comparisons,
  );
}

Future<void> pickCatalogProductImage({
  required ImageService imageService,
  required void Function(XFile image, Uint8List bytes, String message)
  updateSelectedImage,
  required void Function(String message) updateMessage,
}) async {
  try {
    final image = await imageService.pickImage();

    if (image == null) return;

    final bytes = await imageService.readImageBytes(image);
    updateSelectedImage(
      image,
      bytes,
      'Image selected. Save the draft to upload it.',
    );
  } catch (e) {
    updateMessage('Could not select the image: $e');
  }
}

Future<void> uploadCatalogProductImage({
  required ImageService imageService,
  required XFile? selectedImage,
  required Uint8List? selectedImageBytes,
  required String productId,
  required TextEditingController titleController,
}) async {
  final image = selectedImage;
  final bytes = selectedImageBytes;

  if (image == null || bytes == null) {
    throw Exception('Please select a product image first.');
  }

  await imageService.uploadProductImage(
    productId: productId,
    image: image,
    bytes: bytes,
    title: titleController.text.trim(),
  );
}

Future<void> updateCatalogPublication({
  required CatalogService catalogService,
  required Future<void> Function(Future<void> Function() action) runAction,
  required Future<void> Function() loadDrafts,
  required void Function(String message) updateMessage,
  required String productId,
  required bool publish,
}) async {
  await runAction(() async {
    await catalogService.updatePublication(
      productId: productId,
      publish: publish,
    );

    updateMessage(
      publish
          ? 'Product published successfully.'
          : 'Product unpublished successfully.',
    );

    await loadDrafts();
  });
}

Future<void> requestCatalogImageEnhancement({
  required ImageService imageService,
  required Future<void> Function(Future<void> Function() action) runAction,
  required Future<void> Function() loadDrafts,
  required void Function(String message) updateMessage,
  required String storagePath,
}) async {
  await runAction(() async {
    final result = await imageService.requestEnhancement(storagePath);

    if (result is! Map) {
      throw Exception('Unexpected enhancement response.');
    }

    updateMessage(
      result['message']?.toString() ?? 'Enhancement request completed.',
    );

    await loadDrafts();
  });
}

Future<void> loadArchivedCatalogProducts({
  required CatalogService catalogService,
  required void Function(List<dynamic> archivedProducts) updateArchivedProducts,
  required void Function(String message) updateMessage,
}) async {
  try {
    final response = await catalogService.getArchivedProducts();
    updateArchivedProducts(response);
  } catch (e) {
    updateMessage('Unable to load archived products: $e');
  }
}

Future<void> republishArchivedCatalogProduct({
  required CatalogService catalogService,
  required Future<void> Function() loadDrafts,
  required void Function(bool loading, String message) updateLoadingState,
  required void Function(String message) updateMessage,
  required String productId,
}) async {
  updateLoadingState(true, '');

  try {
    await catalogService.republishArchivedProduct(productId);
    updateMessage('Product republished successfully.');
    await loadDrafts();
  } catch (e) {
    updateMessage('Unable to republish product: $e');
  } finally {
    updateLoadingState(false, '');
  }
}

void applyCatalogNavigation({
  required bool isEditing,
  required String? editingProductId,
  required String? savedProductId,
  required Map<String, dynamic>? generatedDraft,
  required TextEditingController inputController,
  required TextEditingController titleController,
  required TextEditingController descriptionController,
  required TextEditingController categoryController,
  required TextEditingController priceController,
  required void Function(bool isEditorMode) updateView,
  required void Function(String? value) setEditingProductId,
  required void Function(String? value) setSavedProductId,
  required void Function(Map<String, dynamic>? value) setGeneratedDraft,
  required void Function(XFile? value) setSelectedImage,
  required void Function(Uint8List? value) setSelectedImageBytes,
  required void Function(String message) updateMessage,
  required String messageText,
}) {
  if (isEditing) {
    updateView(true);
    return;
  }

  updateView(true);
  setEditingProductId(null);
  setSavedProductId(null);
  setGeneratedDraft(null);

  inputController.clear();
  titleController.clear();
  descriptionController.clear();
  categoryController.text = 'other';
  priceController.clear();

  setSelectedImage(null);
  setSelectedImageBytes(null);

  updateMessage(messageText);
}

void returnCatalogHome({
  required void Function() updateHomeView,
  required void Function(String message) updateMessage,
}) {
  updateHomeView();
  updateMessage('');
}
