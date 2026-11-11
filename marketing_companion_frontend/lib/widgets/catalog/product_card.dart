
import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final String? imageUrl;
  final String? enhancedUrl;
  final String enhancementStatus;
  final String? imageStoragePath;
  final bool isVoiceMatched;
  final bool loading;
  final bool canEdit;

  final VoidCallback onEdit;
  final VoidCallback onPublish;
  final VoidCallback onUnpublish;
  final VoidCallback onShare;
  final VoidCallback onRequestEnhancement;
  final void Function(String selection) onSelectImage;

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
                  errorBuilder: (_, __, ___) => const SizedBox(
                    height: 80,
                    child: Center(
                      child: Text('Image preview unavailable'),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              product['title']?.toString() ?? 'Untitled',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              '${product['category']} · '
              '₹${product['price'] ?? 'Not set'} · $status',
            ),
            if (productId != null) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: loading || !canEdit ? null : onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit product'),
              ),
              if (status == 'draft')
                FilledButton.tonalIcon(
                  onPressed: loading ? null : onPublish,
                  icon: const Icon(Icons.publish),
                  label: const Text('Publish product'),
                )
              else if (status == 'published')
                OutlinedButton.icon(
                  onPressed: loading ? null : onUnpublish,
                  icon: const Icon(Icons.unpublished_outlined),
                  label: const Text('Unpublish product'),
                ),
              if (status == 'published')
                OutlinedButton.icon(
                  onPressed: loading ? null : onShare,
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Share product'),
                ),
            ],
            if (imageUrl == null)
              const Text('No image attached'),
            if (enhancedUrl != null) ...[
              const SizedBox(height: 12),
              const Text(
                'Enhanced image',
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
                  errorBuilder: (_, __, ___) => const SizedBox(
                    height: 80,
                    child: Center(
                      child: Text(
                        'Enhanced image preview unavailable',
                      ),
                    ),
                  ),
                ),
              ),
            ],
            if (enhancementStatus == 'processing')
              const Text('Image enhancement is processing.'),
            if (enhancementStatus == 'failed')
              const Text(
                'Image enhancement failed. You can try again.',
              ),
            if (enhancementStatus == 'completed' &&
                enhancedUrl == null)
              const Text(
                'Enhanced image is ready, but its preview could not be loaded.',
              ),
            if (enhancedUrl != null && productId != null) ...[
              const SizedBox(height: 8),
              const Text(
                'Choose the image for your catalogue:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: loading
                          ? null
                          : () => onSelectImage('original'),
                      child: const Text('Use original'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: loading
                          ? null
                          : () => onSelectImage('enhanced'),
                      child: const Text('Use enhanced'),
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
                label: const Text('Test image enhancement'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
