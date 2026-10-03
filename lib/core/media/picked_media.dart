import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// A photo chosen on the phone or in the browser.
///
/// Bytes are always loaded so web can preview and upload without `dart:io`.
class PickedMedia {
  const PickedMedia({
    required this.bytes,
    required this.name,
    this.filePath,
  });

  final Uint8List bytes;
  final String name;

  /// Filesystem path on iOS and Android. Null on web.
  final String? filePath;

  String get path => filePath ?? name;

  ImageProvider get imageProvider => MemoryImage(bytes);
}
