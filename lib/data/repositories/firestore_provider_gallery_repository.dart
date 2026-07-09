import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toukh_provider/core/storage/media_upload_service.dart';
import 'package:toukh_provider/domain/repositories/provider_gallery_repository.dart';
import 'package:toukh_ui/toukh_ui.dart';

class FirestoreProviderGalleryRepository implements ProviderGalleryRepository {
  FirestoreProviderGalleryRepository(
    this._firestore,
    this._media,
  );

  final FirebaseFirestore _firestore;
  final MediaUploadService _media;

  CollectionReference<Map<String, dynamic>> _galleryRef(String providerId) {
    return _firestore.collection('providers').doc(providerId).collection('gallery');
  }

  @override
  Stream<List<ProviderGalleryItem>> watchGallery(String providerId) {
    return _galleryRef(providerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs.map((d) {
        final data = d.data();
        final createdAt =
            ToukhFirestoreTimestamps.toDateTime(data['createdAt']) ??
            DateTime.now();
        return ProviderGalleryItem(
          id: d.id,
          url: data['url'] as String? ?? '',
          fileId: data['fileId'] as String? ?? '',
          fileName: data['fileName'] as String? ?? '',
          createdAt: createdAt,
        );
      }).where((i) => i.url.isNotEmpty).toList();
    });
  }

  @override
  Future<void> addImages(String providerId, List<File> files) async {
    if (files.isEmpty) return;
    final uploaded = <UploadedMedia>[];
    try {
      for (var i = 0; i < files.length; i++) {
        final name =
            'providers/$providerId/gallery/${DateTime.now().microsecondsSinceEpoch}_$i.jpg';
        final media = await _media.uploadImage(
          source: files[i],
          objectPath: name,
        );
        uploaded.add(media);
        await _galleryRef(providerId).add({
          'url': media.url,
          'fileId': media.fileId,
          'fileName': media.fileName,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      for (final m in uploaded) {
        await _media.deleteImage(m);
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteImage({
    required String providerId,
    required ProviderGalleryItem item,
  }) async {
    try {
      await _galleryRef(providerId).doc(item.id).delete();
    } finally {
      if (item.fileId.isNotEmpty && item.fileName.isNotEmpty) {
        await _media.deleteImage(
          UploadedMedia(
            url: item.url,
            fileName: item.fileName,
            fileId: item.fileId,
          ),
        );
      }
    }
  }
}

