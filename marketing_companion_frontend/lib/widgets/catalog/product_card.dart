import 'package:flutter/material.dart';
import '../../l10n/ui_text.dart';

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final String? imageUrl;
  final String? enhancedUrl;
  final String enhancementStatus;
  final String? imageStoragePath;
  final bool isVoiceMatched;
  final bool loading;
  final bool canEdit;
  final String? selectedImage;

  final VoidCallback onEdit;
  final VoidCallback onPublish;
  final VoidCallback onUnpublish;
  final VoidCallback onShare;
  final VoidCallback onRequestEnhancement;
  final void Function(String selection) onSelectImage;
  final Map<String, dynamic>? comparison;

  const ProductCard({
    super.key,
    required this.product,
    required this.imageUrl,
    required this.enhancedUrl,
    required this.enhancementStatus,
    required this.imageStoragePath,
    required this.isVoiceMatched,
    required this.loading,
    required this.canEdit,
    required this.onEdit,
    required this.onPublish,
    required this.onUnpublish,
    required this.onShare,
    required this.onRequestEnhancement,
    required this.onSelectImage,
    required this.comparison,
    required this.selectedImage,
  });

  @override
  Widget build(BuildContext context) {
    final productId = product['id']?.toString();
    final status = product['status']?.toString();

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isVoiceMatched
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => SizedBox(
                    height: 80,
                    child: Center(
                      child: Text(UiText.get(context, 'imageUnavailable')),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              product['title']?.toString() ?? UiText.get(context, 'untitled'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              '${UiText.category(context, product['category']?.toString() ?? 'other')} · '
              '₹${product['price'] ?? 'Not set'} · '
              '${UiText.status(context, status ?? 'draft')}',
            ),
            if (productId != null) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: loading || !canEdit ? null : onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: Text(UiText.get(context, 'editProduct')),
              ),
              if (status == 'draft')
                FilledButton.tonalIcon(
                  onPressed: loading ? null : onPublish,
                  icon: const Icon(Icons.publish),
                  label: Text(UiText.get(context, 'publishProduct')),
                )
              else if (status == 'published')
                OutlinedButton.icon(
                  onPressed: loading ? null : onUnpublish,
                  icon: const Icon(Icons.unpublished_outlined),
                  label: Text(UiText.get(context, 'unpublishProduct')),
                ),
              if (status == 'published')
                OutlinedButton.icon(
                  onPressed: loading ? null : onShare,
                  icon: const Icon(Icons.share_outlined),
                  label: Text(UiText.get(context, 'shareProduct')),
                ),
            ],
            if (imageUrl == null) Text(UiText.get(context, 'noImage')),
            if (enhancedUrl != null && selectedImage != 'enhanced') ...[
              const SizedBox(height: 12),
              Text(
                UiText.get(context, 'enhancedPreview'),
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  enhancedUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            if (enhancementStatus == 'processing')
              Text(UiText.get(context, 'enhancing')),
            if (enhancementStatus == 'failed')
              Text(UiText.get(context, 'enhanceFailed')),
            if (enhancementStatus == 'completed' && enhancedUrl == null)
              Text(UiText.get(context, 'enhancedPreviewFailed')),
            if (enhancedUrl != null &&
                productId != null &&
                (comparison?['selected_image']?.toString() != 'enhanced')) ...[
              const SizedBox(height: 8),
              Text(
                UiText.get(context, 'chooseImage'),
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: loading
                          ? null
                          : () => onSelectImage('original'),
                      child: Text(UiText.get(context, 'original')),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: loading
                          ? null
                          : () => onSelectImage('enhanced'),
                      child: Text(UiText.get(context, 'enhanced')),
                    ),
                  ),
                ],
              ),
            ],
            if (imageUrl != null && productId != null) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: loading || imageStoragePath == null
                    ? null
                    : onRequestEnhancement,
                icon: const Icon(Icons.auto_awesome),
                label: Text(UiText.get(context, 'testEnhancement')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
