
import 'dart:typed_data';

import 'package:flutter/material.dart';

class ProductEditorSection extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController categoryController;
  final TextEditingController priceController;

  final bool loading;
  final String? editingProductId;
  final String? savedProductId;
  final Uint8List? selectedImageBytes;

  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;
  final VoidCallback onSave;
  final VoidCallback onCancelEditing;

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
    required this.onPickImage,
    required this.onRemoveImage,
    required this.onSave,
    required this.onCancelEditing,
  });

  @override
  Widget build(BuildContext context) {
    final isEditing = editingProductId != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isEditing ? '2. Edit product' : '2. Review and edit draft',
          style: Theme.of(context).textTheme.titleLarge,
        ),

        TextField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: 'Product title',
          ),
        ),
        TextField(
          controller: descriptionController,
          minLines: 2,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Description',
          ),
        ),
        TextField(
          controller: categoryController,
          decoration: const InputDecoration(
            labelText: 'Category (use a supported value)',
          ),
        ),
        TextField(
          controller: priceController,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
          ),
          decoration: const InputDecoration(
            labelText: 'Price in INR (optional)',
          ),
        ),

        const SizedBox(height: 16),

        OutlinedButton.icon(
          onPressed: loading ? null : onPickImage,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: Text(
            selectedImageBytes == null
                ? 'Choose product image'
                : 'Change product image',
          ),
        ),

        if (selectedImageBytes != null) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              selectedImageBytes!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.contain,
            ),
          ),
          TextButton.icon(
            onPressed: loading ? null : onRemoveImage,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Remove selected image'),
          ),
        ],

        const SizedBox(height: 8),

        FilledButton(
          onPressed: loading ? null : onSave,
          child: Text(
            isEditing
                ? 'Update product'
                : savedProductId != null
                    ? 'Retry image upload'
                    : 'Save as draft',
          ),
        ),

        if (isEditing)
          TextButton(
            onPressed: loading ? null : onCancelEditing,
            child: const Text('Cancel editing'),
          ),
      ],
    );
  }
}
