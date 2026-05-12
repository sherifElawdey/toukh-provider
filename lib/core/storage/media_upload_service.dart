import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
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
    required File source,
    required String objectPath,
  }) async {
    final bytes = await _compressToJpegBytes(source);
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
      await _b2.deleteFileVersion(
        fileName: media.fileName,
        fileId: media.fileId,
      );
    } catch (e, st) {
      debugPrint('MediaUploadService.deleteImage failed: $e\n$st');
    }
  }

  Future<Uint8List> _compressToJpegBytes(File source) async {
    try {
      final tmpDir = await getTemporaryDirectory();
      final target =
          '${tmpDir.path}/media_${DateTime.now().microsecondsSinceEpoch}.jpg';
      final result = await FlutterImageCompress.compressAndGetFile(
        source.absolute.path,
        target,
        quality: 75,
        minWidth: 1600,
        minHeight: 1600,
        format: CompressFormat.jpeg,
      );
      if (result != null) {
        return File(result.path).readAsBytes();
      }
    } catch (e, st) {
      debugPrint('MediaUploadService compress fallback: $e\n$st');
    }
    return source.readAsBytes();
  }
}
