import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Three equal mini cards: black points, commitment %, avg accept time.
class ReputationMiniCardsRow extends StatelessWidget {
  const ReputationMiniCardsRow({
    super.key,
    required this.blackPointsTotal,
    required this.commitmentPercent,
    required this.avgAcceptSeconds,
  });

  final int blackPointsTotal;
  final int? commitmentPercent;
  final double? avgAcceptSeconds;

  String _formatAvg() {
    final seconds = avgAcceptSeconds;
    if (seconds == null || seconds <= 0) return '—';
    final s = seconds.round();
    if (s < 60) return '${s}s';
    final m = s ~/ 60;
    final rem = s % 60;
    if (rem == 0) return '${m}m';
    return '${m}m ${rem}s';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniCard(
            label: AppStrings.Settings.blackPoints.tr,
            value: '$blackPointsTotal',
          ),
        ),
        const SizedBox(width: AppSizes.spaceSm),
        Expanded(
          child: _MiniCard(
            label: AppStrings.Settings.commitmentPercent.tr,
            value: commitmentPercent == null ? '—' : '$commitmentPercent%',
          ),
        ),
        const SizedBox(width: AppSizes.spaceSm),
        Expanded(
          child: _MiniCard(
            label: AppStrings.Settings.avgAcceptTime.tr,
            value: _formatAvg(),
          ),
        ),
      ],
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spaceSm,
        vertical: AppSizes.spaceMd,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: AppColors.borderSubtle.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.family,
              fontSize: AppSizes.fontLabel - 1,
              color: AppColors.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppFonts.family,
              fontSize: AppSizes.fontTitle,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
