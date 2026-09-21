import 'package:flutter/material.dart';
import 'package:toukh_provider/shared/theme/app_colors.dart';

/// Brand-styled pull-to-refresh wrapper.
///
/// Wrap a **scrollable** child ([ListView], [CustomScrollView],
/// [SingleChildScrollView], [GridView], …). For empty/short content, set
/// `physics: const AlwaysScrollableScrollPhysics()` on that scrollable so
/// the indicator can appear.
class ToukhRefresh extends StatelessWidget {
  const ToukhRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.displacement = 40,
    this.edgeOffset = 0,
    this.notificationPredicate = defaultScrollNotificationPredicate,
  });

  final RefreshCallback onRefresh;
  final Widget child;
  final double displacement;
  final double edgeOffset;
  final ScrollNotificationPredicate notificationPredicate;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.appColor,
      displacement: displacement,
      edgeOffset: edgeOffset,
      notificationPredicate: notificationPredicate,
      onRefresh: onRefresh,
      child: child,
    );
  }
}
