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
  State<ProductEditorSection> createState() => _ProductEditorSectionState();
}

class _ProductEditorSectionState extends State<ProductEditorSection> {
  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editingProductId != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isEditing ? '2. Edit product' : '2. Review and edit draft',
          style: Theme.of(context).textTheme.titleLarge,
        ),

        TextField(
          controller: widget.titleController,
          decoration: const InputDecoration(labelText: 'Product title'),
        ),
        TextField(
          controller: widget.descriptionController,
          minLines: 2,
          maxLines: 5,
          decoration: const InputDecoration(labelText: 'Description'),
        ),
        const SizedBox(height: 8),
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
          onChanged: (value) {
            if (value != null) {
              setState(() {
                widget.categoryController.text = value;
              });
            }
          },
        ),
        TextField(
          controller: widget.priceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Price in INR (optional)',
          ),
        ),

        const SizedBox(height: 16),

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
              height: 200,
              width: double.infinity,
              fit: BoxFit.contain,
            ),
          ),
          TextButton.icon(
            onPressed: widget.loading ? null : widget.onRemoveImage,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Remove selected image'),
          ),
        ],

        const SizedBox(height: 8),

        FilledButton(
          onPressed: widget.loading ? null : widget.onSave,
          child: Text(
            isEditing
                ? 'Update product'
                : widget.savedProductId != null
                ? 'Retry image upload'
                : 'Save as draft',
          ),
        ),

        if (isEditing)
          TextButton(
            onPressed: widget.loading ? null : widget.onCancelEditing,
            child: const Text('Cancel editing'),
          ),
      ],
    );
  }
}
