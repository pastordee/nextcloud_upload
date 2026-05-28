import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'http_client/http_client.dart';

/// Callback function for tracking upload progress
typedef ProgressCallback = void Function(int bytesSent, int totalBytes);

// ignore: public_member_api_docs, avoid_classes_with_only_static_members
class HttpHeaders {
  // ignore: public_member_api_docs
  static String authorizationHeader = 'authorization';

  // ignore: public_member_api_docs
  static String acceptHeader = 'accept';

  // ignore: public_member_api_docs
  static String contentTypeHeader = 'content-type';

  // ignore: public_member_api_docs
  static String userAgentHeader = 'user-agent';
}

// ignore: public_member_api_docs, avoid_classes_with_only_static_members
class ContentType {
  // ignore: public_member_api_docs
  static final json = _MimeType('application/json');

  // ignore: public_member_api_docs
  static final xml = _MimeType('application/xml');
}

class _MimeType {
  _MimeType(this.value);

  final String value;
}

/// Http client with the correct authentication headers
class NextCloudHttpClient extends HttpClient {
  // ignore: public_member_api_docs
  NextCloudHttpClient(
    this._authString,
    this._defaultHeaders,
    this._inner,
  );

  // ignore: public_member_api_docs
  factory NextCloudHttpClient.defaultClient(
    String authString,
    Map<String, String>? defaultHeaders,
  ) =>
      NextCloudHttpClient(
        authString,
        defaultHeaders,
        HttpClient(),
      );

  /// Constructs a [NextCloudHttpClient] using Basic auth.
  factory NextCloudHttpClient.withCredentials(
    String username,
    String password, {
    Map<String, String>? defaultHeaders,
  }) =>
      NextCloudHttpClient.defaultClient(
        'Basic ${base64.encode(utf8.encode('$username:$password')).trim()}',
        defaultHeaders,
      );

  /// Constructs a [NextCloudHttpClient] using a Bearer app password.
  factory NextCloudHttpClient.withAppPassword(
    String appPassword, {
    Map<String, String>? defaultHeaders,
  }) =>
      NextCloudHttpClient.defaultClient(
        'Bearer $appPassword',
        defaultHeaders,
      );

  /// Constructs a [NextCloudHttpClient] without authentication.
  factory NextCloudHttpClient.withoutLogin({
    Map<String, String>? defaultHeaders,
  }) =>
      NextCloudHttpClient.defaultClient(
        '',
        defaultHeaders,
      );

  final http.Client _inner;
  final String _authString;
  final Map<String, String>? _defaultHeaders;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final coreHeaders = <String, String>{};
    coreHeaders[HttpHeaders.authorizationHeader] = _authString;
    coreHeaders['OCS-APIRequest'] = 'true';
    coreHeaders[HttpHeaders.acceptHeader] = ContentType.json.value;

    coreHeaders.forEach((key, value) {
      assert(
        !request.headers.containsKey(key) &&
            (_defaultHeaders == null || !_defaultHeaders!.containsKey(key)),
        'Overriding library core header ($key) is not allowed!',
      );
    });

    request.headers.addAll(coreHeaders);

    request.headers.putIfAbsent(
      HttpHeaders.contentTypeHeader,
      () => ContentType.json.value,
    );

    _defaultHeaders?.forEach((key, value) {
      request.headers.putIfAbsent(key, () => value);
    });

    return _inner.send(request);
  }
}

/// Exception thrown when a request fails
class RequestException implements Exception {
  // ignore: public_member_api_docs
  RequestException(
    this.body,
    this.statusCode,
    this.url,
    this.method, {
    this.retryAfter,
  });

  // ignore: public_member_api_docs
  String body;

  // ignore: public_member_api_docs
  int statusCode;

  // ignore: public_member_api_docs
  String url;

  // ignore: public_member_api_docs
  String method;

  /// Seconds to wait before retrying (for 429 rate limit errors)
  int? retryAfter;

  /// Returns true if this is a rate limiting error (HTTP 429)
  bool get isRateLimited => statusCode == 429;

  /// Returns true if this is a temporary error worth retrying
  bool get isRetryable => statusCode == 429 || statusCode >= 500;

