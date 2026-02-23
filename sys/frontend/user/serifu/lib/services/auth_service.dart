import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';

class AuthService {
  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'auth_user_id';
  String? _cachedToken;

  bool get isLoggedInSync => _cachedToken != null;

  Future<void> saveAuth(String token, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userIdKey, userId);
    _cachedToken = token;
    apiClient.setToken(token);
    apiClient.setUserId(userId);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    _cachedToken = null;
    apiClient.clearToken();
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> restoreAuth() async {
    final token = await getToken();
    final userId = await getUserId();
    if (token != null && token.isNotEmpty) {
      _cachedToken = token;
      apiClient.setToken(token);
      if (userId != null && userId.isNotEmpty) {
        apiClient.setUserId(userId);
      }
    }
  }
}

AuthService authService = AuthService();
