import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:toukh_provider/core/storage/backblaze_b2_config.dart';

/// Result of a successful upload to Backblaze B2.
class B2UploadResult {
  const B2UploadResult({
    required this.fileId,
    required this.fileName,
    required this.contentSha1,
    required this.publicUrl,
  });

  final String fileId;
  final String fileName;
  final String contentSha1;

  /// URL usable by the mobile client / customer apps to fetch the file.
  ///
  /// Valid as-is only when the target bucket is *public*. If the bucket is
  /// private, pair with `b2_get_download_authorization` to attach a token.
  final String publicUrl;
}

/// Thrown when B2 rejects a request with a non-2xx status.
class B2Exception implements Exception {
  B2Exception(this.operation, this.statusCode, this.body);

  final String operation;
  final int statusCode;
  final String body;

  @override
  String toString() => 'B2Exception($operation $statusCode): $body';
}

class _B2Auth {
  _B2Auth({
    required this.apiUrl,
    required this.downloadUrl,
    required this.authorizationToken,
    required this.accountId,
  });

  final String apiUrl;
  final String downloadUrl;
  final String authorizationToken;
  final String accountId;
}

class _B2UploadTarget {
  _B2UploadTarget({required this.uploadUrl, required this.authorizationToken});

  final String uploadUrl;
  final String authorizationToken;
}