  @override
  String toString() {
    final buffer = StringBuffer('RequestException: ');

    switch (statusCode) {
      case 429:
        buffer.write('Rate limited (too many requests)');
        if (retryAfter != null) {
          buffer.write(' - retry after ${retryAfter}s');
        }
        break;
      case 401:
        buffer.write('Unauthorized - check credentials');
        break;
      case 403:
        buffer.write('Forbidden - insufficient permissions');
        break;
      case 404:
        buffer.write('Not found');
        break;
      case 500:
        buffer.write('Internal server error');
        break;
      case 502:
        buffer.write('Bad gateway');
        break;
      case 503:
        buffer.write('Service unavailable');
        break;
      default:
        buffer.write('HTTP $statusCode');
    }

    buffer.write(' ($method $url)');

    if (body.isNotEmpty && body.length < 200) {
      buffer.write(' - $body');
    }

    return buffer.toString();
  }
}

/// Handles HTTP requests with retry logic for rate-limited responses
class Network {
  /// [maxRetries] - Maximum retry attempts for rate-limited requests (default: 3)
  /// [baseRetryDelay] - Base delay in ms for exponential backoff (default: 1000)
  Network(this._client, {this.maxRetries = 3, this.baseRetryDelay = 1000});

  final http.Client _client;

  /// Maximum number of retry attempts for rate limited requests
  final int maxRetries;

  /// Base delay in milliseconds for exponential backoff
  final int baseRetryDelay;

  /// Parse retry-after header value to seconds
  static int? parseRetryAfter(String? retryAfterHeader) {
    if (retryAfterHeader == null) return null;
    final seconds = int.tryParse(retryAfterHeader);
    if (seconds != null) return seconds;
    try {
      final date = DateTime.parse(retryAfterHeader);
      final diff = date.difference(DateTime.now());
      return diff.inSeconds > 0 ? diff.inSeconds : null;
    } catch (_) {
      return null;
    }
  }

  /// Calculate exponential backoff delay with jitter
  int calculateRetryDelay(int attempt, int? retryAfter) {
    if (retryAfter != null) {
      return retryAfter * 1000;
    }
    final exponentialDelay = baseRetryDelay * (1 << attempt);
    final jitter = (exponentialDelay * 0.25).round();
    final random = DateTime.now().millisecondsSinceEpoch % (jitter * 2);
    return exponentialDelay - jitter + random;
  }

  /// Send a request and return the full response, retrying on rate limits
  Future<http.Response> send(
    String method,
    String url,
    List<int> expectedCodes, {
    Uint8List? data,
    Map<String, String>? headers,
    ProgressCallback? onUploadProgress,
  }) async {
    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        return await http.Response.fromStream(
          await download(
            method,
            url,
            expectedCodes,
            data: data,
            headers: headers,
            onUploadProgress: onUploadProgress,
          ),
        );
      } on RequestException catch (e) {
        if (attempt >= maxRetries || !e.isRetryable) {
          rethrow;
        }
        final delay = calculateRetryDelay(attempt, e.retryAfter);
        await Future.delayed(Duration(milliseconds: delay));
      }
    }
    throw StateError('Unexpected end of retry loop');
  }

  /// Send a request and return the streamed response
  Future<http.StreamedResponse> download(
    String method,
    String url,
    List<int> expectedCodes, {
    Uint8List? data,
    Map<String, String>? headers,
    ProgressCallback? onUploadProgress,
  }) async {
    final request = http.Request(method, Uri.parse(url))
      ..followRedirects = false
      ..persistentConnection = true
      ..headers.addAll(headers ?? {});

    if (data != null && data.isNotEmpty && onUploadProgress != null) {
      final totalBytes = data.length;
      var sentBytes = 0;
      final stream = Stream.fromIterable(data.map((byte) {
        sentBytes++;
        if (sentBytes % 1024 == 0 || sentBytes == totalBytes) {
          onUploadProgress(sentBytes, totalBytes);
        }
        return [byte];
      })).expand((chunk) => chunk);
      request.bodyBytes = await stream.toList().then(Uint8List.fromList);
    } else {
      request.bodyBytes = data ?? Uint8List(0);
    }

    final response = await _client.send(request);

    if (!expectedCodes.contains(response.statusCode)) {
      final r = await http.Response.fromStream(response);
      int? retryAfter;
      if (response.statusCode == 429) {
        retryAfter = parseRetryAfter(r.headers['retry-after']);
      }
      throw RequestException(r.body, r.statusCode, url, method, retryAfter: retryAfter);
    }
    return response;
  }
}
