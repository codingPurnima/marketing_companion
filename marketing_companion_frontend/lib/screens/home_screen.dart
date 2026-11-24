import 'package:flutter/material.dart';
import '../widgets/catalog/voice_assistant_section.dart';
import '../widgets/catalog/product_tile.dart';
import '../l10n/generated/app_localizations.dart';

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

  final Map<String, GlobalKey> productItemKeys;

  final Future<void> Function(String productId, bool publish)
  onUpdatePublication;

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
    required this.productItemKeys,
    required this.onUpdatePublication,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final publishedProducts = products.where((item) {
      return item is Map && item['status']?.toString() == 'published';
    }).toList();

    final draftProducts = products.where((item) {
      return item is Map && item['status']?.toString() != 'published';
    }).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myProducts),
        actions: [
          IconButton(
            tooltip: l10n.myProfile,
            onPressed: loading ? null : onProfile,
            icon: const Icon(Icons.person_outline),
          ),
          IconButton(
            tooltip: l10n.signOut,
            onPressed: onSignOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: loading ? null : onAddProduct,
        icon: const Icon(Icons.add),
        label: Text(l10n.addProduct),
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
                      l10n.yourCatalog,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      products.length == 1
                          ? l10n.productCountOne
                          : l10n.productCount(products.length),
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
                        l10n.fetchingProducts,
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
                        Text(
                          l10n.couldNotFetchProducts,
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
                          label: Text(l10n.tryAgain),
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
                        l10n.noActiveProducts,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.addFirstProductMessage,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              ..._buildProductSection(
                context,
                title: l10n.publishedProducts,
                sectionProducts: publishedProducts,
                emptyMessage: l10n.noPublishedProducts,
              ),
              ..._buildProductSection(
                context,
                title: l10n.drafts,
                sectionProducts: draftProducts,
                emptyMessage: l10n.noDrafts,
              ),
            ],
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.archivedProducts,
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
                    l10n.noArchivedProducts,
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
                        product['title']?.toString() ?? l10n.untitledProduct;
                    final category = product['category']?.toString() ?? l10n.otherCategory;
                    final price = product['price'] ?? product['price_inr'];
                    final productId = product['id']?.toString();

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 5,
                      ),
                      child: ProductTile(
                        key: productId == null
                            ? null
                            : productItemKeys.putIfAbsent(
                                productId,
                                () => GlobalKey(),
                              ),
                        title: title,
                        category: category,
                        price: price?.toString(),
                        status: 'archived',
                        imageUrl: productId == null
                            ? null
                            : imageUrls[productId],
                        onTap: null,
                        actionLabel: l10n.republish,

                        onAction: loading || productId == null
                            ? null
                            : () => _confirmProductAction(
                                context,
                                productId,
                                'archived',
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

  Future<void> _confirmProductAction(
    BuildContext context,
    String productId,
    String status,
  ) async {
    if (loading) return;

    final l10n = AppLocalizations.of(context)!;

    // ignore: unused_local_variable
    String action;
    String buttonLabel;
    String dialogTitle;
    String dialogDescription;

    switch (status) {
      case 'published':
        action = 'archive';
        buttonLabel = l10n.archive;
        dialogTitle = l10n.archiveProductConfirmation;
        dialogDescription = l10n.archiveProductDescription;
        break;

      case 'archived':
        action = 'republish';
        buttonLabel = l10n.republish;
        dialogTitle = l10n.republishProductConfirmation;
        dialogDescription = l10n.republishProductDescription;
        break;

      default:
        action = 'publish';
        buttonLabel = l10n.publish;
        dialogTitle = l10n.publishProductConfirmation;
        dialogDescription = l10n.publishProductDescription;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogTitle),
        content: Text(dialogDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(buttonLabel),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (status == 'archived') {
      onRepublishArchived(productId);
    } else {
      onUpdatePublication(productId, status != 'published');
    }
  }

  List<Widget> _buildProductSection(
    BuildContext context, {
    required String title,
    required List<dynamic> sectionProducts,
    required String emptyMessage,
  }) {
    final l10n = AppLocalizations.of(context)!;
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
            delegate: SliverChildListDelegate(
              List.generate(sectionProducts.length, (index) {
                final product = Map<String, dynamic>.from(
                  sectionProducts[index] as Map,
                );

                final productId = product['id']?.toString();

                final productTitle =
                    product['title']?.toString() ?? l10n.untitledProduct;

                final category = product['category']?.toString() ?? l10n.otherCategory;

                final status = product['status']?.toString() ?? 'draft';

                final price = product['price'] ?? product['price_inr'];

                final imageUrl = productId == null
                    ? null
                    : imageUrls[productId];

                final isVoiceMatched =
                    productId != null && productId == voiceMatchedProductId;

                final productKey = productId == null
                    ? null
                    : productItemKeys.putIfAbsent(productId, () => GlobalKey());

                return Padding(
                  key: productKey,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 5,
                  ),
                  child: ProductTile(
                    title: productTitle,
                    category: category,
                    price: price?.toString(),
                    status: status,
                    imageUrl: imageUrl,
                    highlighted: isVoiceMatched,
                    onTap: loading ? null : () => onProductTap(product),
                    actionLabel: status == 'published' ? l10n.archive : l10n.publish,

                    onAction: loading || productId == null
                        ? null
                        : () =>
                              _confirmProductAction(context, productId, status),
                  ),
                );
              }),
            ),
          ),
        ),
    ];
  }
}
