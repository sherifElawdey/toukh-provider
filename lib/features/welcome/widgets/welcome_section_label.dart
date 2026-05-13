import 'package:flutter/material.dart';

class WelcomeSectionLabel extends StatelessWidget {
  const WelcomeSectionLabel({
    super.key,
    required this.label,
    required this.scheme,
  });

  final String label;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: scheme.onSurface.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}
