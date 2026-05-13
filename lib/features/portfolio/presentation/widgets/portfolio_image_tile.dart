import 'dart:io';

import 'package:flutter/material.dart';
import 'package:toukh_ui/toukh_ui.dart';

class PortfolioImageTile extends StatelessWidget {
  const PortfolioImageTile({
    super.key,
    required this.file,
    required this.onRemove,
  });

  final File file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          child: Image.file(file, fit: BoxFit.cover),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: IconButton(
            style: IconButton.styleFrom(
              backgroundColor: Colors.black54,
            ),
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
            onPressed: onRemove,
          ),
        ),
      ],
    );
  }
}
