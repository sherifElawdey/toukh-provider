import 'package:toukh_provider/core/media/picked_media.dart';
import 'package:toukh_provider/domain/entities/menu_item.dart';

class MenuItemEditorResult {
  const MenuItemEditorResult({
    required this.entity,
    this.newImageFile,
    this.clearImage = false,
  });

  final MenuItemEntity entity;
  final PickedMedia? newImageFile;
  final bool clearImage;
}
