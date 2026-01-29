import '../api/api_client.dart';
import '../models/answer.dart';

enum AnswerSort { latest, popular, trending }

class AnswerRepository {
  final ApiClient _client;

  AnswerRepository({ApiClient? client}) : _client = client ?? apiClient;

  Future<List<Answer>> getAnswersForQuiz(
    String quizId, {
    int page = 1,
    int pageSize = 20,
    AnswerSort sort = AnswerSort.popular,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
      'sort': sort.name,
    };
    final response = await _client.get('/quizzes/$quizId/answers', queryParams: queryParams);
    final data = response['data'] as List<dynamic>;
    return data.map((json) => Answer.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Answer> getAnswer(String id) async {
    final response = await _client.get('/answers/$id');
    return Answer.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Answer> createAnswer(String quizId, String content) async {
    final response = await _client.post('/quizzes/$quizId/answers', body: {
      'content': content,
    });
    return Answer.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Answer> updateAnswer(String id, String content) async {
    final response = await _client.put('/answers/$id', body: {
      'content': content,
    });
    return Answer.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> deleteAnswer(String id) async {
    await _client.delete('/answers/$id');
  }

  Future<void> likeAnswer(String id) async {
    await _client.post('/answers/$id/like');
  }

  Future<void> unlikeAnswer(String id) async {
    await _client.delete('/answers/$id/like');
  }

  Future<List<Answer>> getTrendingAnswers({
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };
    final response = await _client.get('/trending/answers', queryParams: queryParams);
    final data = response['data'] as List<dynamic>;
    return data.map((json) => Answer.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<Answer>> getRankings({
    required String period, // daily, weekly, all-time
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };
    final response = await _client.get('/rankings/$period', queryParams: queryParams);
    final data = response['data'] as List<dynamic>;
    return data.map((json) => Answer.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<Comment>> getComments(
    String answerId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };
    final response = await _client.get('/answers/$answerId/comments', queryParams: queryParams);
    final data = response['data'] as List<dynamic>;
    return data.map((json) => Comment.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Comment> createComment(String answerId, String content) async {
    final response = await _client.post('/answers/$answerId/comments', body: {
      'content': content,
    });
    return Comment.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> deleteComment(String id) async {
    await _client.delete('/comments/$id');
  }
}

final answerRepository = AnswerRepository();
