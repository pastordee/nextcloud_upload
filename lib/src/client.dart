import 'network.dart';
import 'shares/client.dart';
import 'webdav/client.dart';

/// Minimal Nextcloud client for file upload and share creation.
class NextcloudUploadClient {
  // ignore: public_member_api_docs
  NextcloudUploadClient(
    Uri host,
    NextCloudHttpClient httpClient,
    String username,
  ) {
    if (host.scheme.isEmpty) {
      host = Uri.https(host.authority, Uri.decodeComponent(host.path));
    }

    baseUrl = host.toString();

    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }

    final network = Network(httpClient);

    _webDavClient = WebDavClient(baseUrl, network, username);
    _sharesClient = SharesClient(baseUrl, network);
  }

  /// Constructs a client using Basic auth (username + password).
  factory NextcloudUploadClient.withCredentials(
    Uri host,
    String username,
    String password, {
    Map<String, String>? defaultHeaders,
  }) =>
      NextcloudUploadClient(
        host,
        NextCloudHttpClient.withCredentials(
          username,
          password,
          defaultHeaders: defaultHeaders,
        ),
        username,
      );

  /// Constructs a client using a Bearer app password.
  ///
  /// [username] is still required to build the WebDAV file path.
  factory NextcloudUploadClient.withAppPassword(
    Uri host,
    String username,
    String appPassword, {
    Map<String, String>? defaultHeaders,
  }) =>
      NextcloudUploadClient(
        host,
        NextCloudHttpClient.withAppPassword(
          appPassword,
          defaultHeaders: defaultHeaders,
        ),
        username,
      );

  /// The base URL of the Nextcloud server
  late String baseUrl;

  late WebDavClient _webDavClient;
  late SharesClient _sharesClient;

  // ignore: public_member_api_docs
  WebDavClient get webDav => _webDavClient;

  // ignore: public_member_api_docs
  SharesClient get shares => _sharesClient;
}
