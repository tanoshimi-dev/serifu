import '../api/api_client.dart';
import '../models/notification.dart';

class NotificationRepository {
  final ApiClient _client;

  NotificationRepository({ApiClient? client}) : _client = client ?? apiClient;

  Future<List<AppNotification>> getNotifications({
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };
    final response = await _client.get('/notifications', queryParams: queryParams);
    final data = response['data'] as List<dynamic>;
    return data.map((json) => AppNotification.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<void> markAllAsRead() async {
    await _client.put('/notifications/read-all');
  }

  Future<int> getUnreadCount() async {
    final response = await _client.get('/notifications/unread-count');
    final data = response['data'] as Map<String, dynamic>;
    return data['unread_count'] as int? ?? 0;
  }
}

NotificationRepository notificationRepository = NotificationRepository();
