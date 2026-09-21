import 'package:flutter/material.dart';

import '../icons/toukh_icons.dart';
import '../theme/app_sizes.dart';
import '../widgets/custom_text.dart';
import 'toukh_notification.dart';
import 'toukh_notification_category.dart';
import 'toukh_notification_style.dart';

class ToukhNotificationListTile extends StatelessWidget {
  const ToukhNotificationListTile({
    super.key,
    required this.notification,
    required this.onTap,
    this.subtitle,
    this.statusChipLabel,
    this.categoryLabel,
    this.onDelete,
  });

  final ToukhNotification notification;
  final VoidCallback onTap;
  final String? subtitle;

  /// Localized order status chip (e.g. "Preparing"). Falls back to English.
  final String? statusChipLabel;

  /// Localized category label for non-order notifications.
  final String? categoryLabel;

  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final timeText = subtitle ?? _formatTime(notification.createdAt);
    final style = ToukhNotificationStyleResolver.resolve(notification);
    final showOrderChip =
        notification.category.trim().toLowerCase() ==
            ToukhNotificationCategory.order &&
        style.statusChipKey != null;
    final chipText = showOrderChip
        ? (statusChipLabel ??
            ToukhNotificationStyleResolver.statusChipFallback(
              style.statusChipKey,
            ))
        : null;
    final nonOrderCategory = notification.category.trim().toLowerCase() !=
            ToukhNotificationCategory.order
        ? (categoryLabel ??
            ToukhNotificationStyleResolver.categoryFallback(
              notification.category,
            ))
        : null;
    final chipLabel = chipText ?? nonOrderCategory;

    return Material(
      color: notification.isUnread
          ? style.accentColor.withValues(alpha: 0.08)
          : scheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LeadingIcon(
              imageUrl: notification.imageUrl,
              icon: style.icon,
              accentColor: style.accentColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          CustomText(
                            notification.title,
                            style: TextStyle(
                              fontWeight: notification.isUnread
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              fontSize: AppSizes.fontBody,
                              color: scheme.onSurface,
                            ),
                          ),
                          if (chipLabel != null && chipLabel.isNotEmpty)
                            _StatusChip(
                              label: chipLabel,
                              color: style.accentColor,
                            ),
                          if (notification.isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: style.accentColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      if (timeText.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        CustomText(
                          timeText,
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurface.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      CustomText(
                        notification.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurface.withValues(alpha: 0.65),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (onDelete != null)
              IconButton(
                icon: Icon(
                  ToukhIcons.close,
                  size: 18,
                  color: scheme.onSurface.withValues(alpha: 0.45),
                ),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                onPressed: onDelete,
                tooltip: 'Delete',
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: CustomText(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          height: 1.1,
        ),
      ),
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon({
    this.imageUrl,
    required this.icon,
    required this.accentColor,
  });

  final String? imageUrl;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          imageUrl!,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _iconPlaceholder(),
        ),
      );
    }
    return _iconPlaceholder();
  }

  Widget _iconPlaceholder() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: accentColor, size: 24),
    );
  }
}
