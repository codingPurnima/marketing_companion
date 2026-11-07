import 'package:flutter/material.dart';
import 'package:marketing_companion_web/screens/artisan_profile_page.dart';
import 'package:marketing_companion_web/theme/app_theme.dart';
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
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = screenWidth >= 820;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: _buildAppBar(context, product),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: Padding(
              padding: EdgeInsets.all(screenWidth < 500 ? 16 : 24),
              child: isWide
                  ? _buildWideLayout(context, product, productImages)
                  : _buildNarrowLayout(context, product, productImages),
            ),
          ),
        ),
      ),
      // Sticky WhatsApp CTA on mobile
      bottomNavigationBar: !isWide
          ? _buildStickyContactBar(context)
          : null,
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, Map<String, dynamic> product) {
    return AppBar(
      backgroundColor: AppColors.surfaceWhite,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        color: AppColors.textBody,
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        product['title'] ?? 'Product Details',
        style: AppTextStyles.navBrand,
        overflow: TextOverflow.ellipsis,
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.border),
      ),
    );
  }

  // ── Wide layout (desktop/tablet) — image left, details right ──

  Widget _buildWideLayout(
    BuildContext context,
    Map<String, dynamic> product,
    List<Map<String, dynamic>> productImages,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: Image panel
        Expanded(
          flex: 5,
          child: _buildImagePanel(productImages),
        ),

        const SizedBox(width: 32),

        // Right: Product info
        Expanded(
          flex: 5,
          child: _buildProductInfoPanel(context, product, wide: true),
        ),
      ],
    );
  }

  // ── Narrow layout (mobile) — stacked ──

  Widget _buildNarrowLayout(
    BuildContext context,
    Map<String, dynamic> product,
    List<Map<String, dynamic>> productImages,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildImagePanel(productImages),
        const SizedBox(height: 24),
        _buildProductInfoPanel(context, product, wide: false),
        // Extra bottom padding so sticky bar doesn't obscure content
        const SizedBox(height: 80),
      ],
    );
  }

  // ── Image panel ──

  Widget _buildImagePanel(List<Map<String, dynamic>> productImages) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main image
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 1,
            child: productImages.isEmpty
                ? Container(
                    color: AppColors.surfaceWarm,
                    child: const Center(
                      child: Icon(
                        Icons.image_outlined,
                        size: 72,
                        color: AppColors.primaryMuted,
                      ),
                    ),
                  )
                : FutureBuilder<String?>(
                    future: getImageUrl(productImages[selectedImageIndex]),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Container(
                          color: AppColors.surfaceWarm,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (snapshot.data == null) {
                        return Container(
                          color: AppColors.surfaceWarm,
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              size: 72,
                              color: AppColors.textMuted,
                            ),
                          ),
                        );
                      }

                      return Image.network(
                        snapshot.data!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: AppColors.surfaceWarm,
                          child: const Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              size: 48,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),

        // Thumbnail strip (if multiple images)
        if (productImages.length > 1) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: productImages.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => setState(() => selectedImageIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selectedImageIndex == index
                            ? AppColors.primary
                            : AppColors.border,
                        width: selectedImageIndex == index ? 2 : 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: FutureBuilder<String?>(
                      future: getImageUrl(productImages[index]),
                      builder: (context, snapshot) {
                        if (snapshot.data != null) {
                          return Image.network(
                            snapshot.data!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                const ProductImagePlaceholder(),
                          );
                        }
                        return const ProductImagePlaceholder();
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  // ── Product info panel ──

  Widget _buildProductInfoPanel(
    BuildContext context,
    Map<String, dynamic> product,
    {required bool wide}
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Category tag
        if (product['category'] != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: CategoryTag(
              label: (product['category'] as String).toUpperCase(),
            ),
          ),

        // Product title
        Text(
          product['title'] ?? 'Untitled product',
          style: AppTextStyles.headingLarge,
        ),

        const SizedBox(height: 14),

        // Price
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${product['currency'] ?? 'INR'} ${product['price'] ?? '—'}',
            style: AppTextStyles.price.copyWith(fontSize: 22),
          ),
        ),

        const SizedBox(height: 24),

        // Description
        Text(
          'About this product',
          style: AppTextStyles.sectionLabel,
        ),
        const SizedBox(height: 10),
        Text(
          product['description'] ?? 'No description available.',
          style: AppTextStyles.bodyLarge,
        ),

        const SizedBox(height: 28),

        // Artisan section
        Container(
          height: 1,
          color: AppColors.divider,
        ),
        const SizedBox(height: 24),

        Text('About the artisan', style: AppTextStyles.sectionLabel),

        const SizedBox(height: 14),

        _buildArtisanSection(context, product),

        const SizedBox(height: 24),

        // WhatsApp CTA — only on desktop
        if (wide) _buildWhatsAppButton(),
      ],
    );
  }

  Widget _buildArtisanSection(
    BuildContext context,
    Map<String, dynamic> product,
  ) {
    if (isLoadingArtisan) {
      return const SizedBox(
        height: 48,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (artisan == null) {
      return Text(
        'Artisan information is unavailable.',
        style: AppTextStyles.bodyMedium,
      );
    }

    final location = [artisan!['district'], artisan!['state']]
        .where((v) => v != null)
        .join(', ');

    return GestureDetector(
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
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surfaceWarm,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            ArtisanAvatar(radius: 26),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          artisan!['public_name'] ?? 'Artisan',
                          style: AppTextStyles.headingSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: AppColors.primaryMuted,
                      ),
                    ],
                  ),
                  if (artisan!['craft'] != null) ...[
                    const SizedBox(height: 4),
                    CraftBadge(label: artisan!['craft']),
                  ],
                  if (location.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            location,
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhatsAppButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isLoadingArtisan || artisan == null ? null : contactArtisan,
        icon: const Icon(Icons.chat_rounded, size: 18),
        label: const Text('Enquire on WhatsApp'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: AppColors.whatsapp,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.border,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildStickyContactBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.paddingOf(context).bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: _buildWhatsAppButton(),
    );
  }
}