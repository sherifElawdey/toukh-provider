import 'package:flutter/material.dart';

/// Soft rounded surface without outline borders (dashboard cards).
Decoration dashboardSoftDecoration(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return BoxDecoration(
    color: Theme.of(context).cardColor,
    border: Border.all(
      color: scheme.onSurface.withValues(alpha: 0.12),
      width: 0.6,
    ),
    borderRadius: BorderRadius.circular(16),
  );
}
