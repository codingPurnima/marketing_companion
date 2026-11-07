import 'package:flutter/material.dart';
import 'package:marketing_companion_web/screens/artisan_directory_page.dart';
import 'package:marketing_companion_web/screens/product_detail_page.dart';
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
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ArtisanDirectoryPage()),
              );
            },
            icon: const Icon(Icons.people_outline),
            label: const Text('Artisans'),
          ),
          const SizedBox(width: 12),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 68,
        title: Row(
          children: [
            const Icon(
              Icons.storefront_outlined,
              color: Color(0xFF8B5E3C),
              size: 28,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'Artisan Marketplace',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: MediaQuery.sizeOf(context).width < 500 ? 18 : 22,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: TextField(
                  controller: searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (value) {
                    searchQuery = value;
                    applyFilters();
                  },
                  decoration: InputDecoration(
                    hintText: 'Search handmade products...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: () {
                        searchQuery = searchController.text;
                        applyFilters();
                      },
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: selectedCategory == null,
                      onSelected: (_) {
                        setState(() {
                          selectedCategory = null;
                        });
                        applyFilters();
                      },
                    ),
                    ...categories.map(
                      (category) => ChoiceChip(
                        label: Text(formatCategory(category)),
                        selected: selectedCategory == category,
                        onSelected: (_) {
                          setState(() {
                            selectedCategory = category;
                          });
                          applyFilters();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: productsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Unable to load products.'),
                        const SizedBox(height: 12),
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
                        const Icon(
                          Icons.search_off,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        const Text('No products found.'),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: clearFilters,
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

                    return GridView.builder(
                      padding: const EdgeInsets.all(24),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        childAspectRatio: width < 310 ? 1.05 : 0.8,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        return ProductCard(
                          product: products[index],
                          getProductImage: getProductImage,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final Future<String?> Function(Map<String, dynamic>) getProductImage;

  const ProductCard({
    super.key,
    required this.product,
    required this.getProductImage,
  });

  @override
  Widget build(BuildContext context) {
    final images = List<Map<String, dynamic>>.from(
      product['product_images'] ?? [],
    );

    images.sort(
      (a, b) => (a['sort_order'] ?? 0).compareTo(b['sort_order'] ?? 0),
    );

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailPage(product: product),
          ),
        );
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: images.isNotEmpty
                  ? FutureBuilder<String?>(
                      future: getProductImage(images.first),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data != null) {
                          return Image.network(
                            snapshot.data!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const ProductImagePlaceholder(),
                          );
                        }

                        return const ProductImagePlaceholder();
                      },
                    )
                  : const ProductImagePlaceholder(),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['title'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      product['category'] ?? '',
                      style: const TextStyle(color: Colors.brown),
                    ),
                    const Spacer(),
                    if (product['price'] != null)
                      Text(
                        '${product['currency'] ?? 'INR'} '
                        '${product['price']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductImagePlaceholder extends StatelessWidget {
  const ProductImagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFEDE7E0),
      child: const Icon(Icons.image_outlined, size: 48, color: Colors.brown),
    );
  }
}
