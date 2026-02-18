import 'dart:io';
import '../api/api_client.dart';
import '../models/user.dart';
import '../models/answer.dart';

class UserRepository {
  final ApiClient _client;

  UserRepository({ApiClient? client}) : _client = client ?? apiClient;

  Future<User> getUser(String id) async {
    final response = await _client.get('/users/$id');
    return User.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<User> uploadAvatar(String userId, File imageFile) async {
    final response =
        await _client.uploadFile('/users/$userId/avatar', 'avatar', imageFile);
    return User.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<User> updateUser(String id, {String? name, String? bio, String? avatar}) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (bio != null) body['bio'] = bio;
    if (avatar != null) body['avatar'] = avatar;

    final response = await _client.put('/users/$id', body: body);
    return User.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<List<Answer>> getUserAnswers(
    String userId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };
    final response = await _client.get('/users/$userId/answers', queryParams: queryParams);
    final data = response['data'] as List<dynamic>;
    return data.map((json) => Answer.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<void> followUser(String userId) async {
    await _client.post('/users/$userId/follow');
  }

  Future<void> unfollowUser(String userId) async {
    await _client.delete('/users/$userId/follow');
  }

  Future<List<User>> getFollowers(
    String userId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };
    final response = await _client.get('/users/$userId/followers', queryParams: queryParams);
    final data = response['data'] as List<dynamic>;
    return data.map((json) => User.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<User>> getFollowing(
    String userId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };
    final response = await _client.get('/users/$userId/following', queryParams: queryParams);
    final data = response['data'] as List<dynamic>;
    return data.map((json) => User.fromJson(json as Map<String, dynamic>)).toList();
  }
}

UserRepository userRepository = UserRepository();
