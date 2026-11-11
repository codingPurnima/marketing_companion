import 'dart:typed_data';
import '../services/api_service.dart';
import 'package:flutter/material.dart';

import '../config/app_config.dart';
import 'profile_screen.dart';

import 'package:share_plus/share_plus.dart';

import '../services/image_service.dart';
import '../services/speech_service.dart';
import '../services/voice_command_service.dart';
import '../widgets/catalog/catalog_generation_section.dart';
import '../widgets/catalog/product_editor_section.dart';
import '../widgets/catalog/product_list_section.dart';
import '../widgets/catalog/archived_products_section.dart';
import '../services/catalog_service.dart';
import '../services/voice_command_handler.dart';
import '../widgets/catalog/voice_command_confirmation_dialog.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final inputController = TextEditingController();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final categoryController = TextEditingController(text: 'other');
  final priceController = TextEditingController();

  Map<String, String> draftImagePaths = {};

  late final ApiService apiService;
  late final ImageService imageService;
  final SpeechService speechService = SpeechService();
  late final VoiceCommandHandler voiceCommandHandler;
  late final CatalogService catalogService;

  XFile? selectedImage;
  Uint8List? selectedImageBytes;

  String? savedProductId;
  Map<String, String> draftImageUrls = {};

  Map<String, String> draftImageIds = {};
  Map<String, Map<String, dynamic>> draftImageComparisons = {};

  Map<String, dynamic>? generatedDraft;
  List<dynamic> drafts = [];

  bool loading = false;
  String message = '';

  String? editingProductId;

  bool speechAvailable = false;
  bool isListening = false;
  String speechMessage = '';

  List<dynamic> archivedProducts = [];

  String? voiceMatchedProductId;

  void startEditingProduct(Map<String, dynamic> product) {
    setState(() {
      editingProductId = product['id'].toString();

      titleController.text = product['title']?.toString() ?? '';
      descriptionController.text = product['description']?.toString() ?? '';
      categoryController.text = product['category']?.toString() ?? '';
      priceController.text = product['price']?.toString() ?? '';

      selectedImage = null;
      selectedImageBytes = null;

      message = 'Editing product. Update the details and save.';
    });
  }

  Future<void> selectImage(String productId, String selection) async {
    final imageId = draftImageIds[productId];

    if (imageId == null) {
      throw Exception('Image record not found.');
    }

    await runAction(() async {
      final result = await imageService.selectImage(
        imageId: imageId,
        selection: selection,
      );

      message = result is Map
          ? result['message']?.toString() ?? 'Image selection updated.'
          : 'Image selection updated.';

      await loadDrafts();
    });
  }

  Future<void> runAction(Future<void> Function() action) async {
    setState(() {
      loading = true;
      message = '';
    });

    try {
      await action();
    } catch (e) {
      message = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> generateCatalog() async {
    if (inputController.text.trim().isEmpty) {
      setState(() {
        message = 'Please describe your product first.';
      });
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

      setState(() => generatedDraft = draft);
      message = 'Catalog generated. Review the fields before saving.';
      await speechService.speakCatalogSummary(draft);
    });
  }

  Future<void> pickProductImage() async {
    try {
      final image = await imageService.pickImage();

      if (image == null) return;

      final bytes = await imageService.readImageBytes(image);

      if (!mounted) return;

      setState(() {
        selectedImage = image;
        selectedImageBytes = bytes;
        message = 'Image selected. Save the draft to upload it.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        message = 'Could not select the image: $e';
      });
    }
  }

  Future<void> uploadProductImage(String productId) async {
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

  Future<void> saveDraft() async {
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

      final double? price = priceText.isEmpty
          ? null
          : double.tryParse(priceText);

      if (priceText.isNotEmpty && (price == null || price < 0)) {
        throw Exception('Enter a valid non-negative price.');
      }

      if (editingProductId != null) {
        await catalogService.updateDraft(
          productId: editingProductId!,
          title: title,
          description: description,
          category: category,
          price: price,
        );

        if (!mounted) return;

        setState(() {
          editingProductId = null;

          titleController.clear();
          descriptionController.clear();
          categoryController.text = 'other';
          priceController.clear();

          message = 'Product updated successfully.';
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

        if (!mounted) return;
        setState(() => savedProductId = productId);
      }

      if (selectedImage != null && selectedImageBytes != null) {
        await uploadProductImage(productId);

        if (!mounted) return;

        setState(() {
          savedProductId = null;
          editingProductId = null;

          inputController.clear();
          titleController.clear();
          descriptionController.clear();
          categoryController.text = 'other';
          priceController.clear();

          generatedDraft = null;
          selectedImage = null;
          selectedImageBytes = null;

          message = 'Draft saved and image uploaded successfully.';
        });
      } else {
        if (!mounted) return;

        setState(() {
          savedProductId = null;
          editingProductId = null;

          inputController.clear();
          titleController.clear();
          descriptionController.clear();
          categoryController.text = 'other';
          priceController.clear();

          generatedDraft = null;

          message = 'Draft saved successfully.';
        });
      }

      await loadDrafts();
    });
  }

  Future<void> loadDrafts() async {
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

          final originalUrl = comparisonData['original_url'];
          if (originalUrl != null) {
            urls[productId] = originalUrl.toString();
          }
        }
      } catch (e) {
        debugPrint('Could not load image for product $productId: $e');
      }
    }
    await loadArchivedProducts();

    if (!mounted) return;

    setState(() {
      drafts = result;
      draftImageUrls = urls;
      draftImagePaths = paths;
      draftImageIds = imageIds;
      draftImageComparisons = comparisons;
    });
  }

  Future<void> updatePublication(String productId, bool publish) async {
    await runAction(() async {
      await catalogService.updatePublication(
        productId: productId,
        publish: publish,
      );

      message = publish
          ? 'Product published successfully.'
          : 'Product unpublished successfully.';

      await loadDrafts();
    });
  }

  Future<void> requestImageEnhancement(String storagePath) async {
    await runAction(() async {
      final result = await imageService.requestEnhancement(storagePath);

      if (result is! Map) {
        throw Exception('Unexpected enhancement response.');
      }

      message =
          result['message']?.toString() ?? 'Enhancement request completed.';

      await loadDrafts();
    });
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  Future<void> loadArchivedProducts() async {
    try {
      final response = await catalogService.getArchivedProducts();
      if (!mounted) return;

      setState(() {
        archivedProducts = response;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        message = 'Unable to load archived products: $e';
      });
    }
  }

  Future<void> publishArchivedProduct(String productId) async {
    setState(() {
      loading = true;
      message = '';
    });

    try {
      await catalogService.republishArchivedProduct(productId);

      if (!mounted) return;

      setState(() {
        message = 'Product republished successfully.';
      });

      await loadDrafts();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        message = 'Unable to republish product: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    apiService = ApiService(baseUrl: apiBaseUrl, supabaseClient: supabase);
    catalogService = CatalogService(apiService: apiService);
    imageService = ImageService(
      supabaseClient: supabase,
      apiService: apiService,
    );
    voiceCommandHandler = VoiceCommandHandler(
      commandService: VoiceCommandService(),
    );
    initializeSpeech();
    speechService.initializeTts();
  }

  Future<void> initializeSpeech() async {
    final available = await speechService.initializeSpeech(
      onStatus: (status) {
        if (!mounted) return;

        setState(() {
          isListening = status == 'listening';
        });
      },
      onError: (error) {
        if (!mounted) return;

        setState(() {
          isListening = false;
          speechMessage = error;
        });
      },
    );

    if (!mounted) return;

    setState(() {
      speechAvailable = available;
      speechMessage = available
          ? 'Voice input is ready.'
          : 'Speech recognition is unavailable on this device.';
    });
  }

  Future<void> startListening() async {
    if (!speechAvailable || loading) return;

    setState(() {
      speechMessage = 'Listening...';
      voiceMatchedProductId = null;
      inputController.clear();
    });

    await speechService.startListening(
      onResult: (recognizedWords) {
        if (!mounted) return;

        setState(() {
          inputController.text = recognizedWords;
          inputController.selection = TextSelection.collapsed(
            offset: inputController.text.length,
          );
        });
      },
    );
  }

  Future<void> stopListening() async {
    await speechService.stopListening();

    if (!mounted) return;

    setState(() {
      isListening = false;
      speechMessage = 'Voice input captured. Review the transcription.';
    });

    await handleVoiceCommand();
  }

  Future<void> handleVoiceCommand() async {
    final voiceCommand = voiceCommandHandler.parse(inputController.text);

    if (voiceCommand.type == VoiceCommandType.unknown) return;

    if (voiceCommand.type == VoiceCommandType.listProducts) {
      await runAction(loadDrafts);

      if (!mounted) return;

      final response = drafts.isEmpty
          ? 'You have no products in your catalog yet.'
          : 'You have ${drafts.length} products in your catalog.';

      await speechService.speak(response);
      return;
    }

    if (voiceCommand.type == VoiceCommandType.saveDraft) {
      return;
    }

    if (voiceCommand.type == VoiceCommandType.listArchived) {
      message = 'Loading archived products...';
      setState(() {});

      await runAction(loadArchivedProducts);

      if (!mounted) return;

      final count = archivedProducts.length;
      final response = count == 0
          ? 'You have no archived products.'
          : 'You have $count archived products. They are now displayed on the screen.';

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

    // 3. Refresh products before searching
    await runAction(loadDrafts);

    if (!mounted) return;

    // 4. Match product by name
    final matches = voiceCommandHandler.findMatches(
      productName: productName,
      commandType: voiceCommand.type,
      drafts: drafts,
      archivedProducts: archivedProducts,
    );
    if (matches.isEmpty) {
      message = 'No matching product found.';
      setState(() {});

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

      message =
          'Multiple products match: $names. '
          'Please specify the product more clearly.';

      setState(() {});

      await speechService.speak(
        'I found multiple matching products. '
        'Please specify which product you mean.',
      );
      return;
    }

    final product = matches.first;
    final productId = product['id'].toString();
    final title = product['title']?.toString() ?? 'this product';
    final status = product['status']?.toString();

    // 5. Execute non-modifying commands
    if (action == 'find') {
      setState(() {
        voiceMatchedProductId = productId;
        message = 'Found product: $title';
      });

      await speechService.speak('I found $title.');
      return;
    }

    if (action == 'edit') {
      startEditingProduct(product);

      setState(() {
        voiceMatchedProductId = productId;
        message = 'Loaded $title for editing.';
      });

      await speechService.speak(
        'I have loaded $title. You can now edit its details.',
      );
      return;
    }

    // 6. Validate publication status
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

      message = response;
      setState(() {});
      await speechService.speak(response);
      return;
    }

    // 7. Ask for explicit confirmation
    final publish = action == 'publish' || action == 'republish';

    final confirmed = await VoiceCommandConfirmationDialog.show(
      context: context,
      title: title,
      publish: publish,
    );

    if (!mounted) return;

    if (confirmed != true) {
      message = 'Action cancelled.';
      setState(() {});

      await speechService.speak('Action cancelled.');
      return;
    }

    // 8. Execute confirmed action
    setState(() {
      loading = true;
      message = '';
    });

    try {
      if (action == 'republish') {
        await publishArchivedProduct(productId);
      } else {
        await catalogService.updatePublication(
          productId: productId,
          publish: publish,
        );

        await loadDrafts();
      }

      if (!mounted) return;

      final response = action == 'republish'
          ? '$title has been republished successfully.'
          : publish
          ? '$title has been published successfully.'
          : '$title has been archived successfully.';

      setState(() {
        voiceMatchedProductId = productId;
        message = response;
      });

      await speechService.speak(response);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        message = 'Could not complete the action: $e';
      });

      await speechService.speak('Sorry, the action could not be completed.');
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> shareProduct(Map<String, dynamic> product) async {
    final productId = product['id']?.toString();

    if (productId == null || productId.isEmpty) return;

    if (product['status'] != 'published') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Publish this product before sharing it.'),
        ),
      );
      return;
    }

    final productUrl = Uri.https(
      '20d50b26.marketing-companion.pages.dev',
      '/',
      {'product': productId},
    ).toString();

    final title = product['title']?.toString() ?? 'this product';

    await SharePlus.instance.share(
      ShareParams(text: 'Check out my handmade product: $title\n$productUrl'),
    );
  }

  @override
  void dispose() {
    inputController.dispose();
    titleController.dispose();
    descriptionController.dispose();
    categoryController.dispose();
    priceController.dispose();
    speechService.stopListening();
    speechService.stopSpeaking();
    selectedImageBytes = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catalog prototype'),
        actions: [
          IconButton(
            tooltip: 'My profile',
            onPressed: loading
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  },
            icon: const Icon(Icons.person_outline),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CatalogGenerationSection(
            inputController: inputController,
            loading: loading,
            speechAvailable: speechAvailable,
            isListening: isListening,
            speechMessage: speechMessage,
            onGenerate: generateCatalog,
            onStartListening: startListening,
            onStopListening: stopListening,
          ),
          const Divider(height: 32),

          ProductEditorSection(
            titleController: titleController,
            descriptionController: descriptionController,
            categoryController: categoryController,
            priceController: priceController,
            loading: loading,
            editingProductId: editingProductId,
            savedProductId: savedProductId,
            selectedImageBytes: selectedImageBytes,
            onPickImage: pickProductImage,
            onRemoveImage: () {
              setState(() {
                selectedImage = null;
                selectedImageBytes = null;
              });
            },
            onSave: saveDraft,
            onCancelEditing: () {
              setState(() {
                editingProductId = null;
                titleController.clear();
                descriptionController.clear();
                categoryController.clear();
                priceController.clear();
                message = 'Product editing cancelled.';
              });
            },
          ),
          const Divider(height: 32),
          ProductListSection(
            products: drafts,
            imageUrls: draftImageUrls,
            imagePaths: draftImagePaths,
            imageComparisons: draftImageComparisons,
            voiceMatchedProductId: voiceMatchedProductId,
            loading: loading,
            canEdit: savedProductId == null,
            onLoadProducts: () => runAction(loadDrafts),
            onEdit: startEditingProduct,
            onPublish: (id) => updatePublication(id, true),
            onUnpublish: (id) => updatePublication(id, false),
            onShare: shareProduct,
            onRequestEnhancement: requestImageEnhancement,
            onSelectImage: selectImage,
          ),
          const SizedBox(height: 24),

          ArchivedProductsSection(
            products: archivedProducts,
            loading: loading,
            onRepublish: publishArchivedProduct,
          ),
        ],
      ),
    );
  }
}