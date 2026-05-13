import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:toukh_provider/domain/entities/provider_review_summary.dart';
import 'package:toukh_provider/features/home/presentation/widgets/dashboard_shell.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class HomeDashboardReviewsSection extends StatelessWidget {
  const HomeDashboardReviewsSection({super.key, required this.reviews});

  final List<ProviderReviewSummary> reviews;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateFmt = DateFormat.yMMMd(locale);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomText(
          AppStrings.Home.dashboardReviewsTitle.tr,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: AppSizes.fontTitle,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSizes.spaceMd),
        if (reviews.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.spaceSm),
            child: CustomText(
              AppStrings.Home.dashboardReviewsEmpty.tr,
              style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.55)),
            ),
          )
        else
          ...reviews.map((r) {
            final initial =
                (r.authorName?.trim().isNotEmpty ?? false) ? r.authorName!.trim()[0].toUpperCase() : '?';
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                decoration: dashboardSoftDecoration(context),
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: scheme.primary.withValues(alpha: 0.18),
                      foregroundColor: scheme.primary,
                      child: CustomText(initial, style: const TextStyle(fontWeight: FontWeight.w800)),
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
                                  r.authorName ?? '—',
                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(
                                  5,
                                  (i) => Icon(
                                    i < r.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                    size: 16,
                                    color: AppColors.appColor.withValues(alpha: i < r.rating ? 1 : 0.28),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (r.createdAt != null) ...[
                            const SizedBox(height: 4),
                            CustomText(
                              dateFmt.format(r.createdAt!),
                              style: TextStyle(
                                fontSize: 12,
                                color: scheme.onSurface.withValues(alpha: 0.48),
                              ),
                            ),
                          ],
                          if ((r.comment ?? '').trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            CustomText(
                              r.comment!.trim(),
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
              ),
            );
          }),
      ],
    );
  }
}
