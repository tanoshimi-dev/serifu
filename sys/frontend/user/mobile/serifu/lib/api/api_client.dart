import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}

class ApiClient {
  final http.Client _httpClient;
  final String? _baseUrlOverride;

  ApiClient({http.Client? httpClient, String? baseUrl})
      : _httpClient = httpClient ?? http.Client(),
        _baseUrlOverride = baseUrl;

  // Use API_BASE_URL from .env if set, otherwise fall back to defaults:
  // - Android emulator: 10.0.2.2 to access host machine's localhost
  // - iOS simulator: localhost
  String get baseUrl {
    if (_baseUrlOverride != null) return _baseUrlOverride;
    final envUrl = dotenv.env['API_BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080/api/v1';
    }
    return 'http://localhost:8080/api/v1';
  }

  String? _userId;
  String? _token;

  void setUserId(String userId) {
    _userId = userId;
  }

  String? get userId => _userId;

  void setToken(String token) {
    _token = token;
  }

  void clearToken() {
    _token = null;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
        if (_userId != null) 'X-User-ID': _userId!,
      };

  Future<Map<String, dynamic>> get(String path,
      {Map<String, String>? queryParams}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: queryParams);
    final response = await _httpClient.get(uri, headers: _headers);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(String path,
      {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _httpClient.post(
      uri,
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> put(String path,
      {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _httpClient.put(
      uri,
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _httpClient.delete(uri, headers: _headers);
    return _handleResponse(response);
  }

  /// Get the server base URL (without /api/v1 suffix) for constructing static file URLs.
  String get serverBaseUrl {
    final url = baseUrl;
    if (url.endsWith('/api/v1')) {
      return url.substring(0, url.length - '/api/v1'.length);
    }
    return url;
  }

  Future<Map<String, dynamic>> uploadFile(
      String path, String fieldName, File file) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll({
      if (_token != null) 'Authorization': 'Bearer $_token',
      if (_userId != null) 'X-User-ID': _userId!,
    });
    request.files
        .add(await http.MultipartFile.fromPath(fieldName, file.path));
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body['success'] == true) {
        return body;
      }
      throw ApiException(body['error'] ?? 'Unknown error',
          statusCode: response.statusCode);
    }

    throw ApiException(
      body['error'] ?? 'Request failed',
      statusCode: response.statusCode,
    );
  }
}

// Global singleton instance
ApiClient apiClient = ApiClient();
