import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Creates a [MockClient] that dispatches on `METHOD /path`.
///
/// [handlers] maps `"GET /path"` or `"POST /path"` keys to response builders.
/// Path matching supports simple `:id` pattern segments.
/// If no handler matches, returns a 404 by default (or [fallback] if provided).
MockClient createMockClient({
  required Map<String, http.Response Function(http.Request)> handlers,
  http.Response Function(http.Request)? fallback,
}) {
  return MockClient((request) async {
    final method = request.method;
    final path = request.url.path;

    // Try exact match first
    final exactKey = '$method $path';
    if (handlers.containsKey(exactKey)) {
      return handlers[exactKey]!(request);
    }

    // Try pattern matching (e.g., `/users/:id/answers`)
    for (final entry in handlers.entries) {
      final parts = entry.key.split(' ');
      if (parts.length != 2 || parts[0] != method) continue;

      if (_pathMatches(parts[1], path)) {
        return entry.value(request);
      }
    }

    if (fallback != null) {
      return fallback(request);
    }

    return http.Response(
      jsonEncode({'success': false, 'error': 'Not found: $method $path'}),
      404,
    );
  });
}

bool _pathMatches(String pattern, String path) {
  final patternSegments = pattern.split('/');
  final pathSegments = path.split('/');

  if (patternSegments.length != pathSegments.length) return false;

  for (var i = 0; i < patternSegments.length; i++) {
    if (patternSegments[i].startsWith(':')) continue;
    if (patternSegments[i] != pathSegments[i]) return false;
  }

  return true;
}

/// JSON success response helper.
http.Response jsonResponse(dynamic data, {int statusCode = 200}) {
  return http.Response(
    jsonEncode({'success': true, 'data': data}),
    statusCode,
    headers: {'content-type': 'application/json'},
  );
}

/// JSON list response helper.
http.Response jsonListResponse(List<dynamic> data, {int statusCode = 200}) {
  return http.Response(
    jsonEncode({'success': true, 'data': data}),
    statusCode,
    headers: {'content-type': 'application/json'},
  );
}

/// JSON error response helper.
http.Response errorResponse(String message, {int statusCode = 400}) {
  return http.Response(
    jsonEncode({'success': false, 'error': message}),
    statusCode,
    headers: {'content-type': 'application/json'},
  );
}

/// Empty success response.
http.Response successResponse() {
  return http.Response(
    jsonEncode({'success': true, 'data': {}}),
    200,
    headers: {'content-type': 'application/json'},
  );
}
