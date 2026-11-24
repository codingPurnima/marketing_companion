import 'package:flutter/material.dart';
import '../../l10n/ui_text.dart';

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
        Text(
          UiText.get(context, 'archived'),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (products.isEmpty)
          Text(UiText.get(context, 'noArchived'))
        else
          ...products.map((product) {
            final item = Map<String, dynamic>.from(product as Map);
            final productId = item['id']?.toString();

            return Card(
              child: ListTile(
                title: Text(item['title']?.toString() ?? ''),
                subtitle: Text(
                  UiText.category(context, item['category']?.toString() ?? 'other')
                ),
                trailing: ElevatedButton(
                  onPressed: loading || productId == null
                      ? null
                      : () => onRepublish(productId),
                  child: Text(UiText.get(context, 'republish')),
                ),
              ),
            );
          }),
      ],
    );
  }
}
