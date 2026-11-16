import 'dart:typed_data';
import 'package:marketing_companion_frontend/utils/handle_voice_cmds.dart';
import '../utils/catalog_actions.dart';

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
import '../services/catalog_service.dart';
import '../services/voice_command_handler.dart';
import '../controllers/voice_assistant_controller.dart';
import '../widgets/catalog/voice_assistant_section.dart';

import 'home_screen.dart';

enum CatalogView { home, editor }

class CatalogScreen extends StatefulWidget {
  final VoiceAssistantController voiceAssistantController;

  const CatalogScreen({super.key, required this.voiceAssistantController});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final inputController = TextEditingController();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final categoryController = TextEditingController(text: 'other');
  final priceController = TextEditingController();
  final voiceInputController = TextEditingController(); // Voice commands

  Map<String, String> draftImagePaths = {};

  late final ApiService apiService;
  late final ImageService imageService;
  SpeechService get speechService =>
      widget.voiceAssistantController.speechService;
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

  List<dynamic> archivedProducts = [];

  String? voiceMatchedProductId;

  bool get speechAvailable => widget.voiceAssistantController.speechAvailable;

  bool get isListening => widget.voiceAssistantController.isListening;

  String get speechMessage => widget.voiceAssistantController.speechMessage;

  CatalogView currentView = CatalogView.home;

