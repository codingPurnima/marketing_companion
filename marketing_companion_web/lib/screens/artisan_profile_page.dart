import 'package:flutter/material.dart';
import 'package:marketing_companion_web/theme/app_theme.dart';
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
      return const LoadingScaffold(title: 'Artisan Profile');
    }

    if (artisanData == null) {
      return ErrorScaffold(
        title: 'Artisan Profile',
        message: profileError ?? 'Artisan profile not found.',
      );
    }

    final artisan = artisanData!;
    debugPrint('RENDERING ARTISAN PROFILE: ${artisan['public_name']}');

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile header card
                  _buildProfileHeader(artisan),

                  const SizedBox(height: 40),

                  // Products section header
                  _buildSectionHeader('Published Products'),

                  const SizedBox(height: 20),

                  // Products grid
                  _buildProductsSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surfaceWhite,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        color: AppColors.textBody,
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text('Artisan Profile', style: AppTextStyles.navBrand),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.border),
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> artisan) {
    final name = artisan['public_name'] ?? 'Artisan';
    final craft = artisan['craft'] as String?;
    final bio = artisan['bio'] as String?;
    final district = artisan['district'] as String?;
    final state = artisan['state'] as String?;

    final location = [district, state]
        .where((v) => v != null && v.isNotEmpty)
        .join(', ');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ArtisanAvatar(radius: 36),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTextStyles.headingLarge,
                    ),
                    if (craft != null) ...[
                      const SizedBox(height: 8),
                      CraftBadge(label: craft),
                    ],
                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            location,
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          if (bio != null && bio.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              height: 1,
              color: AppColors.divider,
            ),
            const SizedBox(height: 20),
            Text(
              'About',
              style: AppTextStyles.sectionLabel,
            ),
            const SizedBox(height: 8),
            Text(
              bio,
              style: AppTextStyles.bodyLarge,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.headingMedium),
        const SizedBox(height: 6),
        const OrnamentsiveDivider(width: 48),
      ],
    );
  }

  Widget _buildProductsSection() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Unable to load products.',
              style: AppTextStyles.bodyMedium,
            ),
          );
        }

        final products = snapshot.data ?? [];

        if (products.isEmpty) {
          return _buildNoProductsState();
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final columns = width >= 700
                ? 3
                : width >= 420
                ? 2
                : 1;
            final spacing = width < 500 ? 12.0 : 18.0;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                childAspectRatio: 0.8,
              ),
              itemBuilder: (context, index) {
                final product = products[index];
                final productImages =
                    (product['product_images'] as List?)
                            ?.cast<Map<String, dynamic>>() ??
                        [];

                productImages.sort(
                  (a, b) =>
                      (a['sort_order'] ?? 0).compareTo(b['sort_order'] ?? 0),
                );

                return _ProfileProductCard(
                  product: product,
                  images: productImages,
                  getImageUrl: getImageUrl,
                  onTap: () => openProduct(product),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildNoProductsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceWarm,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 48,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'No products yet',
            style: AppTextStyles.headingSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'This artisan has not published any products yet.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────
//  Profile Product Card
// ───────────────────────────────────────────────

class _ProfileProductCard extends StatefulWidget {
  final Map<String, dynamic> product;
  final List<Map<String, dynamic>> images;
  final Future<String?> Function(Map<String, dynamic>) getImageUrl;
  final VoidCallback onTap;

  const _ProfileProductCard({
    required this.product,
    required this.images,
    required this.getImageUrl,
    required this.onTap,
  });

  @override
  State<_ProfileProductCard> createState() => _ProfileProductCardState();
}

class _ProfileProductCardState extends State<_ProfileProductCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hovered ? AppColors.primaryMuted : AppColors.border,
            ),
            color: AppColors.surfaceCard,
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(28),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Expanded(
                flex: 5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    widget.images.isEmpty
                        ? const ProductImagePlaceholder()
                        : FutureBuilder<String?>(
                            future: widget.getImageUrl(widget.images.first),
                            builder: (context, snapshot) {
                              if (snapshot.data != null) {
                                return AnimatedScale(
                                  scale: _hovered ? 1.04 : 1.0,
                                  duration: const Duration(milliseconds: 300),
                                  child: Image.network(
                                    snapshot.data!,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) =>
                                        const ProductImagePlaceholder(),
                                  ),
                                );
                              }
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Container(
                                  color: AppColors.surfaceWarm,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                );
                              }
                              return const ProductImagePlaceholder();
                            },
                          ),
                    if (product['category'] != null)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: CategoryTag(
                          label: (product['category'] as String).toUpperCase(),
                        ),
                      ),
                  ],
                ),
              ),

              // Info
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product['title'] ?? 'Untitled',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:
                            AppTextStyles.headingSmall.copyWith(fontSize: 14),
                      ),
                      Text(
                        '${product['currency'] ?? 'INR'} ${product['price'] ?? '—'}',
                        style: AppTextStyles.priceSmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}