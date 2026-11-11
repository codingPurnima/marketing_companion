
import 'package:flutter/material.dart';
import 'product_card.dart';

class ProductListSection extends StatelessWidget {
  final List<dynamic> products;
  final Map<String, String> imageUrls;
  final Map<String, String> imagePaths;
  final Map<String, Map<String, dynamic>> imageComparisons;
  final String? voiceMatchedProductId;
  final bool loading;
  final bool canEdit;

  final VoidCallback onLoadProducts;
  final ValueChanged<Map<String, dynamic>> onEdit;
  final ValueChanged<String> onPublish;
  final ValueChanged<String> onUnpublish;
  final ValueChanged<Map<String, dynamic>> onShare;
  final ValueChanged<String> onRequestEnhancement;
  final void Function(String productId, String selection) onSelectImage;

  const ProductListSection({
    super.key,
    required this.products,
    required this.imageUrls,
    required this.imagePaths,
    required this.imageComparisons,
    required this.voiceMatchedProductId,
    required this.loading,
    required this.canEdit,
    required this.onLoadProducts,
    required this.onEdit,
    required this.onPublish,
    required this.onUnpublish,
    required this.onShare,
    required this.onRequestEnhancement,
    required this.onSelectImage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '3. Your products',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        OutlinedButton(
          onPressed: loading ? null : onLoadProducts,
          child: const Text('Load drafts'),
        ),
        if (products.isEmpty)
          const Text('No products loaded yet.')
        else
          ...products.map((item) {
            final product = Map<String, dynamic>.from(item as Map);
            final productId = product['id']?.toString();

            final comparison = productId == null
                ? null
                : imageComparisons[productId];

            return ProductCard(
              key: ValueKey(productId ?? product['title']),
              product: product,
              imageUrl: productId == null
                  ? null
                  : imageUrls[productId],
              enhancedUrl: comparison?['enhanced_url']?.toString(),
              enhancementStatus:
                  comparison?['enhancement_status']?.toString() ??
                      'not_requested',
              imageStoragePath: productId == null
                  ? null
                  : imagePaths[productId],
              isVoiceMatched: productId != null &&
                  productId == voiceMatchedProductId,
              loading: loading,
              canEdit: canEdit,
              onEdit: () => onEdit(product),
              onPublish: () {
                if (productId != null) onPublish(productId);
              },
              onUnpublish: () {
                if (productId != null) onUnpublish(productId);
              },
              onShare: () => onShare(product),
              onRequestEnhancement: () {
                final path = productId == null
                    ? null
                    : imagePaths[productId];
                if (path != null) onRequestEnhancement(path);
              },
              onSelectImage: (selection) {
                if (productId != null) {
                  onSelectImage(productId, selection);
                }
              },
            );
          }),
      ],
    );
  }
}
