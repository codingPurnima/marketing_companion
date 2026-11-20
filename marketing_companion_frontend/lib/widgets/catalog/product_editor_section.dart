
import 'dart:typed_data';

import 'package:flutter/material.dart';

class ProductEditorSection extends StatefulWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController categoryController;
  final TextEditingController priceController;

  final bool loading;
  final String? editingProductId;
  final String? savedProductId;
  final Uint8List? selectedImageBytes;

  final String? originalImageUrl;
  final String? enhancedImageUrl;
  final String selectedImageVersion;

  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;
  final VoidCallback onSave;
  final VoidCallback onCancelEditing;
  final VoidCallback onTestImageEnhancement;
  final VoidCallback onSelectOriginal;
  final VoidCallback onSelectEnhanced;

  final bool canTestEnhancement;

  const ProductEditorSection({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.categoryController,
    required this.priceController,
    required this.loading,
    required this.editingProductId,
    required this.savedProductId,
    required this.selectedImageBytes,
    required this.originalImageUrl,
    required this.enhancedImageUrl,
    required this.selectedImageVersion,
    required this.onPickImage,
    required this.onRemoveImage,
    required this.onSave,
    required this.onCancelEditing,
    required this.canTestEnhancement,
    required this.onTestImageEnhancement,
    required this.onSelectOriginal,
    required this.onSelectEnhanced,
  });

  @override
  State<ProductEditorSection> createState() =>
      _ProductEditorSectionState();
}

class _ProductEditorSectionState extends State<ProductEditorSection> {
  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editingProductId != null;
    final hasUploadedImage = widget.originalImageUrl != null;
    final hasEnhancedImage = widget.enhancedImageUrl != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isEditing ? 'Edit product' : '2. Review and edit draft',
          style: Theme.of(context).textTheme.titleLarge,
        ),

        const SizedBox(height: 12),

        TextField(
          controller: widget.titleController,
          decoration: const InputDecoration(
            labelText: 'Product title',
          ),
        ),

        TextField(
          controller: widget.descriptionController,
          minLines: 2,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Description',
          ),
        ),

        const SizedBox(height: 12),

        DropdownButtonFormField<String>(
          initialValue: widget.categoryController.text.isNotEmpty
              ? widget.categoryController.text
              : 'other',
          decoration: const InputDecoration(
            labelText: 'Product Category',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'pottery', child: Text('Pottery')),
            DropdownMenuItem(value: 'textiles', child: Text('Textiles')),
            DropdownMenuItem(value: 'weaving', child: Text('Weaving')),
            DropdownMenuItem(value: 'woodwork', child: Text('Woodwork')),
            DropdownMenuItem(value: 'metalwork', child: Text('Metalwork')),
            DropdownMenuItem(value: 'jewelry', child: Text('Jewelry')),
            DropdownMenuItem(value: 'paintings', child: Text('Paintings')),
            DropdownMenuItem(value: 'other', child: Text('Other')),
          ],
          onChanged: widget.loading
              ? null
              : (value) {
                  if (value != null) {
                    setState(() {
                      widget.categoryController.text = value;
                    });
                  }
                },
        ),

        TextField(
          controller: widget.priceController,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Price in INR (optional)',
          ),
        ),

        const SizedBox(height: 20),

        Text(
          'Product images',
          style: Theme.of(context).textTheme.titleMedium,
        ),

        const SizedBox(height: 8),

        OutlinedButton.icon(
          onPressed: widget.loading ? null : widget.onPickImage,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: Text(
            widget.selectedImageBytes == null
                ? 'Choose product image'
                : 'Change product image',
          ),
        ),

        if (widget.selectedImageBytes != null) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              widget.selectedImageBytes!,
              height: 210,
              width: double.infinity,
              fit: BoxFit.contain,
            ),
          ),
          TextButton.icon(
            onPressed: widget.loading ? null : widget.onRemoveImage,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Remove selected image'),
          ),
          const Text(
            'This image will be uploaded when you enhance it or save the draft.',
            style: TextStyle(fontSize: 12),
          ),
        ],

        if (widget.selectedImageBytes == null && hasUploadedImage) ...[
          const SizedBox(height: 16),

          Text(
            'Image comparison',
            style: Theme.of(context).textTheme.titleSmall,
          ),

          const SizedBox(height: 10),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildImageOption(
                  label: 'Original',
                  imageUrl: widget.originalImageUrl!,
                  selected:
                      widget.selectedImageVersion == 'original',
                  enabled: !widget.loading,
                  onTap: widget.onSelectOriginal,
                ),
              ),

              if (hasEnhancedImage) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _buildImageOption(
                    label: 'Enhanced',
                    imageUrl: widget.enhancedImageUrl!,
                    selected:
                        widget.selectedImageVersion == 'enhanced',
                    enabled: !widget.loading,
                    onTap: widget.onSelectEnhanced,
                  ),
                ),
              ],
            ],
          ),

          if (!hasEnhancedImage)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'No enhanced version available yet.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],

        const SizedBox(height: 16),

        if (widget.canTestEnhancement)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.loading
                  ? null
                  : widget.onTestImageEnhancement,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Enhance product image'),
            ),
          ),

        const SizedBox(height: 8),

        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: widget.loading ? null : widget.onSave,
            child: Text(
              isEditing
                  ? 'Update product'
                  : widget.savedProductId != null
                      ? 'Retry image upload'
                      : 'Save as draft',
            ),
          ),
        ),

        if (isEditing)
          TextButton(
            onPressed:
                widget.loading ? null : widget.onCancelEditing,
            child: const Text('Cancel editing'),
          ),
      ],
    );
  }

  Widget _buildImageOption({
    required String label,
    required String imageUrl,
    required bool selected,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image_outlined),
                ),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 6),

          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 18,
                ),
            ],
          ),

          Text(
            selected ? 'Currently selected' : 'Tap to select',
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
