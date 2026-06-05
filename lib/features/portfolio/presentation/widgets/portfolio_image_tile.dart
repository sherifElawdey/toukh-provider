import 'dart:io';

import 'package:flutter/material.dart';
import 'package:toukh_ui/toukh_ui.dart';

class PortfolioImageTile extends StatelessWidget {
  const PortfolioImageTile({
    super.key,
    this.file,
    this.url,
    required this.onRemove,
  });

  final File? file;
  final String? url;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final imageWidget = file != null
        ? Image.file(file!, fit: BoxFit.cover)
        : (url != null
            ? Image.network(url!, fit: BoxFit.cover)
            : const SizedBox.shrink());

    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          child: imageWidget,
        ),
        Positioned(
          top: 4,
          right: 4,
          child: IconButton(
            style: IconButton.styleFrom(
              backgroundColor: Colors.black54,
            ),
            icon: Icon(ToukhIcons.close, color: Colors.white, size: 20),
            onPressed: onRemove,
          ),
        ),
      ],
    );
  }
}
