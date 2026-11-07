import 'package:flutter/material.dart';
import 'package:marketing_companion_web/screens/artisan_profile_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailPage({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final supabase = Supabase.instance.client;

  Map<String, dynamic>? artisan;
  bool isLoadingArtisan = true;
  int selectedImageIndex = 0;

  List<Map<String, dynamic>> get images {
    final productImages =
        (widget.product['product_images'] as List<dynamic>?) ?? [];

    final sortedImages = productImages
        .map((image) => Map<String, dynamic>.from(image))
        .toList();

    sortedImages.sort(
      (a, b) => (a['sort_order'] ?? 0).compareTo(b['sort_order'] ?? 0),
    );

    return sortedImages;
  }

  void contactArtisan() {
  final phone = artisan?['whatsapp_number']?.toString() ?? '';

  if (phone.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('WhatsApp contact is not available.'),
      ),
    );
    return;
  }

  final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');

  final productTitle = widget.product['title'] ?? 'this product';

  final message = Uri.encodeComponent(
    'Hello! I am interested in $productTitle. '
    'Could you please share more details?',
  );

  final url = 'https://wa.me/$cleanPhone?text=$message';

launchUrl(
  Uri.parse(url),
  mode: LaunchMode.externalApplication,
);
}

  @override
  void initState() {
    super.initState();
    fetchArtisan();
  }

  Future<void> fetchArtisan() async {
    try {
      final ownerId = widget.product['owner_id'];

      if (ownerId == null) return;

      final response = await supabase
          .from('artisan_profiles')
          .select(
            'public_name, bio, craft, district, state, whatsapp_number',
          )
          .eq('user_id', ownerId)
          .maybeSingle();

      if (mounted) {
        setState(() {
          artisan = response;
        });
      }
    } catch (e) {
      debugPrint('ARTISAN FETCH ERROR: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoadingArtisan = false;
        });
      }
    }
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
      debugPrint('IMAGE URL ERROR: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final productImages = images;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (productImages.isNotEmpty) ...[
                  FutureBuilder<String?>(
                    future: getImageUrl(
                      productImages[selectedImageIndex],
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const SizedBox(
                          height: 350,
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (snapshot.data == null) {
                        return const SizedBox(
                          height: 350,
                          child: Center(
                            child: Icon(Icons.image_not_supported, size: 60),
                          ),
                        );
                      }

                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          snapshot.data!,
                          width: double.infinity,
                          height: 350,
                          fit: BoxFit.contain,
                        ),
                      );
                    },
                  ),
                  if (productImages.length > 1) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      children: List.generate(
                        productImages.length,
                        (index) => OutlinedButton(
                          onPressed: () {
                            setState(() {
                              selectedImageIndex = index;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: selectedImageIndex == index
                                ? Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                : null,
                          ),
                          child: Text('Image ${index + 1}'),
                        ),
                      ),
                    ),
                  ],
                ] else
                  const SizedBox(
                    height: 200,
                    child: Center(child: Icon(Icons.image, size: 60)),
                  ),

                const SizedBox(height: 24),

                Text(
                  product['title'] ?? 'Untitled product',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),

                const SizedBox(height: 8),

                Text(
                  product['category'] ?? 'Other',
                  style: Theme.of(context).textTheme.labelLarge,
                ),

                const SizedBox(height: 12),

                Text(
                  '${product['currency'] ?? 'INR'} ${product['price'] ?? 'Price not specified'}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),

                const SizedBox(height: 24),

                const Text(
                  'About this product',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  product['description'] ?? 'No description available.',
                ),

                const SizedBox(height: 32),

                const Text(
                  'About the artisan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                if (isLoadingArtisan)
                  const CircularProgressIndicator()
                else if (artisan == null)
                  const Text('Artisan information is unavailable.')
                else ...[
                  InkWell(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ArtisanProfilePage(
          ownerId: widget.product['owner_id'],
          artisan: artisan!,
        ),
      ),
    );
  },
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        artisan!['public_name'] ?? 'Artisan',
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
        ),
      ),
      const SizedBox(width: 6),
      const Icon(Icons.arrow_forward, size: 16),
    ],
  ),
),
                  if (artisan!['craft'] != null)
                    Text('Craft: ${artisan!['craft']}'),
                  if (artisan!['bio'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(artisan!['bio']),
                    ),
                  if (artisan!['district'] != null ||
                      artisan!['state'] != null)
                    Text(
                      [
                        artisan!['district'],
                        artisan!['state'],
                      ].where((value) => value != null).join(', '),
                    ),
                ],
                const SizedBox(height: 20),

SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
    onPressed: isLoadingArtisan || artisan == null
        ? null
        : contactArtisan,
    icon: const Icon(Icons.chat),
    label: const Text('Enquire on WhatsApp'),
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 16),
      backgroundColor: const Color(0xFF25D366),
      foregroundColor: Colors.white,
    ),
  ),
),
              ],
              
            ),
          ),
        ),
      ),
    );
  }
}