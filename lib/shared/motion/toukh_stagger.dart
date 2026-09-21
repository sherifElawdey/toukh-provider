import 'package:flutter/material.dart';

import 'toukh_fade_slide.dart';
import 'toukh_motion.dart';

/// Staggered fade/slide entrance for a list of children.
class ToukhStagger extends StatelessWidget {
  const ToukhStagger({
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.direction = Axis.vertical,
    this.spacing = 0,
    super.key,
  });

  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;
  final Axis direction;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      final delay = ToukhMotion.staggerDelay +
          ToukhMotion.staggerStep * i;
      items.add(
        ToukhFadeSlide(
          delay: delay,
          child: children[i],
        ),
      );
      if (spacing > 0 && i < children.length - 1) {
        items.add(
          direction == Axis.vertical
              ? SizedBox(height: spacing)
              : SizedBox(width: spacing),
        );
      }
    }

    return direction == Axis.vertical
        ? Column(
            crossAxisAlignment: crossAxisAlignment,
            mainAxisAlignment: mainAxisAlignment,
            children: items,
          )
        : Row(
            crossAxisAlignment: crossAxisAlignment,
            mainAxisAlignment: mainAxisAlignment,
            children: items,
          );
  }
}
