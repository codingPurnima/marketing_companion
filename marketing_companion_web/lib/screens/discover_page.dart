import 'package:flutter/material.dart';
import 'package:marketing_companion_web/screens/artisan_directory_page.dart';
import 'package:marketing_companion_web/screens/product_detail_page.dart';
import 'package:marketing_companion_web/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  final supabase = Supabase.instance.client;
  final searchController = TextEditingController();

  String? selectedCategory;
  String searchQuery = '';

  late Future<List<Map<String, dynamic>>> productsFuture;

  final List<String> categories = [
    'pottery',
    'textiles',
    'weaving',
    'woodwork',
    'metalwork',
    'jewelry',
    'paintings',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    productsFuture = fetchProducts();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> fetchProducts({
    String? category,
    String search = '',
  }) async {
    dynamic query = supabase
        .from('products')
        .select('''
      id,
      title,
      description,
      category,
      price,
      currency,
      product_images (
        id,
        storage_path,
        enhanced_storage_path,
        is_enhanced_selected,
        sort_order,
        alt_text
      )
    ''')
        .eq('status', 'published');

    if (category != null) {
      query = query.eq('category', category);
    }

    if (search.trim().isNotEmpty) {
      final term = search.trim();
      query = query.or('title.ilike.%$term%,description.ilike.%$term%');
    }

    final response = await query.select('''
      id,
      owner_id,
      title,
      description,
      category,
      price,
      currency,
      published_at,
      product_images (
        id,
        storage_path,
        enhanced_storage_path,
        is_enhanced_selected,
        sort_order,
        alt_text
      )
    ''');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<String?> getProductImage(Map<String, dynamic> image) async {
    try {
      final useEnhanced =
          image['is_enhanced_selected'] == true &&
          image['enhanced_storage_path'] != null;

      final path = useEnhanced
          ? image['enhanced_storage_path']
          : image['storage_path'];

      if (path == null) return null;

      return await supabase.storage
          .from('product-images')
          .createSignedUrl(path, 3600);
    } catch (e) {
      debugPrint('IMAGE FETCH ERROR: $e');
      return null;
    }
  }

  void applyFilters() {
    setState(() {
      productsFuture = fetchProducts(
        category: selectedCategory,
        search: searchQuery,
      );
    });
  }

  void clearFilters() {
    searchController.clear();

    setState(() {
      selectedCategory = null;
      searchQuery = '';
      productsFuture = fetchProducts();
    });
  }

  String formatCategory(String category) {
    return category[0].toUpperCase() + category.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 500;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: _buildAppBar(context, isMobile),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search + filter section
          _buildSearchSection(context),

          // Category filters
          _buildCategoryFilters(),

          const SizedBox(height: 8),

          // Product grid
          Expanded(child: _buildProductGrid()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isMobile) {
    return AppBar(
      backgroundColor: AppColors.surfaceWhite,
      elevation: 0,
      toolbarHeight: 68,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.storefront_outlined,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Artisan Marketplace',
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.navBrand,
                ),
                if (!isMobile)
                  Text(
                    'Handcrafted by Indian artisans',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ArtisanDirectoryPage()),
            );
          },
          icon: const Icon(Icons.people_outline_rounded, size: 18),
          label: const Text('Artisans'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textBody,
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.border),
      ),
    );
  }

  Widget _buildSearchSection(BuildContext context) {
    return Container(
      color: AppColors.surfaceWhite,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            style: AppTextStyles.bodyMedium,
            onSubmitted: (value) {
              searchQuery = value;
              applyFilters();
            },
            decoration: InputDecoration(
              hintText: 'Search handcrafted products…',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                onPressed: () {
                  searchQuery = searchController.text;
                  applyFilters();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return Container(
      color: AppColors.surfaceWhite,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CategoryChip(
                label: 'All',
                selected: selectedCategory == null,
                onSelected: (_) {
                  setState(() => selectedCategory = null);
                  applyFilters();
                },
              ),
              ...categories.map(
                (category) => _CategoryChip(
                  label: formatCategory(category),
                  selected: selectedCategory == category,
                  onSelected: (_) {
                    setState(() => selectedCategory = category);
                    applyFilters();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductGrid() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  size: 48,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 16),
                Text(
                  'Unable to load products.',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: applyFilters,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final products = snapshot.data ?? [];

        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.search_off_rounded,
                    size: 40,
                    color: AppColors.primaryMuted,
                  ),
                ),
                const SizedBox(height: 20),
                Text('No products found', style: AppTextStyles.headingSmall),
                const SizedBox(height: 8),
                Text(
                  'Try adjusting your search or filters.',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: clearFilters,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Clear filters'),
                ),
              ],
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            final columns = width >= 1100
                ? 4
                : width >= 750
                ? 3
                : width >= 500
                ? 2
                : 1;

            final padding = width < 500 ? 16.0 : 24.0;
            final spacing = width < 500 ? 12.0 : 20.0;

            return GridView.builder(
              padding: EdgeInsets.all(padding),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                childAspectRatio: columns == 1 ? 1.6 : 0.78,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                return ProductCard(
                  product: products[index],
                  getProductImage: getProductImage,
                  isWide: columns == 1,
                );
              },
            );
          },
        );
      },
    );
  }
}

