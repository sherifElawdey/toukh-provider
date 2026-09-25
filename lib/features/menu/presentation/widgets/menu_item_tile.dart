import 'package:flutter/material.dart';
import 'package:toukh_provider/domain/entities/menu_item.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Professional menu item row for the provider menu builder.
class MenuItemTile extends StatelessWidget {
  const MenuItemTile({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDelete,
    this.showDivider = true,
  });

  final MenuItemEntity item;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool showDivider;

  static const double _thumbSize = 88;

  double? get _fromPrice {
    if (item.sizes.isEmpty) return null;
    return item.sizes
        .map((s) => item.effectivePriceFor(s))
        .reduce((a, b) => a < b ? a : b);
  }

  double? get _fromOriginal {
    if (item.sizes.isEmpty) return null;
    return item.sizes.map((s) => s.priceEgp).reduce((a, b) => a < b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final desc = item.description?.trim();
    final url = item.imageUrl?.trim();
    final from = _fromPrice;
    final original = _fromOriginal;
    final multiSize = item.sizes.length > 1;
    final dimmed = !item.isAvailable;

    return Opacity(
      opacity: dimmed ? 0.55 : 1,
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      child: SizedBox(
                        width: _thumbSize,
                        height: _thumbSize,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            url != null && url.isNotEmpty
                                ? HavitNetworkImage(
                                    imageUrl: url,
                                    fit: BoxFit.cover,
                                  )
                                : ColoredBox(
                                    color: AppColors.appColor
                                        .withValues(alpha: 0.08),
                                    child: Icon(
                                      ToukhIcons.restaurant,
                                      size: 28,
                                      color: AppColors.secondColor
                                          .withValues(alpha: 0.4),
                                    ),
                                  ),
                            if (item.hasOffer)
                              Positioned(
                                top: 6,
                                left: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    menuItemOfferBadgeLabel(
                                      offerType: item.offerType,
                                      discountPercent: item.discountPercent,
                                    ),
                                    style: t.labelSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: AppSizes.spaceMd),
                    Expanded(
                      child: SizedBox(
                        height: _thumbSize,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: CustomText(
                                    item.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: t.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      height: 1.25,
                                      fontFamily: AppFonts.family,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                  tooltip: 'Delete',
                                  icon: Icon(
                                    ToukhIcons.delete,
                                    size: 18,
                                    color:
                                        scheme.error.withValues(alpha: 0.75),
                                  ),
                                  onPressed: onDelete,
                                ),
                              ],
                            ),
                            if (!item.isAvailable)
                              CustomText(
                                'Unavailable',
                                style: t.labelSmall?.copyWith(
                                  color: scheme.error,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            if (desc != null && desc.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              CustomText(
                                desc,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: t.bodySmall?.copyWith(
                                  color: scheme.onSurface
                                      .withValues(alpha: 0.58),
                                  height: 1.3,
                                ),
                              ),
                            ],
                            const Spacer(),
                            Row(
                              children: [
                                if (from != null) ...[
                                  CustomText(
                                    multiSize
                                        ? 'from EGP ${from.toStringAsFixed(0)}'
                                        : 'EGP ${from.toStringAsFixed(0)}',
                                    style: t.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.secondColor,
                                    ),
                                  ),
                                  if (item.hasOffer &&
                                      original != null &&
                                      original > from) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      'EGP ${original.toStringAsFixed(0)}',
                                      style: t.labelSmall?.copyWith(
                                        decoration: TextDecoration.lineThrough,
                                        color: scheme.onSurface
                                            .withValues(alpha: 0.45),
                                      ),
                                    ),
                                  ],
                                ],
                                if (item.sizes.length > 1) ...[
                                  const SizedBox(width: 8),
                                  CustomText(
                                    '${item.sizes.length} sizes',
                                    style: t.labelSmall?.copyWith(
                                      color: scheme.onSurface
                                          .withValues(alpha: 0.45),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                                const Spacer(),
                                Icon(
                                  PhosphorIconsRegular.caretRight,
                                  size: 16,
                                  color:
                                      scheme.onSurface.withValues(alpha: 0.3),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (showDivider)
            Divider(
              height: 1,
              thickness: 0.6,
              color: AppColors.borderSubtle,
            ),
        ],
      ),
    );
  }
}
