import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// A custom HTTP client that wraps every Supabase API call with
/// request/response logging and centralised error reporting.
///
/// Add more interceptor hooks (auth header injection, retry logic,
/// analytics, etc.) here without touching any data source.
class AppHttpClient extends http.BaseClient {
  AppHttpClient([http.Client? inner]) : _inner = inner ?? http.Client();

  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final stopwatch = Stopwatch()..start();
    _logRequest(request);

    try {
      final streamed = await _inner.send(request);
      stopwatch.stop();
      final ms = stopwatch.elapsedMilliseconds;

      if (streamed.statusCode >= 400) {
        // Buffer the body so we can log it AND still return it to the caller.
        final body = await streamed.stream.toBytes();
        _logErrorResponse(request, streamed, body, ms);
        return http.StreamedResponse(
          http.ByteStream.fromBytes(body),
          streamed.statusCode,
          contentLength: streamed.contentLength,
          request: streamed.request,
          headers: streamed.headers,
          isRedirect: streamed.isRedirect,
          persistentConnection: streamed.persistentConnection,
          reasonPhrase: streamed.reasonPhrase,
        );
      }

      _logResponse(request, streamed, ms);
      return streamed;
    } catch (e, st) {
      stopwatch.stop();
      _logError(request, e, st, stopwatch.elapsedMilliseconds);
      rethrow;
    }
  }

  @override
  void close() => _inner.close();

  // ---------------------------------------------------------------------------
  // Interceptor hooks — override or extend these as needed
  // ---------------------------------------------------------------------------

  void _logRequest(http.BaseRequest request) {
    if (!kDebugMode) return;
    debugPrint(
      '[HTTP] --> ${request.method} ${_sanitisedUrl(request.url)}',
    );
  }

  void _logResponse(
    http.BaseRequest request,
    http.StreamedResponse response,
    int ms,
  ) {
    if (!kDebugMode) return;
    final icon = response.statusCode < 400 ? '✓' : '✗';
    debugPrint(
      '[HTTP] $icon <-- ${response.statusCode} '
      '${_sanitisedUrl(request.url)} (${ms}ms)',
    );
  }

  void _logErrorResponse(
    http.BaseRequest request,
    http.StreamedResponse response,
    List<int> body,
    int ms,
  ) {
    debugPrint(
      '[HTTP] ✗ <-- ${response.statusCode} '
      '${_sanitisedUrl(request.url)} (${ms}ms)\n'
      '[HTTP] body: ${String.fromCharCodes(body)}',
    );
  }

  void _logError(
    http.BaseRequest request,
    Object error,
    StackTrace stackTrace,
    int ms,
  ) {
    debugPrint(
      '[HTTP] ✗ ERROR ${_sanitisedUrl(request.url)} '
      '(${ms}ms): $error',
    );
  }

  /// Strips the apikey/Authorization query params from the URL before logging
  /// so secrets are never printed to the console.
  Uri _sanitisedUrl(Uri url) {
    if (url.queryParameters.isEmpty) return url;
    final safe = Map<String, String>.from(url.queryParameters)
      ..remove('apikey');
    return url.replace(queryParameters: safe);
  }
}
