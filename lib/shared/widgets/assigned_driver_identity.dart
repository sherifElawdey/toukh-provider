import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../icons/toukh_icons.dart';
import '../theme/app_sizes.dart';
import '../widgets/custom_text.dart';
import '../orders/assigned_driver_fields.dart';

enum AssignedDriverIdentityVariant { compact, expanded }

/// Shared courier name / photo / phone for provider + customer order UIs.
class AssignedDriverIdentity extends StatelessWidget {
  const AssignedDriverIdentity({
    super.key,
    required this.fields,
    this.variant = AssignedDriverIdentityVariant.compact,
    this.eyebrow,
    this.fallbackName = 'Courier',
    this.showCallButton = true,
    this.padding,
    this.filled = false,
  });

  final AssignedDriverFields fields;
  final AssignedDriverIdentityVariant variant;
  final String? eyebrow;
  final String fallbackName;
  final bool showCallButton;
  final EdgeInsetsGeometry? padding;
  final bool filled;

  Future<void> _call(String raw) async {
    final cleaned = raw.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: cleaned);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!fields.hasAnyIdentity) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final name = (fields.name?.trim().isNotEmpty == true)
        ? fields.name!.trim()
        : fallbackName;
    final photo = fields.photoUrl?.trim();
    final phone = fields.phone?.trim();
    final hasPhone = phone != null && phone.isNotEmpty;
    final isExpanded = variant == AssignedDriverIdentityVariant.expanded;
    final radius = isExpanded ? 22.0 : 16.0;

    final row = Row(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: scheme.primaryContainer,
          backgroundImage:
              photo != null && photo.isNotEmpty ? NetworkImage(photo) : null,
          child: photo == null || photo.isEmpty
              ? Icon(
                  ToukhIcons.profile,
                  size: isExpanded ? 22 : 18,
                  color: scheme.primary,
                )
              : null,
        ),
        SizedBox(width: isExpanded ? 12 : 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null && eyebrow!.trim().isNotEmpty) ...[
                CustomText(
                  eyebrow!,
                  style: t.labelMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ],
              CustomText(
                name,
                style: (isExpanded ? t.titleSmall : t.bodyMedium)?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (hasPhone) ...[
                const SizedBox(height: 2),
                CustomText(
                  phone,
                  style: t.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.75),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        if (showCallButton && hasPhone)
          IconButton(
            onPressed: () => _call(phone),
            icon: Icon(ToukhIcons.phone, color: scheme.primary),
            visualDensity: VisualDensity.compact,
            tooltip: phone,
          ),
      ],
    );

    if (!filled && !isExpanded) {
      return Padding(
        padding: padding ?? EdgeInsets.zero,
        child: row,
      );
    }

    return Container(
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: AppSizes.spaceMd,
            vertical: AppSizes.spaceSm,
          ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(isExpanded ? 16 : 12),
      ),
      child: row,
    );
  }
}
