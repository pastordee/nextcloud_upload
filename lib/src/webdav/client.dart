import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../network.dart';

/// WebDAV client scoped to upload and directory creation only.
class WebDavClient {
  // ignore: public_member_api_docs
  WebDavClient(String baseUrl, this._network, this._username)
      : _davUrl = '$baseUrl/remote.php/dav';

  final String _username;
  final String _davUrl;
  final Network _network;

  Future<String> _getUrl(String path) async {
    path = path.trim();
    if (path.startsWith('/')) {
      path = path.substring(1);
    }
    return '$_davUrl/files/$_username/$path';
  }

  Future<http.Response> _send(
    String method,
    String url,
    List<int> expectedCodes, {
    Uint8List? data,
    Map<String, String>? headers,
    ProgressCallback? onUploadProgress,
  }) {
    headers = headers ?? {};
    headers[HttpHeaders.contentTypeHeader] = ContentType.xml.value;
    return _network.send(
      method,
      url,
      expectedCodes,
      data: data,
      headers: headers,
      onUploadProgress: onUploadProgress,
    );
  }

  /// Create a directory at [path]. Safe mode (default) ignores 301/405 responses.
  Future<http.Response> mkdir(String path, [bool safe = true]) async {
    final expectedCodes = [
      201,
      if (safe) ...[301, 405],
    ];
    return _send('MKCOL', await _getUrl(path), expectedCodes);
  }

  /// Recursively create all directories in [path], like `mkdir -p`.
  Future mkdirs(String path) async {
    path = path.trim();
    final dirs = path.split('/')..removeWhere((value) => value == '');
    if (dirs.isEmpty) return;

    String currentPath = '';
    for (final dir in dirs) {
      currentPath = currentPath.isEmpty ? dir : '$currentPath/$dir';
      try {
        await mkdir(currentPath);
      } catch (e) {
        if (!e.toString().contains('405') &&
            !e.toString().contains('already exists') &&
            !e.toString().contains('Method Not Allowed')) {
          rethrow;
        }
      }
    }
  }

  /// Upload [localData] to [remotePath].
  ///
  /// [onUploadProgress] reports bytes sent and total bytes during the upload.
  Future upload(
    Uint8List localData,
    String remotePath, {
    ProgressCallback? onUploadProgress,
  }) async =>
      _send(
        'PUT',
        await _getUrl(remotePath),
        [200, 201, 204],
        data: localData,
        onUploadProgress: onUploadProgress,
      );
}
