import 'package:flutter/material.dart';
import '../widgets/catalog/voice_assistant_section.dart';
import '../widgets/catalog/product_tile.dart';

class HomeScreen extends StatelessWidget {
  final List<dynamic> products;
  final Map<String, String> imageUrls;
  final bool loading;
  final String message;

  final Future<void> Function() onRefresh;
  final ValueChanged<Map<String, dynamic>> onProductTap;
  final VoidCallback onAddProduct;
  final VoidCallback onProfile;
  final VoidCallback onSignOut;

  final TextEditingController voiceInputController;
  final bool speechAvailable;
  final bool isListening;
  final String speechMessage;
  final VoidCallback onStartListening;
  final VoidCallback onStopListening;
  final VoidCallback onVoiceCommand;

  final List<dynamic> archivedProducts;
  final ValueChanged<String> onRepublishArchived;

  final String? voiceMatchedProductId;
  final ScrollController? scrollController;
  final VoidCallback? onScrollToProduct;

  final bool initialLoading;
  final String? initialError;
  final VoidCallback onRetry;

  const HomeScreen({
    super.key,
    required this.products,
    required this.imageUrls,
    required this.loading,
    required this.message,
    required this.onRefresh,
    required this.onProductTap,
    required this.onAddProduct,
    required this.onProfile,
    required this.onSignOut,
    required this.voiceInputController,
    required this.speechAvailable,
    required this.isListening,
    required this.onStartListening,
    required this.onStopListening,
    required this.onVoiceCommand,
    required this.speechMessage,
    required this.archivedProducts,
    required this.onRepublishArchived,
    this.voiceMatchedProductId,
    this.scrollController,
    this.onScrollToProduct,
    required this.initialLoading,
    required this.initialError,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final publishedProducts = products.where((item) {
      return item is Map && item['status']?.toString() == 'published';
    }).toList();

    final draftProducts = products.where((item) {
      return item is Map && item['status']?.toString() != 'published';
    }).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Products'),
        actions: [
          IconButton(
            tooltip: 'My profile',
            onPressed: loading ? null : onProfile,
            icon: const Icon(Icons.person_outline),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: onSignOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: loading ? null : onAddProduct,
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: CustomScrollView(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your catalog',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${products.length} ${products.length == 1 ? 'product' : 'products'}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (message.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        message,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                    if (loading) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),
            if (initialLoading)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Fetching products...',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              )
            else if (initialError != null && products.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_outlined, size: 48),
                        const SizedBox(height: 12),
                        const Text(
                          'Could not fetch your products.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          initialError!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: onRetry,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (products.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 56,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No active products yet',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Add your first product to start building your catalog.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              ..._buildProductSection(
                context,
                title: 'Published products',
                sectionProducts: publishedProducts,
                emptyMessage: 'No published products yet.',
              ),
              ..._buildProductSection(
                context,
                title: 'Drafts',
                sectionProducts: draftProducts,
                emptyMessage: 'No drafts yet.',
              ),
            ],
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Archived products',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Text(
                      '${archivedProducts.length}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            if (archivedProducts.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Text(
                    'No archived products.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final product = Map<String, dynamic>.from(
                      archivedProducts[index] as Map,
                    );

                    final title =
                        product['title']?.toString() ?? 'Untitled product';
                    final category = product['category']?.toString() ?? 'Other';
                    final price = product['price'] ?? product['price_inr'];
                    final productId = product['id']?.toString();

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 5,
                      ),
                      child: ProductTile(
                        title: title,
                        category: category,
                        price: price?.toString(),
                        status: 'archived',
                        imageUrl: productId == null
                            ? null
                            : imageUrls[productId],
                        onTap: null,
                        trailing: TextButton(
                          onPressed: loading || productId == null
                              ? null
                              : () => onRepublishArchived(productId),
                          child: const Text('Republish'),
                        ),
                      ),
                    );
                  }, childCount: archivedProducts.length),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: VoiceAssistantSection(
        controller: voiceInputController,
        loading: loading,
        speechAvailable: speechAvailable,
        isListening: isListening,
        speechMessage: speechMessage,
        onStartListening: onStartListening,
        onStopListening: onStopListening,
        onSubmit: onVoiceCommand,
      ),
    );
  }

  List<Widget> _buildProductSection(
    BuildContext context, {
    required String title,
    required List<dynamic> sectionProducts,
    required String emptyMessage,
  }) {
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        sliver: SliverToBoxAdapter(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Text(
                '${sectionProducts.length}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
      if (sectionProducts.isEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Text(
              emptyMessage,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final product = Map<String, dynamic>.from(
                sectionProducts[index] as Map,
              );

              final productId = product['id']?.toString();
              final title = product['title']?.toString() ?? 'Untitled product';
              final category = product['category']?.toString() ?? 'Other';
              final status = product['status']?.toString() ?? 'draft';
              final price = product['price'] ?? product['price_inr'];

              final imageUrl = productId == null ? null : imageUrls[productId];

              final isVoiceMatched =
                  productId != null && productId == voiceMatchedProductId;

              if (isVoiceMatched && onScrollToProduct != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  onScrollToProduct!.call();
                });
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                child: ProductTile(
                  title: title,
                  category: category,
                  price: price?.toString(),
                  status: status,
                  imageUrl: imageUrl,
                  highlighted: isVoiceMatched,
                  onTap: loading ? null : () => onProductTap(product),
                ),
              );
            }, childCount: sectionProducts.length),
          ),
        ),
    ];
  }
}