/// Thin HTTP client for the Backblaze B2 native v4 API.
///
/// Only implements the calls needed by the app (authorize, list bucket,
/// get upload url, upload file, delete file version).
class BackblazeB2Client {
  BackblazeB2Client({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final http.Client _http;

  _B2Auth? _auth;
  String? _bucketId;
  _B2UploadTarget? _uploadTarget;

  String get bucketName => BackblazeB2Config.bucketName;

  Future<_B2Auth> _authorize({bool force = false}) async {
    if (!force && _auth != null) return _auth!;
    final creds = base64Encode(
      utf8.encode('${BackblazeB2Config.keyId}:${BackblazeB2Config.applicationKey}'),
    );
    final res = await _http.get(
      Uri.parse('${BackblazeB2Config.authorizeBaseUrl}/b2api/v4/b2_authorize_account'),
      headers: {'Authorization': 'Basic $creds'},
    );
    if (res.statusCode ~/ 100 != 2) {
      throw B2Exception('authorize', res.statusCode, res.body);
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    // v4 nests connection info under "apiInfo" / "storageApi".
    final storage = (body['apiInfo'] as Map<String, dynamic>?)
            ?['storageApi'] as Map<String, dynamic>? ??
        body;
    final auth = _B2Auth(
      apiUrl: (storage['apiUrl'] ?? body['apiUrl']) as String,
      downloadUrl: (storage['downloadUrl'] ?? body['downloadUrl']) as String,
      authorizationToken: body['authorizationToken'] as String,
      accountId: (body['accountId'] ?? storage['accountId']) as String,
    );
    _auth = auth;
    _bucketId = null;
    _uploadTarget = null;
    return auth;
  }

  Future<String> _resolveBucketId(_B2Auth auth) async {
    if (_bucketId != null) return _bucketId!;
    final res = await _http.post(
      Uri.parse('${auth.apiUrl}/b2api/v4/b2_list_buckets'),
      headers: {
        'Authorization': auth.authorizationToken,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'accountId': auth.accountId,
        'bucketName': bucketName,
      }),
    );
    if (res.statusCode ~/ 100 != 2) {
      throw B2Exception('list_buckets', res.statusCode, res.body);
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final buckets = (body['buckets'] as List).cast<Map<String, dynamic>>();
    if (buckets.isEmpty) {
      throw B2Exception(
        'list_buckets',
        404,
        'Bucket "$bucketName" not found on the account.',
      );
    }
    final id = buckets.first['bucketId'] as String;
    _bucketId = id;
    return id;
  }

  Future<_B2UploadTarget> _resolveUploadTarget(_B2Auth auth) async {
    if (_uploadTarget != null) return _uploadTarget!;
    final bucketId = await _resolveBucketId(auth);
    final res = await _http.post(
      Uri.parse('${auth.apiUrl}/b2api/v4/b2_get_upload_url'),
      headers: {
        'Authorization': auth.authorizationToken,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'bucketId': bucketId}),
    );
    if (res.statusCode ~/ 100 != 2) {
      throw B2Exception('get_upload_url', res.statusCode, res.body);
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final target = _B2UploadTarget(
      uploadUrl: body['uploadUrl'] as String,
      authorizationToken: body['authorizationToken'] as String,
    );
    _uploadTarget = target;
    return target;
  }

  /// Percent-encode a file name per B2 rules (spec: "URL Encoding").
  String _encodeFileName(String fileName) {
    // B2 accepts most printable ASCII; encode the unsafe set.
    return fileName
        .split('/')
        .map(Uri.encodeComponent)
        .join('/');
  }

  /// Uploads [bytes] under [fileName] (forward-slash separated object path).
  ///
  /// Retries once on transient errors (401/408/429/5xx) after re-authorizing
  /// and refetching an upload URL.
  Future<B2UploadResult> uploadBytes({
    required String fileName,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final sha1Hex = sha1.convert(bytes).toString();

    Future<B2UploadResult> attempt() async {
      final auth = await _authorize();
      final target = await _resolveUploadTarget(auth);
      final res = await _http.post(
        Uri.parse(target.uploadUrl),
        headers: {
          'Authorization': target.authorizationToken,
          'X-Bz-File-Name': _encodeFileName(fileName),
          'Content-Type': contentType,
          'Content-Length': bytes.length.toString(),
          'X-Bz-Content-Sha1': sha1Hex,
        },
        body: bytes,
      );
      if (res.statusCode ~/ 100 != 2) {
        throw B2Exception('upload', res.statusCode, res.body);
      }
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return B2UploadResult(
        fileId: body['fileId'] as String,
        fileName: body['fileName'] as String? ?? fileName,
        contentSha1: body['contentSha1'] as String? ?? sha1Hex,
        publicUrl: _publicUrlFor(auth, fileName),
      );
    }

    try {
      return await attempt();
    } on B2Exception catch (e) {
      if (!_isTransient(e.statusCode)) rethrow;
      debugPrint('B2 upload transient failure ${e.statusCode}; retrying once.');
      _uploadTarget = null;
      _auth = null;
      return attempt();
    }
  }

  /// Deletes a specific version of a file.
  Future<void> deleteFileVersion({
    required String fileName,
    required String fileId,
  }) async {
    Future<void> attempt() async {
      final auth = await _authorize();
      final res = await _http.post(
        Uri.parse('${auth.apiUrl}/b2api/v4/b2_delete_file_version'),
        headers: {
          'Authorization': auth.authorizationToken,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'fileName': fileName, 'fileId': fileId}),
      );
      if (res.statusCode ~/ 100 != 2) {
        throw B2Exception('delete', res.statusCode, res.body);
      }
    }

    try {
      await attempt();
    } on B2Exception catch (e) {
      if (!_isTransient(e.statusCode)) rethrow;
      debugPrint('B2 delete transient failure ${e.statusCode}; retrying once.');
      _auth = null;
      await attempt();
    }
  }

  String publicUrlFor(String fileName) {
    final auth = _auth;
    if (auth == null) {
      // Without an auth cycle we can still build a well-formed URL using the
      // canonical f000 host; B2 will redirect to the correct cluster.
      return 'https://f000.backblazeb2.com/file/$bucketName/${_encodeFileName(fileName)}';
    }
    return _publicUrlFor(auth, fileName);
  }

  String _publicUrlFor(_B2Auth auth, String fileName) {
    return '${auth.downloadUrl}/file/$bucketName/${_encodeFileName(fileName)}';
  }

  bool _isTransient(int code) =>
      code == 401 || code == 408 || code == 429 || (code >= 500 && code < 600);

  void close() => _http.close();
}
