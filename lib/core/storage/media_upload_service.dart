import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:toukh_provider/core/media/picked_media.dart';
import 'package:toukh_provider/core/storage/backblaze_b2_client.dart';

/// Metadata returned after a successful image upload to Backblaze B2.
class UploadedMedia {
  const UploadedMedia({
    required this.url,
    required this.fileName,
    required this.fileId,
  });

  final String url;
  final String fileName;
  final String fileId;
}

/// Compresses images and uploads them to Backblaze B2.
///
/// Handles the "compress + upload + return URL" contract; callers (e.g. the
/// registration flow) are responsible for orchestrating multiple uploads and
/// rolling back on partial failure via [deleteImage].
class MediaUploadService {
  MediaUploadService(this._b2);

  final BackblazeB2Client _b2;

  /// Compresses [source] (JPEG, max long-edge 1600 px, quality 75) and uploads
  /// it to the configured B2 bucket as [objectPath] (forward-slash separated).
  Future<UploadedMedia> uploadImage({
    required PickedMedia source,
    required String objectPath,
  }) async {
    final bytes = await _compressToJpegBytes(source);
    if (kIsWeb) {
      return _uploadViaCallable(bytes: bytes, objectPath: objectPath);
    }
    final result = await _b2.uploadBytes(
      fileName: objectPath,
      bytes: bytes,
      contentType: 'image/jpeg',
    );
    return UploadedMedia(
      url: result.publicUrl,
      fileName: result.fileName,
      fileId: result.fileId,
    );
  }

  /// Best-effort delete; swallows errors so rollbacks never mask the original
  /// upload failure. Logs for visibility.
  Future<void> deleteImage(UploadedMedia media) async {
    try {
      if (kIsWeb) {
        await FirebaseFunctions.instanceFor(region: 'us-central1')
            .httpsCallable('deleteRegistrationMedia')
            .call({
          'fileName': media.fileName,
          'fileId': media.fileId,
        });
        return;
      }
      await _b2.deleteFileVersion(
        fileName: media.fileName,
        fileId: media.fileId,
      );
    } catch (e, st) {
      debugPrint('MediaUploadService.deleteImage failed: $e\n$st');
    }
  }

  Future<Uint8List> _compressToJpegBytes(PickedMedia source) async {
    final nativePath = source.filePath;
    if (!kIsWeb && nativePath != null) {
      try {
        final tmpDir = await getTemporaryDirectory();
        final target =
            '${tmpDir.path}/media_${DateTime.now().microsecondsSinceEpoch}.jpg';
        final result = await FlutterImageCompress.compressAndGetFile(
          nativePath,
          target,
          quality: 75,
          minWidth: 1600,
          minHeight: 1600,
          format: CompressFormat.jpeg,
        );
        if (result != null) {
          return result.readAsBytes();
        }
      } catch (e, st) {
        debugPrint('MediaUploadService compress fallback: $e\n$st');
      }
    }
    try {
      final compressed = await FlutterImageCompress.compressWithList(
        source.bytes,
        quality: 75,
        minWidth: 1600,
        minHeight: 1600,
        format: CompressFormat.jpeg,
      );
      if (compressed.isNotEmpty) return Uint8List.fromList(compressed);
    } catch (e, st) {
      debugPrint('MediaUploadService compressWithList fallback: $e\n$st');
    }
    return source.bytes;
  }

  /// Web cannot call Backblaze directly. The signed-in provider sends the
  /// photo to Cloud Functions, which writes it to B2.
  Future<UploadedMedia> _uploadViaCallable({
    required Uint8List bytes,
    required String objectPath,
  }) async {
    final result = await FirebaseFunctions.instanceFor(
      region: 'us-central1',
    ).httpsCallable('uploadRegistrationMedia').call({
      'objectPath': objectPath,
      'contentType': 'image/jpeg',
      'bytesBase64': base64Encode(bytes),
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    return UploadedMedia(
      url: data['url'] as String? ?? '',
      fileName: data['fileName'] as String? ?? objectPath,
      fileId: data['fileId'] as String? ?? '',
    );
  }
}
