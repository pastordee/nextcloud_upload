import '../network.dart';
import 'share.dart';

/// Client for creating and retrieving shares
class SharesClient {
  // ignore: public_member_api_docs
  SharesClient(
    String baseUrl,
    this._network,
  ) : _baseUrl = '$baseUrl/ocs/v2.php/apps/files_sharing/api/v1/';

  final String _baseUrl;
  final Network _network;

  String _getUrl(String path) {
    path = path.trim();
    if (path.startsWith('/')) {
      return _baseUrl + path.substring(1);
    }
    return [_baseUrl, path].join();
  }

  /// Get all shares, optionally filtered by [path].
  Future<List<Share>> getShares({
    String? path,
    bool reshares = false,
    bool subfiles = false,
  }) async {
    var url = _getUrl('/shares?reshares=$reshares&subfiles=$subfiles');
    if (path != null) {
      url += '&path=$path';
    }
    final response = await _network.send('GET', url, [200]);
    return sharesFromResponse(response.body);
  }

  /// Retrieve a share by [id].
  Future<Share> getShare(int id) async {
    final url = _getUrl('/shares/$id');
    final response = await _network.send('GET', url, [200]);
    return sharesFromResponse(response.body).single;
  }

  /// Delete a share by [id].
  Future deleteShare(int id) async {
    final url = _getUrl('/shares/$id');
    await _network.send('DELETE', url, [200]);
  }

  Future<Share> _createShare(
    String path,
    int shareType, {
    String? shareWith,
    bool publicUpload = false,
    String? password,
    Permissions? permissions,
  }) async {
    assert(
      (shareType != ShareTypes.user && shareType != ShareTypes.group) ||
          shareWith != null,
      "When the share type is 'user' or 'group' then shareWith must not be null",
    );
    if (shareType == ShareTypes.publicLink && permissions == null) {
      permissions = Permissions([Permission.read]);
    }
    permissions ??= Permissions([Permission.all]);
    var url = _getUrl(
      '/shares?path=$path&shareType=$shareType&publicUpload=$publicUpload&permissions=${permissions.toInt()}',
    );
    if (shareType == ShareTypes.user || shareType == ShareTypes.group) {
      url += '&shareWith=$shareWith';
    } else if (shareType == ShareTypes.publicLink && password != null) {
      url += '&password=$password';
    }
    final response = await _network.send('POST', url, [200]);
    return shareFromResponse(response.body);
  }

  /// Share [path] with a user. Returns the created [Share].
  Future<Share> shareWithUser(
    String path,
    String user, {
    Permissions? permissions,
    bool publicUpload = false,
  }) =>
      _createShare(
        path,
        ShareTypes.user,
        shareWith: user,
        permissions: permissions,
        publicUpload: publicUpload,
      );

  /// Share [path] with a group. Returns the created [Share].
  Future<Share> shareWithGroup(
    String path,
    String group, {
    Permissions? permissions,
    bool publicUpload = false,
  }) =>
      _createShare(
        path,
        ShareTypes.group,
        shareWith: group,
        permissions: permissions,
        publicUpload: publicUpload,
      );

  /// Create a public link share for [path]. Returns the created [Share].
  ///
  /// The public URL is available at [Share.url] and the share ID at [Share.id].
  Future<Share> shareWithPublicLink(
    String path, {
    Permissions? permissions,
    String? password,
    bool publicUpload = false,
  }) =>
      _createShare(
        path,
        ShareTypes.publicLink,
        password: password,
        permissions: permissions,
        publicUpload: publicUpload,
      );
}
