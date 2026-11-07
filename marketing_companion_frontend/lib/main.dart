import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
const apiBaseUrl = String.fromEnvironment('API_BASE_URL');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (supabaseUrl.isEmpty || supabaseKey.isEmpty || apiBaseUrl.isEmpty) {
    throw StateError(
      'Set SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY and API_BASE_URL.',
    );
  }

  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseKey);

  runApp(const ArtisanApp());
}

final supabase = Supabase.instance.client;

class ArtisanApp extends StatelessWidget {
  const ArtisanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Artisan Catalog Prototype',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: StreamBuilder<AuthState>(
        stream: supabase.auth.onAuthStateChange,
        builder: (context, snapshot) {
          if (supabase.auth.currentSession == null) {
            return const LoginScreen();
          }
          return const CatalogScreen();
        },
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isSignUp = false;
  bool loading = false;
  String message = '';

  Future<void> authenticate() async {
    setState(() {
      loading = true;
      message = '';
    });

    try {
      final email = emailController.text.trim();
      final password = passwordController.text;

      if (isSignUp) {
        final response = await supabase.auth.signUp(
          email: email,
          password: password,
        );

        if (response.session == null) {
          message = 'Account created. Check your email to confirm it.';
        }
      } else {
        await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
      }
    } catch (e) {
      message = e is AuthException ? e.message : 'Authentication failed.';
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Artisan Catalog')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            isSignUp ? 'Create account' : 'Sign in',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: loading ? null : authenticate,
            child: Text(
              loading
                  ? 'Please wait...'
                  : isSignUp
                  ? 'Create account'
                  : 'Sign in',
            ),
          ),
          TextButton(
            onPressed: () => setState(() {
              isSignUp = !isSignUp;
              message = '';
            }),
            child: Text(
              isSignUp
                  ? 'Already registered? Sign in'
                  : 'New artisan? Create an account',
            ),
          ),
          if (message.isNotEmpty) SelectableText(message),
        ],
      ),
    );
  }
}

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

  List<dynamic> archivedProducts = [];

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

      // Product editing does not change its images.
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

    // Step 1: Upload the image.
    await storage.uploadBinary(
      storagePath,
      bytes,
      fileOptions: FileOptions(contentType: contentType, upsert: false),
    );

    try {
      // Step 2: Link the image to its saved product.
      await supabase.from('product_images').insert({
        'product_id': productId,
        'storage_path': storagePath,
        'alt_text': titleController.text.trim(),
        'sort_order': 0,
      });
    } catch (_) {
      // Avoid leaving an orphaned storage object if linking fails.
      try {
        await storage.remove([storagePath]);
      } catch (_) {
        // Preserve the original database error.
      }

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

      // Update an existing product.
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

      // Reuse the existing product ID when retrying a failed image upload.
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

        // The backend must return the inserted product row.
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

      // If no image was selected, save only the draft.
      if (selectedImage != null && selectedImageBytes != null) {
        await uploadProductImage(productId);

        if (!mounted) return;

        setState(() {
          selectedImage = null;
          selectedImageBytes = null;
          savedProductId = null;
          message = 'Draft saved and image uploaded successfully.';
        });
      } else {
        if (!mounted) return;

        setState(() {
          savedProductId = null;
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
  void dispose() {
    inputController.dispose();
    titleController.dispose();
    descriptionController.dispose();
    categoryController.dispose();
    priceController.dispose();
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
          Text(
            '1. Generate catalog',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          TextField(
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
          const SizedBox(height: 8),
          FilledButton(
            onPressed: loading ? null : generateCatalog,
            child: const Text('Generate with Gemini'),
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

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final publicNameController = TextEditingController();
  final bioController = TextEditingController();
  final craftController = TextEditingController();
  final districtController = TextEditingController();
  final stateController = TextEditingController();
  final whatsappController = TextEditingController();

  bool loading = true;
  bool saving = false;
  String message = '';

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

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  @override
  void dispose() {
    publicNameController.dispose();
    bioController.dispose();
    craftController.dispose();
    districtController.dispose();
    stateController.dispose();
    whatsappController.dispose();
    super.dispose();
  }

  Future<void> loadProfile() async {
    setState(() {
      loading = true;
      message = '';
    });

    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/v1/profile/me'),
        headers: authHeaders,
      );

      final data = response.body.isEmpty ? null : jsonDecode(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final detail = data is Map ? data['detail'] : null;
        throw Exception(detail ?? 'Unable to load profile.');
      }

      if (data is Map) {
        publicNameController.text = data['public_name']?.toString() ?? '';
        bioController.text = data['bio']?.toString() ?? '';
        craftController.text = data['craft']?.toString() ?? '';
        districtController.text = data['district']?.toString() ?? '';
        stateController.text = data['state']?.toString() ?? '';
        whatsappController.text = data['whatsapp_number']?.toString() ?? '';
      }

      if (!mounted) return;

      setState(() {
        message = data == null
            ? 'Create your public artisan profile.'
            : 'Your profile is loaded.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        message = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      saving = true;
      message = '';
    });

    try {
      final response = await http.put(
        Uri.parse('$apiBaseUrl/api/v1/profile/me'),
        headers: authHeaders,
        body: jsonEncode({
          'public_name': publicNameController.text.trim(),
          'bio': bioController.text.trim(),
          'craft': craftController.text.trim(),
          'district': districtController.text.trim(),
          'state': stateController.text.trim(),
          'whatsapp_number': whatsappController.text.trim(),
        }),
      );

      final data = response.body.isEmpty ? null : jsonDecode(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final detail = data is Map ? data['detail'] : null;
        throw Exception(detail ?? 'Unable to save profile.');
      }

      if (!mounted) return;

      setState(() {
        message = 'Profile saved successfully.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        message = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    int minLines = 1,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return '$label is required.';
              }
              return null;
            }
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My artisan profile')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Public profile details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'These details help customers discover and contact you.',
                    ),
                    const SizedBox(height: 20),

                    _buildField(
                      label: 'Public name',
                      controller: publicNameController,
                      required: true,
                    ),
                    const SizedBox(height: 16),

                    _buildField(
                      label: 'Bio',
                      controller: bioController,
                      minLines: 3,
                      maxLines: 5,
                    ),
                    const SizedBox(height: 16),

                    _buildField(
                      label: 'Craft',
                      controller: craftController,
                      required: true,
                    ),
                    const SizedBox(height: 16),

                    _buildField(
                      label: 'District',
                      controller: districtController,
                    ),
                    const SizedBox(height: 16),

                    _buildField(label: 'State', controller: stateController),
                    const SizedBox(height: 16),

                    _buildField(
                      label: 'WhatsApp number',
                      controller: whatsappController,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 24),

                    FilledButton(
                      onPressed: saving ? null : saveProfile,
                      child: saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save profile'),
                    ),

                    if (message.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      SelectableText(message),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
