
import 'package:flutter/material.dart';

class ArchivedProductsSection extends StatelessWidget {
  final List<dynamic> products;
  final bool loading;
  final ValueChanged<String> onRepublish;

  const ArchivedProductsSection({
    super.key,
    required this.products,
    required this.loading,
    required this.onRepublish,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Archived',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (products.isEmpty)
          const Text('No archived products yet.')
        else
          ...products.map((product) {
            final item = Map<String, dynamic>.from(product as Map);
            final productId = item['id']?.toString();

            return Card(
              child: ListTile(
                title: Text(item['title']?.toString() ?? ''),
                subtitle: Text(
                  '${item['category'] ?? 'other'} '
                  '• ₹${item['price'] ?? 0}',
                ),
                trailing: ElevatedButton(
                  onPressed: loading || productId == null
                      ? null
                      : () => onRepublish(productId),
                  child: const Text('Republish'),
                ),
              ),
            );
          }),
      ],
    );
  }
}
