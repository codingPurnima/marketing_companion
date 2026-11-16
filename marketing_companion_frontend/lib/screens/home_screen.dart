
import 'package:flutter/material.dart';
import '../widgets/catalog/voice_assistant_section.dart';

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
  });

  @override
  Widget build(BuildContext context) {
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
            if (products.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 56,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No products yet',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Add your first product to start building your catalog.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: loading ? null : onAddProduct,
                          icon: const Icon(Icons.add),
                          label: const Text('Add your first product'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product = Map<String, dynamic>.from(
                        products[index] as Map,
                      );

                      final productId = product['id']?.toString();
                      final title =
                          product['title']?.toString() ?? 'Untitled product';
                      final category =
                          product['category']?.toString() ?? 'Other';
                      final status =
                          product['status']?.toString() ?? 'draft';
                      final price =
                          product['price'] ?? product['price_inr'];

                      final imageUrl = productId == null
                          ? null
                          : imageUrls[productId];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 5,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          onTap: loading
                              ? null
                              : () => onProductTap(product),
                          leading: SizedBox(
                            width: 64,
                            height: 64,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: imageUrl != null
                                  ? Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _imagePlaceholder(context),
                                    )
                                  : _imagePlaceholder(context),
                            ),
                          ),
                          title: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$category · ${price == null ? 'Price not set' : '₹$price'}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                _statusLabel(context, status),
                              ],
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                        ),
                      );
                    },
                    childCount: products.length,
                  ),
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

  Widget _imagePlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_outlined,
        color: Theme.of(context).colorScheme.outline,
      ),
    );
  }

  Widget _statusLabel(BuildContext context, String status) {
    final label = switch (status) {
      'published' => 'Published',
      'archived' => 'Archived',
      _ => 'Draft',
    };

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 9,
          vertical: 3,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
    );
  }
}