// ───────────────────────────────────────────────
//  Category Chip
// ───────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: onSelected,
        showCheckmark: false,
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: selected ? AppColors.chipSelectedFg : AppColors.chipUnselectedFg,
        ),
        backgroundColor: AppColors.chipUnselected,
        selectedColor: AppColors.chipSelected,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        side: BorderSide.none,
        shape: const StadiumBorder(),
      ),
    );
  }
}

// ───────────────────────────────────────────────
//  Product Card
// ───────────────────────────────────────────────

class ProductCard extends StatefulWidget {
  final Map<String, dynamic> product;
  final Future<String?> Function(Map<String, dynamic>) getProductImage;
  final bool isWide;

  const ProductCard({
    super.key,
    required this.product,
    required this.getProductImage,
    this.isWide = false,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final images = List<Map<String, dynamic>>.from(
      widget.product['product_images'] ?? [],
    );
    images.sort(
      (a, b) => (a['sort_order'] ?? 0).compareTo(b['sort_order'] ?? 0),
    );

    final product = widget.product;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailPage(product: product),
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovered ? AppColors.primaryMuted : AppColors.border,
            ),
            color: AppColors.surfaceCard,
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(28),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          clipBehavior: Clip.antiAlias,
          child: widget.isWide
              ? _buildWideLayout(context, images, product)
              : _buildGridLayout(context, images, product),
        ),
      ),
    );
  }

  Widget _buildGridLayout(
    BuildContext context,
    List<Map<String, dynamic>> images,
    Map<String, dynamic> product,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image section — 60% of card height
        Expanded(
          flex: 5,
          child: Stack(
            fit: StackFit.expand,
            children: [
              images.isNotEmpty
                  ? FutureBuilder<String?>(
                      future: widget.getProductImage(images.first),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data != null) {
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
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }
                        return const ProductImagePlaceholder();
                      },
                    )
                  : const ProductImagePlaceholder(),
              // Category tag overlay
              if (product['category'] != null)
                Positioned(
                  top: 10,
                  left: 10,
                  child: CategoryTag(
                    label: (product['category'] as String).toUpperCase(),
                  ),
                ),
            ],
          ),
        ),

        // Info section — 40% of card height
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['title'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headingSmall.copyWith(fontSize: 15),
                ),
                const Spacer(),
                if (product['price'] != null)
                  Text(
                    '${product['currency'] ?? 'INR'} ${product['price']}',
                    style: AppTextStyles.priceSmall,
                  ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      'View details',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primaryMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 2),
                    AnimatedSlide(
                      offset: _hovered
                          ? const Offset(0.3, 0)
                          : const Offset(0, 0),
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        size: 12,
                        color: AppColors.primaryMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWideLayout(
    BuildContext context,
    List<Map<String, dynamic>> images,
    Map<String, dynamic> product,
  ) {
    return Row(
      children: [
        // Image — left side
        SizedBox(
          width: 160,
          height: double.infinity,
          child: images.isNotEmpty
              ? FutureBuilder<String?>(
                  future: widget.getProductImage(images.first),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      return Image.network(
                        snapshot.data!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const ProductImagePlaceholder(),
                      );
                    }
                    return const ProductImagePlaceholder();
                  },
                )
              : const ProductImagePlaceholder(),
        ),

        // Info — right side
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (product['category'] != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: CategoryTag(
                      label: (product['category'] as String).toUpperCase(),
                    ),
                  ),
                Text(
                  product['title'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headingSmall,
                ),
                const SizedBox(height: 6),
                if (product['description'] != null)
                  Text(
                    product['description'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall,
                  ),
                const Spacer(),
                if (product['price'] != null)
                  Text(
                    '${product['currency'] ?? 'INR'} ${product['price']}',
                    style: AppTextStyles.price,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
