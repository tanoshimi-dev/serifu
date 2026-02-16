import '../api/api_client.dart';
import '../models/user.dart';

class AuthRepository {
  final ApiClient _client;

  AuthRepository({ApiClient? client}) : _client = client ?? apiClient;

  Future<({String token, User user})> register(
      String email, String name, String password) async {
    final response = await _client.post('/auth/register', body: {
      'email': email,
      'name': name,
      'password': password,
    });
    final data = response['data'] as Map<String, dynamic>;
    return (
      token: data['token'] as String,
      user: User.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  Future<({String token, User user})> login(
      String email, String password) async {
    final response = await _client.post('/auth/login', body: {
      'email': email,
      'password': password,
    });
    final data = response['data'] as Map<String, dynamic>;
    return (
      token: data['token'] as String,
      user: User.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  Future<({String token, User user})> googleLogin(String idToken, {String? name}) async {
    final response = await _client.post('/auth/google', body: {
      'token': idToken,
      if (name != null) 'name': name,
    });
    final data = response['data'] as Map<String, dynamic>;
    return (
      token: data['token'] as String,
      user: User.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  Future<({String token, User user})> appleLogin(String identityToken, {String? name}) async {
    final response = await _client.post('/auth/apple', body: {
      'token': identityToken,
      if (name != null) 'name': name,
    });
    final data = response['data'] as Map<String, dynamic>;
    return (
      token: data['token'] as String,
      user: User.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  Future<({String token, User user})> lineLogin(String accessToken, {String? name}) async {
    final response = await _client.post('/auth/line', body: {
      'token': accessToken,
      if (name != null) 'name': name,
    });
    final data = response['data'] as Map<String, dynamic>;
    return (
      token: data['token'] as String,
      user: User.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  Future<User> getMe() async {
    final response = await _client.get('/auth/me');
    return User.fromJson(response['data'] as Map<String, dynamic>);
  }
}

final authRepository = AuthRepository();
