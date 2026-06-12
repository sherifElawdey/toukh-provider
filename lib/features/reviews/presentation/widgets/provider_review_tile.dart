import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:toukh_provider/domain/entities/provider_review_summary.dart';
import 'package:toukh_provider/features/home/presentation/widgets/dashboard_shell.dart';
import 'package:toukh_ui/toukh_ui.dart';

class ProviderReviewTile extends StatelessWidget {
  const ProviderReviewTile({super.key, required this.review});

  final ProviderReviewSummary review;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateFmt = DateFormat.yMMMd(locale);
    final initial = (review.authorName?.trim().isNotEmpty ?? false)
        ? review.authorName!.trim()[0].toUpperCase()
        : '?';

    return Container(
      decoration: dashboardSoftDecoration(context),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: scheme.primary.withValues(alpha: 0.18),
            foregroundColor: scheme.primary,
            child: CustomText(
              initial,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: CustomText(
                        review.authorName ?? '—',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < review.rating
                              ? ToukhIcons.starFilled
                              : ToukhIcons.star,
                          size: 16,
                          color: AppColors.appColor.withValues(
                            alpha: i < review.rating ? 1 : 0.28,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (review.createdAt != null) ...[
                  const SizedBox(height: 4),
                  CustomText(
                    dateFmt.format(review.createdAt!),
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurface.withValues(alpha: 0.48),
                    ),
                  ),
                ],
                if ((review.comment ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  CustomText(
                    review.comment!.trim(),
                    style: TextStyle(
                      height: 1.35,
                      color: scheme.onSurface.withValues(alpha: 0.78),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