  void startEditingProduct(Map<String, dynamic> product) {
    setState(() {
      currentView = CatalogView.editor;
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
    await generateCatalogDraft(
      catalogService: catalogService,
      inputController: inputController,
      titleController: titleController,
      descriptionController: descriptionController,
      categoryController: categoryController,
      priceController: priceController,
      runAction: runAction,
      speechService: speechService,
      updateGeneratedDraft: (draft) {
        if (!mounted) return;
        setState(() => generatedDraft = draft);
      },
      updateMessage: (messageText) {
        if (!mounted) return;
        setState(() => message = messageText);
      },
    );
  }

  Future<void> pickProductImage() async {
    await pickCatalogProductImage(
      imageService: imageService,
      updateSelectedImage: (image, bytes, messageText) {
        if (!mounted) return;
        setState(() {
          selectedImage = image;
          selectedImageBytes = bytes;
          message = messageText;
        });
      },
      updateMessage: (messageText) {
        if (!mounted) return;
        setState(() => message = messageText);
      },
    );
  }

  Future<void> uploadProductImage(String productId) async {
    await uploadCatalogProductImage(
      imageService: imageService,
      selectedImage: selectedImage,
      selectedImageBytes: selectedImageBytes,
      productId: productId,
      titleController: titleController,
    );
  }

  Future<void> saveDraft() async {
    await saveCatalogDraft(
      catalogService: catalogService,
      imageService: imageService,
      inputController: inputController,
      titleController: titleController,
      descriptionController: descriptionController,
      categoryController: categoryController,
      priceController: priceController,
      runAction: runAction,
      loadDrafts: loadDrafts,
      updateMessage: (messageText) {
        if (!mounted) return;
        setState(() => message = messageText);
      },
      updateState: (updater) {
        if (!mounted) return;
        setState(updater);
      },
      uploadProductImage: uploadProductImage,
      editingProductId: editingProductId,
      savedProductId: savedProductId,
      selectedImage: selectedImage,
      selectedImageBytes: selectedImageBytes,
      generatedDraft: generatedDraft,
      setSavedProductId: (value) => savedProductId = value,
      setEditingProductId: (value) => editingProductId = value,
      setSelectedImage: (value) => selectedImage = value,
      setSelectedImageBytes: (value) => selectedImageBytes = value,
      setGeneratedDraft: (value) => generatedDraft = value,
    );
  }

  Future<void> loadDrafts() async {
    await loadCatalogDrafts(
      catalogService: catalogService,
      imageService: imageService,
      loadArchivedProducts: loadArchivedProducts,
      updateCatalogState:
          ({
            required List<dynamic> drafts,
            required Map<String, String> draftImageUrls,
            required Map<String, String> draftImagePaths,
            required Map<String, String> draftImageIds,
            required Map<String, Map<String, dynamic>> draftImageComparisons,
          }) {
            if (!mounted) return;
            setState(() {
              this.drafts = drafts;
              this.draftImageUrls = draftImageUrls;
              this.draftImagePaths = draftImagePaths;
              this.draftImageIds = draftImageIds;
              this.draftImageComparisons = draftImageComparisons;
            });
          },
    );
  }

  Future<void> updatePublication(String productId, bool publish) async {
    await updateCatalogPublication(
      catalogService: catalogService,
      runAction: runAction,
      loadDrafts: loadDrafts,
      updateMessage: (messageText) {
        if (!mounted) return;
        setState(() => message = messageText);
      },
      productId: productId,
      publish: publish,
    );
  }

  Future<void> requestImageEnhancement(String storagePath) async {
    await requestCatalogImageEnhancement(
      imageService: imageService,
      runAction: runAction,
      loadDrafts: loadDrafts,
      updateMessage: (messageText) {
        if (!mounted) return;
        setState(() => message = messageText);
      },
      storagePath: storagePath,
    );
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  Future<void> loadArchivedProducts() async {
    await loadArchivedCatalogProducts(
      catalogService: catalogService,
      updateArchivedProducts: (response) {
        if (!mounted) return;
        setState(() => archivedProducts = response);
      },
      updateMessage: (messageText) {
        if (!mounted) return;
        setState(() => message = messageText);
      },
    );
  }

  Future<void> publishArchivedProduct(String productId) async {
    await republishArchivedCatalogProduct(
      catalogService: catalogService,
      loadDrafts: loadDrafts,
      updateLoadingState: (loadingState, messageText) {
        if (!mounted) return;
        setState(() {
          loading = loadingState;
          message = messageText;
        });
      },
      updateMessage: (messageText) {
        if (!mounted) return;
        setState(() => message = messageText);
      },
      productId: productId,
    );
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
    widget.voiceAssistantController.addListener(_handleVoiceAssistantChanged);

    widget.voiceAssistantController.initialize();

    loadDrafts();
  }

  void _handleVoiceAssistantChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> startListening() async {
    await manageVoiceListening(
      speechAvailable: speechAvailable,
      loading: loading,
      isListening: isListening,
      voiceInputController: voiceInputController,
      startListening:
          ({required void Function(String recognizedWords) onResult}) => widget
              .voiceAssistantController
              .startListening(onResult: onResult),
      stopListening: () => widget.voiceAssistantController.stopListening(),
      onStop: handleVoiceCommand,
      updateState: (fn) {
        if (!mounted) return;
        setState(fn);
      },
    );
  }

  Future<void> stopListening() async {
    await stopVoiceListening(
      stopListening: () => widget.voiceAssistantController.stopListening(),
      onSubmit: handleVoiceCommand,
    );
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

  void openAddProduct() {
    applyCatalogNavigation(
      isEditing: false,
      editingProductId: editingProductId,
      savedProductId: savedProductId,
      generatedDraft: generatedDraft,
      inputController: inputController,
      titleController: titleController,
      descriptionController: descriptionController,
      categoryController: categoryController,
      priceController: priceController,
      updateView: (isEditorMode) {
        if (!mounted) return;
        setState(
          () => currentView = isEditorMode
              ? CatalogView.editor
              : CatalogView.home,
        );
      },
      setEditingProductId: (value) => editingProductId = value,
      setSavedProductId: (value) => savedProductId = value,
      setGeneratedDraft: (value) => generatedDraft = value,
      setSelectedImage: (value) => selectedImage = value,
      setSelectedImageBytes: (value) => selectedImageBytes = value,
      updateMessage: (messageText) {
        if (!mounted) return;
        setState(() => message = messageText);
      },
      messageText: '',
    );
  }

  void openProductEditor(Map<String, dynamic> product) {
    startEditingProduct(product);

    applyCatalogNavigation(
      isEditing: true,
      editingProductId: editingProductId,
      savedProductId: savedProductId,
      generatedDraft: generatedDraft,
      inputController: inputController,
      titleController: titleController,
      descriptionController: descriptionController,
      categoryController: categoryController,
      priceController: priceController,
      updateView: (isEditorMode) {
        if (!mounted) return;
        setState(
          () => currentView = isEditorMode
              ? CatalogView.editor
              : CatalogView.home,
        );
      },
      setEditingProductId: (value) => editingProductId = value,
      setSavedProductId: (value) => savedProductId = value,
      setGeneratedDraft: (value) => generatedDraft = value,
      setSelectedImage: (value) => selectedImage = value,
      setSelectedImageBytes: (value) => selectedImageBytes = value,
      updateMessage: (messageText) {
        if (!mounted) return;
        setState(() => message = messageText);
      },
      messageText: 'Editing product. Update the details and save.',
    );
  }

  void returnHome() {
    returnCatalogHome(
      updateHomeView: () {
        if (!mounted) return;
        setState(() {
          currentView = CatalogView.home;
        });
      },
      updateMessage: (messageText) {
        if (!mounted) return;
        setState(() => message = messageText);
      },
    );
  }

  Future<void> startCatalogListening() async {
    if (!speechAvailable || loading || isListening) return;

    inputController.clear();

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

  Future<void> stopCatalogListening() async {
    await speechService.stopListening();
  }

  Future<void> handleVoiceCommand() async {
    await processVoiceCommand(
      context: context,
      voiceInputController: voiceInputController,
      voiceCommandHandler: voiceCommandHandler,
      speechService: speechService,
      runAction: runAction,
      loadDrafts: loadDrafts,
      saveDraft: saveDraft,
      startEditingProduct: (product) async => startEditingProduct(product),
      updatePublication: updatePublication,
      publishArchivedProduct: publishArchivedProduct,
      mounted: mounted,
      isEditorMode: currentView == CatalogView.editor,
      drafts: drafts,
      archivedProducts: archivedProducts,
      updateMessage: (messageText) {
        if (!mounted) return;
        setState(() => message = messageText);
      },
      updateVoiceMatchedProductId: (productId) {
        if (!mounted) return;
        setState(() => voiceMatchedProductId = productId);
      },
      goHome: () {
        if (!mounted) return;
        setState(() {
          currentView = CatalogView.home;
          message = '';
        });
      },
    );
  }

  @override
  void dispose() {
    inputController.dispose();
    titleController.dispose();
    descriptionController.dispose();
    categoryController.dispose();
    priceController.dispose();
    widget.voiceAssistantController.removeListener(
      _handleVoiceAssistantChanged,
    );
    selectedImageBytes = null;
    voiceInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (currentView == CatalogView.home) {
      return HomeScreen(
        products: drafts,
        imageUrls: draftImageUrls,
        loading: loading,
        message: message,
        voiceInputController: voiceInputController,
        speechAvailable: speechAvailable,
        isListening: isListening,
        speechMessage: speechMessage,
        onStartListening: startListening,
        onStopListening: stopListening,
        onVoiceCommand: handleVoiceCommand,
        onRefresh: () => runAction(loadDrafts),
        onProductTap: openProductEditor,
        onAddProduct: openAddProduct,
        onProfile: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          );
        },
        onSignOut: signOut,
        archivedProducts: archivedProducts,
        onRepublishArchived: publishArchivedProduct,
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to products',
          icon: const Icon(Icons.arrow_back),
          onPressed: returnHome,
        ),
        title: Text(editingProductId == null ? 'Add Product' : 'Edit Product'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (editingProductId == null) ...[
            CatalogGenerationSection(
              inputController: inputController,
              loading: loading,
              speechAvailable: speechAvailable,
              isListening: isListening,
              speechMessage: speechMessage,
              onGenerate: generateCatalog,
              onStartListening: startCatalogListening,
              onStopListening: stopCatalogListening,
            ),
            const Divider(height: 32),
          ],

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
                savedProductId = null;
                generatedDraft = null;

                titleController.clear();
                descriptionController.clear();
                categoryController.text = 'other';
                priceController.clear();
                inputController.clear();

                selectedImage = null;
                selectedImageBytes = null;

                message = 'Product editing cancelled.';
                currentView = CatalogView.home;
              });
            },
          ),

          const Divider(height: 32),

          if (message.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ],
        ],
      ),
      bottomNavigationBar: VoiceAssistantSection(
        controller: voiceInputController,
        loading: loading,
        speechAvailable: speechAvailable,
        isListening: isListening,
        speechMessage: speechMessage,
        onStartListening: startListening,
        onStopListening: stopListening,
        onSubmit: handleVoiceCommand,
      ),
    );
  }
}
