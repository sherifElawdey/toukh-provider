import 'package:toukh_provider/core/media/picked_media.dart';

/// Firestore-backed gallery image for a provider.
class ProviderGalleryItem {
  const ProviderGalleryItem({
    required this.id,
    required this.url,
    required this.fileId,
    required this.fileName,
    required this.createdAt,
    this.isOffer = false,
    this.caption,
  });

  final String id;
  final String url;
  final String fileId;
  final String fileName;
  final DateTime createdAt;

  /// Shown to customers as an offer they can request (pharmacies).
  final bool isOffer;

  /// Optional short text shown with the image, e.g. "20% off vitamins".
  final String? caption;
}

abstract class ProviderGalleryRepository {
  Stream<List<ProviderGalleryItem>> watchGallery(String providerId);

  /// Uploads [files] and creates gallery documents for [providerId].
  Future<void> addImages(String providerId, List<PickedMedia> files);

  /// Marks [itemId] as an offer image (or not) and sets its caption.
  Future<void> updateImage({
    required String providerId,
    required String itemId,
    required bool isOffer,
    String? caption,
  });

  /// Deletes a gallery image doc and best-effort B2 object removal.
  Future<void> deleteImage({
    required String providerId,
    required ProviderGalleryItem item,
  });
}

