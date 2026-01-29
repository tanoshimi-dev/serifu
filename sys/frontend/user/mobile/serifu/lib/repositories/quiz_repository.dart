import '../api/api_client.dart';
import '../models/quiz.dart';

class QuizRepository {
  final ApiClient _client;

  QuizRepository({ApiClient? client}) : _client = client ?? apiClient;

  Future<List<Quiz>> getDailyQuizzes() async {
    final response = await _client.get('/quizzes/daily');
    final data = response['data'] as List<dynamic>;
    return data.map((json) => Quiz.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<Quiz>> getQuizzes({
    int page = 1,
    int pageSize = 20,
    String? categoryId,
    String? status,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
      if (categoryId != null) 'category_id': categoryId,
      if (status != null) 'status': status,
    };
    final response = await _client.get('/quizzes', queryParams: queryParams);
    final data = response['data'] as List<dynamic>;
    return data.map((json) => Quiz.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Quiz> getQuiz(String id) async {
    final response = await _client.get('/quizzes/$id');
    return Quiz.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<List<Category>> getCategories() async {
    final response = await _client.get('/categories');
    final data = response['data'] as List<dynamic>;
    return data.map((json) => Category.fromJson(json as Map<String, dynamic>)).toList();
  }
}

final quizRepository = QuizRepository();
