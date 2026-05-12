import 'dart:io';

import 'package:toukh_provider/domain/entities/menu_item.dart';

class MenuItemEditorResult {
  const MenuItemEditorResult({
    required this.entity,
    this.newImageFile,
    this.clearImage = false,
  });

  final MenuItemEntity entity;
  final File? newImageFile;
  final bool clearImage;
}
