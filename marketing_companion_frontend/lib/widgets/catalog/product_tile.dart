import 'package:flutter/material.dart';

class ProductTile extends StatelessWidget {
  final String title;
  final String category;
  final String? price;
  final String status;
  final String? imageUrl;
  final bool highlighted;
  final VoidCallback? onTap;
  final Widget? trailing;
  final String? actionLabel;
  final VoidCallback? onAction;

  const ProductTile({
    super.key,
    required this.title,
    required this.category,
    required this.price,
    required this.status,
    required this.imageUrl,
    this.highlighted = false,
    this.onTap,
    this.trailing,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final statusDetails = switch (status) {
      'published' => (
        label: 'Published',
        background: colors.primaryContainer,
        foreground: colors.onPrimaryContainer,
      ),
      'archived' => (
        label: 'Archived',
        background: colors.surfaceContainerHighest,
        foreground: colors.onSurfaceVariant,
      ),
      _ => (
        label: 'Draft',
        background: colors.secondaryContainer,
        foreground: colors.onSecondaryContainer,
      ),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlighted ? colors.primary : colors.outlineVariant,
          width: highlighted ? 2 : 1,
        ),
        boxShadow: highlighted
            ? [
                BoxShadow(
                  color: colors.primary.withOpacity(0.14),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: highlighted
            ? colors.primaryContainer.withOpacity(0.18)
            : colors.surface,
        borderRadius: BorderRadius.circular(15),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildImage(context),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              price == null || price!.isEmpty
                                  ? 'Price not set'
                                  : '₹$price',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusDetails.background,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              statusDetails.label,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: statusDetails.foreground,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing!,
                ] else if (onAction != null)
                  PopupMenuButton<String>(
                    tooltip: 'Product actions',
                    enabled: onAction != null,
                    icon: Icon(Icons.more_vert, color: colors.onSurfaceVariant),
                    onSelected: (value) {
                      if (value == 'action') {
                        onAction?.call();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem<String>(
                        value: 'action',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              size: 20,
                              color: colors.onSurface,
                            ),
                            const SizedBox(width: 12),
                            Text(actionLabel ?? 'Action'),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 76,
        height: 76,
        child: imageUrl == null || imageUrl!.isEmpty
            ? _placeholder(colors)
            : Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(colors),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;

                  return Container(
                    color: colors.surfaceContainerHighest,
                    alignment: Alignment.center,
                    child: const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _placeholder(ColorScheme colors) {
    return Container(
      color: colors.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_outlined,
        size: 28,
        color: colors.onSurfaceVariant,
      ),
    );
  }
}
