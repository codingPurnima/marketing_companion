import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import 'profile_screen.dart';

import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

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
  final ImagePicker imagePicker = ImagePicker();

  Map<String, String> draftImagePaths = {};

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

  final SpeechToText speech = SpeechToText();

  bool speechAvailable = false;
  bool isListening = false;
  String speechMessage = '';
  final FlutterTts flutterTts = FlutterTts();

  List<dynamic> archivedProducts = [];

  String? voiceMatchedProductId;

  Future<void> initializeTextToSpeech() async {
    try {
      await flutterTts.setLanguage('en-IN');
      await flutterTts.setSpeechRate(0.45);
      await flutterTts.setPitch(1.0);
      await flutterTts.awaitSpeakCompletion(true);

      debugPrint('TTS initialized successfully');
    } catch (e) {
      debugPrint('TTS initialization error: $e');
    }
  }

  Map<String, String> get authHeaders {
    final token = supabase.auth.currentSession?.accessToken;

    if (token == null) {
      throw Exception('Your session has expired. Please sign in again.');
    }

    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<dynamic> apiRequest(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$apiBaseUrl$path');

    final response = switch (method.toUpperCase()) {
      'POST' => await http.post(
        uri,
        headers: authHeaders,
        body: jsonEncode(body),
      ),
      'PUT' => await http.put(
        uri,
        headers: authHeaders,
        body: jsonEncode(body),
      ),
      'PATCH' => await http.patch(
        uri,
        headers: authHeaders,
        body: jsonEncode(body),
      ),
      _ => await http.get(uri, headers: authHeaders),
    };

    final data = response.body.isEmpty ? null : jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = data is Map ? data['detail'] : null;
      throw Exception(detail ?? 'Request failed (${response.statusCode}).');
    }

    return data;
  }

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
      final result = await apiRequest(
        '/api/v1/images/$imageId/selection',
        method: 'PATCH',
        body: {'selection': selection},
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
      final result = await apiRequest(
        '/api/v1/catalog/generate',
        method: 'POST',
        body: {'product_text': inputController.text.trim()},
      );

      final draft = Map<String, dynamic>.from(result as Map);

      titleController.text = draft['title']?.toString() ?? '';
      descriptionController.text = draft['description']?.toString() ?? '';
      categoryController.text = draft['category']?.toString() ?? 'other';
      priceController.text = draft['price_inr']?.toString() ?? '';

      setState(() => generatedDraft = draft);
      message = 'Catalog generated. Review the fields before saving.';
      await speakGeneratedCatalog(draft);
    });
  }

  Future<void> pickProductImage() async {
    try {
      final image = await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 2000,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();

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
    final userId = supabase.auth.currentUser?.id;

    if (image == null || bytes == null) {
      throw Exception('Please select a product image first.');
    }

    if (userId == null) {
      throw Exception('Please sign in again.');
    }

    final originalExtension = image.name.split('.').last.toLowerCase();

    final extension = switch (originalExtension) {
      'png' => 'png',
      'webp' => 'webp',
      'jpeg' => 'jpeg',
      'jpg' => 'jpg',
      _ => 'jpg',
    };

    final contentType = switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };

    final storagePath =
        '$userId/$productId/${DateTime.now().millisecondsSinceEpoch}.$extension';

    final storage = supabase.storage.from('product-images');

    await storage.uploadBinary(
      storagePath,
      bytes,
      fileOptions: FileOptions(contentType: contentType, upsert: false),
    );

    try {
      await supabase.from('product_images').insert({
        'product_id': productId,
        'storage_path': storagePath,
        'alt_text': titleController.text.trim(),
        'sort_order': 0,
      });
    } catch (_) {
      try {
        await storage.remove([storagePath]);
      } catch (_) {}

      rethrow;
    }
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
        await apiRequest(
          '/api/v1/catalog/$editingProductId',
          method: 'PATCH',
          body: {
            'title': title,
            'description': description,
            'category': category,
            'materials': [],
            'tags': [],
            'price_inr': price,
          },
        );

        if (!mounted) return;

        setState(() {
          editingProductId = null;

          titleController.clear();
          descriptionController.clear();
          categoryController.clear();
          priceController.clear();

          message = 'Product updated successfully.';
        });

        await loadDrafts();
        return;
      }

      var productId = savedProductId;

      if (productId == null) {
        final result = await apiRequest(
          '/api/v1/catalog/drafts',
          method: 'POST',
          body: {
            'title': title,
            'description': description,
            'category': category,
            'materials': generatedDraft?['materials'] ?? [],
            'tags': generatedDraft?['tags'] ?? [],
            'price_inr': price,
          },
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
    final result = await apiRequest('/api/v1/catalog/drafts');

    if (result is! List) {
      throw Exception('Unexpected response while loading drafts.');
    }

    final urls = <String, String>{};
    final paths = <String, String>{};
    final imageIds = <String, String>{};
    final comparisons = <String, Map<String, dynamic>>{};

    for (final item in result) {
      if (item is! Map || item['id'] == null) continue;

      final productId = item['id'].toString();

      try {
        final imageRows = await supabase
            .from('product_images')
            .select('id, storage_path')
            .eq('product_id', item['id'])
            .order('sort_order');

        if (imageRows.isEmpty) continue;

        final image = imageRows.first;
        final imageId = image['id'].toString();
        final path = image['storage_path'].toString();

        imageIds[productId] = imageId;
        paths[productId] = path;

        final comparison = await apiRequest(
          '/api/v1/images/$imageId/comparison',
        );

        if (comparison is Map) {
          final comparisonData = Map<String, dynamic>.from(comparison);
          comparisons[productId] = comparisonData;

          final originalUrl = comparisonData['original_url'];
          if (originalUrl != null) {
            urls[productId] = originalUrl.toString();
          }
        }
        await loadArchivedProducts();
      } catch (e) {
        debugPrint('Could not load image for product $productId: $e');
      }
    }

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
      await apiRequest(
        '/api/v1/catalog/$productId/${publish ? 'publish' : 'unpublish'}',
        method: 'PATCH',
      );

      message = publish
          ? 'Product published successfully.'
          : 'Product unpublished successfully.';

      await loadDrafts();
    });
  }

  Future<void> requestImageEnhancement(String storagePath) async {
    await runAction(() async {
      final result = await apiRequest(
        '/api/v1/images/enhance',
        method: 'POST',
        body: {'original_storage_path': storagePath},
      );

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
      final response = await apiRequest('/api/v1/catalog/archived');

      if (!mounted) return;

      setState(() {
        archivedProducts = response as List<dynamic>;
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
      await apiRequest('/api/v1/catalog/$productId/publish', method: 'PATCH');

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
    initializeSpeech();
    initializeTextToSpeech();
  }

  Future<void> initializeSpeech() async {
    try {
      final available = await speech.initialize(
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
            speechMessage = error.errorMsg;
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
    } catch (e) {
      if (!mounted) return;

      setState(() {
        speechAvailable = false;
        speechMessage = 'Could not initialize speech recognition.';
      });
    }
  }

  Future<void> startListening() async {
    if (!speechAvailable || loading) return;

    setState(() {
      speechMessage = 'Listening...';
      voiceMatchedProductId = null;
inputController.clear();
    });

    await speech.listen(
      onResult: (result) {
        if (!mounted) return;

        setState(() {
          inputController.text = result.recognizedWords;
          inputController.selection = TextSelection.collapsed(
            offset: inputController.text.length,
          );
        });
      },
      listenFor: const Duration(minutes: 1),
      pauseFor: const Duration(seconds: 5),
      partialResults: true,
    );
  }

  Future<void> stopListening() async {
    await speech.stop();

    if (!mounted) return;

    setState(() {
      isListening = false;
      speechMessage = 'Voice input captured. Review the transcription.';
    });

    await handleVoiceCommand();
  }

  Future<void> speakGeneratedCatalog(Map<String, dynamic> draft) async {
    final title = draft['title']?.toString() ?? '';
    final description = draft['description']?.toString() ?? '';
    final category = draft['category']?.toString() ?? 'other';
    final price = draft['price_inr']?.toString();

    final summary =
        '''
    Your catalog draft is ready.
    Product title: $title.
    Category: $category.
    ${price != null && price.isNotEmpty ? 'Price: $price rupees.' : 'No price was provided.'}
    Description: $description.
    Please review these details before saving.
  ''';

    try {
      debugPrint('TTS: Starting speech');
      final result = await flutterTts.speak(summary);
      debugPrint('TTS speak result: $result');
    } catch (e) {
      debugPrint('TTS playback error: $e');
    }
  }

String normalizeVoiceText(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String? extractProductName(
  String command,
  List<String> prefixes,
) {
  for (final prefix in prefixes) {
    if (command.startsWith('$prefix ')) {
      return command.substring(prefix.length).trim();
    }
  }

  return null;
}

List<Map<String, dynamic>> findMatchingProducts(
  String query, {
  required List<dynamic> source,
}) {
  final normalizedQuery = normalizeVoiceText(query);
  final queryWords = normalizedQuery.split(' ').toSet();
  final matches = <Map<String, dynamic>>[];

  for (final item in source) {
    final product = Map<String, dynamic>.from(item as Map);
    final title = normalizeVoiceText(
      product['title']?.toString() ?? '',
    );

    if (title.isEmpty) continue;

    final titleWords = title.split(' ').toSet();

    double score = 0;

    if (title == normalizedQuery) {
      score = 2;
    } else if (title.contains(normalizedQuery) ||
        normalizedQuery.contains(title)) {
      score = 1.5;
    } else {
      final commonWords = queryWords.intersection(titleWords);
      score = commonWords.length / queryWords.length;
    }

    if (score >= 0.6) {
      product['_matchScore'] = score;
      matches.add(product);
    }
  }

  matches.sort(
    (a, b) => (b['_matchScore'] as double)
        .compareTo(a['_matchScore'] as double),
  );

  return matches;
}

Future<void> handleVoiceCommand() async {
  final command = normalizeVoiceText(inputController.text);

  if (command.isEmpty) return;

  // 1. List products
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
    await runAction(loadDrafts);

    if (!mounted) return;

    final response = drafts.isEmpty
        ? 'You have no products in your catalog yet.'
        : 'You have ${drafts.length} products in your catalog.';

    await flutterTts.speak(response);
    return;
  }

  // Save draft command
const saveDraftCommands = {
  'save this draft',
  'save draft',
  'save my draft',
  'save product as draft',
  'save this product as draft',
};

if (saveDraftCommands.contains(command)) {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Save draft?'),
      content: Text(
        editingProductId != null
            ? 'Save the changes to this product?'
            : 'Save this product as a draft?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Save'),
        ),
      ],
    ),
  );

  if (!mounted) return;

  if (confirmed != true) {
    message = 'Draft saving cancelled.';
    setState(() {});
    await flutterTts.speak('Draft saving cancelled.');
    return;
  }

  await runAction(saveDraft);

  if (!mounted) return;

  await flutterTts.speak(message);
  return;
}

// Load archived products command
const archivedProductCommands = {
  'show archived products',
  'show my archived products',
  'load archived products',
  'load my archived products',
  'show archived items',
  'load archived items',
};

if (archivedProductCommands.contains(command)) {
  message = 'Loading archived products...';
  setState(() {});

  await runAction(loadArchivedProducts);

  if (!mounted) return;

  final count = archivedProducts.length;

  final response = count == 0
      ? 'You have no archived products.'
      : 'You have $count archived products. '
          'They are now displayed on the screen.';

  await flutterTts.speak(response);
  return;
}

  // 2. Identify command and extract product name
  String? productName;
  String? action;

  productName = extractProductName(command, [
    'find my product',
    'find the product',
    'find product',
    'find my',
    'find',
  ]);

  if (productName != null) {
    action = 'find';
  }

  productName ??= extractProductName(command, [
    'edit my product',
    'edit the product',
    'edit product',
    'edit my',
    'edit',
  ]);

  if (action == null && productName != null) {
    action = 'edit';
  }

  productName ??= extractProductName(command, [
  'republish archived product',
  'republish my archived product',
  'republish the archived product',
  'republish archived',
  'republish product',
  'republish my',
  'republish',
]);

if (action == null && productName != null) {
  action = 'republish';
}

  productName ??= extractProductName(command, [
    'publish my draft',
    'publish the draft',
    'publish draft',
    'publish my product',
    'publish the product',
    'publish product',
    'publish my',
    'publish',
  ]);

  if (action == null && productName != null) {
    action = 'publish';
  }

  productName ??= extractProductName(command, [
    'archive my product',
    'archive the product',
    'archive product',
    'archive my',
    'archive',
  ]);

  if (action == null && productName != null) {
    action = 'archive';
  }

  productName ??= extractProductName(command, [
    'unpublish my product',
    'unpublish the product',
    'unpublish product',
    'unpublish my',
    'unpublish',
  ]);

  if (action == null && productName != null) {
    action = 'archive';
  }

  if (action == null || productName == null || productName.isEmpty) {
    return;
  }

  // 3. Refresh products before searching
  await runAction(loadDrafts);
  await runAction(loadArchivedProducts);


  if (!mounted) return;

  // 4. Match product by name
  final sourceProducts = action == 'republish'
    ? archivedProducts
    : action == 'find'
        ? [...drafts, ...archivedProducts]
        : drafts;

final matches = findMatchingProducts(
  productName,
  source: sourceProducts,
);

  if (matches.isEmpty) {
    message = 'No matching product found.';
    setState(() {});

    await flutterTts.speak(
      'I could not find a product matching $productName.',
    );
    return;
  }

  if (matches.length > 1 &&
      (matches[0]['_matchScore'] as double) -
              (matches[1]['_matchScore'] as double) <
          0.15) {
    final names = matches
        .take(3)
        .map((product) => product['title'].toString())
        .join(', ');

    message = 'Multiple products match: $names. '
        'Please specify the product more clearly.';

    setState(() {});

    await flutterTts.speak(
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

    await flutterTts.speak('I found $title.');
    return;
  }

  if (action == 'edit') {
    startEditingProduct(product);

    setState(() {
      voiceMatchedProductId = productId;
      message = 'Loaded $title for editing.';
    });

    await flutterTts.speak(
      'I have loaded $title. You can now edit its details.',
    );
    return;
  }

  // 6. Validate publication status
  if (action == 'publish' && status != 'draft') {
    await flutterTts.speak(
      '$title is not a draft. Only drafts can be published.',
    );

    setState(() {
      message = '$title is not a draft.';
    });
    return;
  }

  if (action == 'archive' && status != 'published') {
    await flutterTts.speak(
      '$title is not currently published.',
    );

    setState(() {
      message = '$title is not currently published.';
    });
    return;
  }

  if (action == 'republish' && status != 'archived') {
  message = '$title is not archived.';
  setState(() {});
  await flutterTts.speak('$title is not archived.');
  return;
}

  // 7. Ask for explicit confirmation
  final publish = action == 'publish' || action == 'republish';

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(publish ? 'Publish product?' : 'Archive product?'),
      content: Text(
        publish
            ? 'Do you want to publish "$title"?'
            : 'Do you want to archive "$title"? '
                'It will no longer appear on the customer website.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(publish ? 'Publish' : 'Archive'),
        ),
      ],
    ),
  );

  if (!mounted) return;

  if (confirmed != true) {
    message = 'Action cancelled.';
    setState(() {});

    await flutterTts.speak('Action cancelled.');
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
    await loadArchivedProducts();
  } else {
    await apiRequest(
      '/api/v1/catalog/$productId/${publish ? 'publish' : 'unpublish'}',
      method: 'PATCH',
    );

    await loadDrafts();
    await loadArchivedProducts();
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

  await flutterTts.speak(response);
} catch (e) {
    if (!mounted) return;

    setState(() {
      message = 'Could not complete the action: $e';
    });

    await flutterTts.speak('Sorry, the action could not be completed.');
  } finally {
    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }
}

  @override
  void dispose() {
    inputController.dispose();
    titleController.dispose();
    descriptionController.dispose();
    categoryController.dispose();
    priceController.dispose();
    selectedImageBytes = null;
    speech.stop();
    flutterTts.stop();
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
                    ? stopListening
                    : startListening,
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
            onPressed: loading
                ? null
                : inputController.text.trim().isEmpty
                ? null
                : generateCatalog,
            child: const Text('Generate Catalog'),
          ),
          const Divider(height: 32),
          Text(
            editingProductId != null
                ? '2. Edit product'
                : '2. Review and edit draft',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          TextField(
            controller: titleController,
            decoration: const InputDecoration(labelText: 'Product title'),
          ),
          TextField(
            controller: descriptionController,
            minLines: 2,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          TextField(
            controller: categoryController,
            decoration: const InputDecoration(
              labelText: 'Category (use a supported value)',
            ),
          ),
          TextField(
            controller: priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Price in INR (optional)',
            ),
          ),

          const SizedBox(height: 16),

          OutlinedButton.icon(
            onPressed: loading ? null : pickProductImage,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text(
              selectedImage == null
                  ? 'Choose product image'
                  : 'Change product image',
            ),
          ),

          if (selectedImageBytes != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                selectedImageBytes!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.contain,
              ),
            ),
            TextButton.icon(
              onPressed: loading
                  ? null
                  : () {
                      setState(() {
                        selectedImage = null;
                        selectedImageBytes = null;
                      });
                    },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Remove selected image'),
            ),
          ],

          const SizedBox(height: 8),
          FilledButton(
            onPressed: loading ? null : saveDraft,
            child: Text(
              editingProductId != null
                  ? 'Update product'
                  : savedProductId != null
                  ? 'Retry image upload'
                  : 'Save as draft',
            ),
          ),

          if (editingProductId != null)
            TextButton(
              onPressed: loading
                  ? null
                  : () {
                      setState(() {
                        editingProductId = null;

                        titleController.clear();
                        descriptionController.clear();
                        categoryController.clear();
                        priceController.clear();

                        message = 'Product editing cancelled.';
                      });
                    },
              child: const Text('Cancel editing'),
            ),
          const Divider(height: 32),
          Text(
            '3. Your products',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          OutlinedButton(
            onPressed: loading ? null : () => runAction(loadDrafts),
            child: const Text('Load drafts'),
          ),
          if (loading) const Center(child: CircularProgressIndicator()),
          if (message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: SelectableText(message),
            ),
          if (drafts.isEmpty)
            const Text('No products loaded yet.')
          else
            ...drafts.map((item) {
              final draft = Map<String, dynamic>.from(item as Map);
              final productId = draft['id']?.toString();
              final imageUrl = productId == null
                  ? null
                  : draftImageUrls[productId];

              final comparison = productId == null
                  ? null
                  : draftImageComparisons[productId];

              final enhancedUrl = comparison?['enhanced_url']?.toString();
              final enhancementStatus =
                  comparison?['enhancement_status']?.toString() ??
                  'not_requested';
              debugPrint(
                'Product: $productId | Image path: ${draftImagePaths[productId]}',
              );
              return Card(
  clipBehavior: Clip.antiAlias,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    side: BorderSide(
      color: productId == voiceMatchedProductId
          ? Theme.of(context).colorScheme.primary
          : Colors.transparent,
      width: 2,
    ),
  ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (imageUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const SizedBox(
                                  height: 80,
                                  child: Center(
                                    child: Text('Image preview unavailable'),
                                  ),
                                ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        draft['title']?.toString() ?? 'Untitled',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${draft['category']} · '
                        '₹${draft['price'] ?? 'Not set'} · '
                        '${draft['status']}',
                      ),
                      if (productId != null) ...[
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: loading || savedProductId != null
                              ? null
                              : () => startEditingProduct(
                                  Map<String, dynamic>.from(draft),
                                ),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Edit product'),
                        ),
                        if (draft['status'] == 'draft')
                          FilledButton.tonalIcon(
                            onPressed: loading
                                ? null
                                : () => updatePublication(productId, true),
                            icon: const Icon(Icons.publish),
                            label: const Text('Publish product'),
                          )
                        else if (draft['status'] == 'published')
                          OutlinedButton.icon(
                            onPressed: loading
                                ? null
                                : () => updatePublication(productId, false),
                            icon: const Icon(Icons.unpublished_outlined),
                            label: const Text('Unpublish product'),
                          ),
                      ],
                      if (imageUrl == null) const Text('No image attached'),
                      if (enhancedUrl != null) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Enhanced image',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            enhancedUrl,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const SizedBox(
                                  height: 80,
                                  child: Center(
                                    child: Text(
                                      'Enhanced image preview unavailable',
                                    ),
                                  ),
                                ),
                          ),
                        ),
                      ],

                      if (enhancementStatus == 'processing')
                        const Text('Image enhancement is processing.'),

                      if (enhancementStatus == 'failed')
                        const Text(
                          'Image enhancement failed. You can try again.',
                        ),

                      if (enhancementStatus == 'completed' &&
                          enhancedUrl == null)
                        const Text(
                          'Enhanced image is ready, but its preview could not be loaded.',
                        ),

                      if (enhancedUrl != null && productId != null) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Choose the image for your catalogue:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: loading
                                    ? null
                                    : () => selectImage(productId, 'original'),
                                child: const Text('Use original'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: loading
                                    ? null
                                    : () => selectImage(productId, 'enhanced'),
                                child: const Text('Use enhanced'),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (imageUrl != null && productId != null) ...[
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed:
                              loading || draftImagePaths[productId] == null
                              ? null
                              : () => requestImageEnhancement(
                                  draftImagePaths[productId]!,
                                ),
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('Test image enhancement'),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 24),

          const Text(
            'Archived',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          if (archivedProducts.isEmpty)
            const Text('No archived products yet.')
          else
            ...archivedProducts.map((product) {
              return Card(
                child: ListTile(
                  title: Text(product['title'] ?? ''),
                  subtitle: Text(
                    '${product['category'] ?? 'other'} • ₹${product['price'] ?? 0}',
                  ),
                  trailing: ElevatedButton(
                    onPressed: loading
                        ? null
                        : () => publishArchivedProduct(product['id']),
                    child: const Text('Republish'),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}