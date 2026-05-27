import 'dart:io';

/// Firestore-backed gallery image for a provider.
class ProviderGalleryItem {
  const ProviderGalleryItem({
    required this.id,
    required this.url,
    required this.fileId,
    required this.fileName,
    required this.createdAt,
  });

  final String id;
  final String url;
  final String fileId;
  final String fileName;
  final DateTime createdAt;
}

abstract class ProviderGalleryRepository {
  Stream<List<ProviderGalleryItem>> watchGallery(String providerId);

  /// Uploads [files] and creates gallery documents for [providerId].
  Future<void> addImages(String providerId, List<File> files);

  /// Deletes a gallery image doc and best-effort B2 object removal.
  Future<void> deleteImage({
    required String providerId,
    required ProviderGalleryItem item,
  });
}

