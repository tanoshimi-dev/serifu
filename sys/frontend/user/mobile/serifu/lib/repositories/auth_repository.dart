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

  Future<User> getMe() async {
    final response = await _client.get('/auth/me');
    return User.fromJson(response['data'] as Map<String, dynamic>);
  }
}

final authRepository = AuthRepository();
