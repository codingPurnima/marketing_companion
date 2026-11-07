import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'product_detail_page.dart';

class ArtisanProfilePage extends StatefulWidget {
  final String ownerId;
  final Map<String, dynamic>? artisan;

  const ArtisanProfilePage({
    super.key,
    required this.ownerId,
    this.artisan,
  });

  @override
  State<ArtisanProfilePage> createState() => _ArtisanProfilePageState();
}

class _ArtisanProfilePageState extends State<ArtisanProfilePage> {
  final supabase = Supabase.instance.client;

  late Future<List<Map<String, dynamic>>> productsFuture;
  Map<String, dynamic>? artisanData;
bool profileLoading = true;
String? profileError;

 @override
void initState() {
  debugPrint('ARTISAN PROFILE PAGE INIT: ${widget.ownerId}');
  super.initState();

  productsFuture = fetchProducts();

  artisanData = widget.artisan;

  if (artisanData != null) {
    profileLoading = false;
  } else {
    fetchArtisan();
  }
}

Future<void> fetchArtisan() async {
  try {
    final response = await supabase
        .from('artisan_profiles')
        .select(
          'user_id, public_name, bio, craft, district, state, whatsapp_number',
        )
        .eq('user_id', widget.ownerId)
        .maybeSingle();

      debugPrint('FETCHED ARTISAN DATA: $response');

    if (!mounted) return;

    setState(() {
      artisanData = response;
      profileLoading = false;

      if (response == null) {
        profileError = 'Artisan profile not found.';
      }
    });
  } catch (e) {
    if (!mounted) return;

    setState(() {
      profileLoading = false;
      profileError = 'Unable to load artisan profile.';
    });

    debugPrint('ARTISAN PROFILE ERROR: $e');
  }
}

  Future<List<Map<String, dynamic>>> fetchProducts() async {
    final response = await supabase
        .from('products')
        .select('''
          id, owner_id, title, description, category, price, currency,
          published_at,
          product_images (
            id, storage_path, enhanced_storage_path,
            is_enhanced_selected, sort_order, alt_text
          )
        ''')
        .eq('owner_id', widget.ownerId)
        .eq('status', 'published')
        .order('published_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<String?> getImageUrl(Map<String, dynamic> image) async {
    try {
      final useEnhanced = image['is_enhanced_selected'] == true &&
          image['enhanced_storage_path'] != null;

      final path = useEnhanced
          ? image['enhanced_storage_path']
          : image['storage_path'];

      if (path == null) return null;

      return await supabase.storage
          .from('product-images')
          .createSignedUrl(path, 3600);
    } catch (e) {
      debugPrint('PROFILE IMAGE ERROR: $e');
      return null;
    }
  }

  void openProduct(Map<String, dynamic> product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailPage(product: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (profileLoading) {
      
  return Scaffold(
    
    appBar: AppBar(title: const Text('Artisan Profile')),
    body: const Center(child: CircularProgressIndicator()),
  );
}

if (artisanData == null) {
  return Scaffold(
    appBar: AppBar(title: const Text('Artisan Profile')),
    body: Center(
      child: Text(profileError ?? 'Artisan profile not found.'),
    ),
  );
}

final artisan = artisanData!;
debugPrint('RENDERING ARTISAN PROFILE: ${artisan['public_name']}');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Artisan Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  artisan['public_name'] ?? 'Artisan',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),

                if (artisan['craft'] != null)
                  Text(
                    artisan['craft'],
                    style: Theme.of(context).textTheme.titleMedium,
                  ),

                const SizedBox(height: 12),

                if (artisan['bio'] != null)
                  Text(artisan['bio']),

                if (artisan['district'] != null ||
                    artisan['state'] != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 18),
                      const SizedBox(width: 6),
                      Text([
                        artisan['district'],
                        artisan['state'],
                      ].where((value) => value != null).join(', ')),
                    ],
                  ),
                ],

                const SizedBox(height: 32),

                Text(
                  'Published Products',
                  style: Theme.of(context).textTheme.titleLarge,
                ),

                const SizedBox(height: 16),

                FutureBuilder<List<Map<String, dynamic>>>(
                  future: productsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (snapshot.hasError) {
                      return const Text('Unable to load products.');
                    }

                    final products = snapshot.data ?? [];

                    if (products.isEmpty) {
                      return const Text(
                        'This artisan has no published products yet.',
                      );
                    }

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final columns =
                            constraints.maxWidth >= 700 ? 3 : 2;

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: products.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.78,
                          ),
                          itemBuilder: (context, index) {
                            final product = products[index];
                            final images =
                                (product['product_images'] as List?)
                                        ?.cast<Map<String, dynamic>>() ??
                                    [];

                            images.sort(
                              (a, b) => (a['sort_order'] ?? 0)
                                  .compareTo(b['sort_order'] ?? 0),
                            );

                            return Card(
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () => openProduct(product),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: images.isEmpty
                                          ? const Center(
                                              child: Icon(
                                                Icons.image_outlined,
                                                size: 40,
                                              ),
                                            )
                                          : FutureBuilder<String?>(
                                              future: getImageUrl(images.first),
                                              builder: (context, imageSnapshot) {
                                                if (imageSnapshot.data == null) {
                                                  return const Center(
                                                    child: Icon(
                                                      Icons.image_outlined,
                                                      size: 40,
                                                    ),
                                                  );
                                                }

                                                return Image.network(
                                                  imageSnapshot.data!,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      const Center(
                                                    child: Icon(
                                                      Icons.broken_image,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product['title'] ?? 'Untitled',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${product['currency'] ?? 'INR'} ${product['price'] ?? 'Price not specified'}',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}