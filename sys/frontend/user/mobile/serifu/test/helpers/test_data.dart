// Canned JSON response factories for E2E tests.
// These match the model `fromJson` contracts.

const testUserId = 'user-001';
const testToken = 'test-jwt-token-abc';
const testQuizId = 'quiz-001';
const testAnswerId = 'answer-001';
const testOtherUserId = 'user-002';
const testCommentId = 'comment-001';
const testNotificationId = 'notif-001';
const testCategoryId = 'cat-001';

Map<String, dynamic> testUserJson({
  String id = testUserId,
  String email = 'test@example.com',
  String name = 'TestUser',
  String? avatar,
  String? bio,
  int totalLikes = 42,
  int? followerCount = 10,
  int? followingCount = 5,
  int? answerCount = 8,
  bool? isFollowing,
}) =>
    {
      'id': id,
      'email': email,
      'name': name,
      if (avatar != null) 'avatar': avatar,
      if (bio != null) 'bio': bio,
      'total_likes': totalLikes,
      'status': 'active',
      'created_at': '2025-01-01T00:00:00Z',
      'updated_at': '2025-01-01T00:00:00Z',
      if (followerCount != null) 'follower_count': followerCount,
      if (followingCount != null) 'following_count': followingCount,
      if (answerCount != null) 'answer_count': answerCount,
      if (isFollowing != null) 'is_following': isFollowing,
    };

Map<String, dynamic> testLoginResponseJson({
  String token = testToken,
  Map<String, dynamic>? user,
}) =>
    {
      'success': true,
      'data': {
        'token': token,
        'user': user ?? testUserJson(),
      },
    };

Map<String, dynamic> testQuizJson({
  String id = testQuizId,
  String title = 'Test Quiz Title',
  String description = 'A test quiz description',
  String requirement = 'Answer in one sentence',
  String? categoryId,
  Map<String, dynamic>? category,
  int answerCount = 5,
}) =>
    {
      'id': id,
      'title': title,
      'description': description,
      'requirement': requirement,
      if (categoryId != null) 'category_id': categoryId,
      if (category != null) 'category': category,
      'release_date': '2025-01-01T00:00:00Z',
      'status': 'active',
      'answer_count': answerCount,
      'created_at': '2025-01-01T00:00:00Z',
      'updated_at': '2025-01-01T00:00:00Z',
    };

Map<String, dynamic> testCategoryJson({
  String id = testCategoryId,
  String name = 'Funny',
  String? description,
  String? icon,
  String? color,
  int sortOrder = 0,
}) =>
    {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      if (icon != null) 'icon': icon,
      if (color != null) 'color': color,
      'sort_order': sortOrder,
      'status': 'active',
    };

Map<String, dynamic> testAnswerJson({
  String id = testAnswerId,
  String quizId = testQuizId,
  String userId = testUserId,
  Map<String, dynamic>? user,
  String content = 'This is a test answer',
  int likeCount = 3,
  int commentCount = 1,
  int viewCount = 10,
  bool? isLiked,
}) =>
    {
      'id': id,
      'quiz_id': quizId,
      'user_id': userId,
      if (user != null) 'user': user,
      'content': content,
      'like_count': likeCount,
      'comment_count': commentCount,
      'view_count': viewCount,
      'status': 'active',
      'created_at': '2025-01-01T00:00:00Z',
      'updated_at': '2025-01-01T00:00:00Z',
      if (isLiked != null) 'is_liked': isLiked,
    };

Map<String, dynamic> testCommentJson({
  String id = testCommentId,
  String answerId = testAnswerId,
  String userId = testUserId,
  Map<String, dynamic>? user,
  String content = 'Nice answer!',
}) =>
    {
      'id': id,
      'answer_id': answerId,
      'user_id': userId,
      if (user != null) 'user': user,
      'content': content,
      'status': 'active',
      'created_at': '2025-01-01T00:00:00Z',
      'updated_at': '2025-01-01T00:00:00Z',
    };

Map<String, dynamic> testNotificationJson({
  String id = testNotificationId,
  String userId = testUserId,
  String actorId = testOtherUserId,
  Map<String, dynamic>? actor,
  String type = 'like',
  String targetType = 'answer',
  String targetId = testAnswerId,
  bool isRead = false,
}) =>
    {
      'id': id,
      'user_id': userId,
      'actor_id': actorId,
      if (actor != null) 'actor': actor,
      'type': type,
      'target_type': targetType,
      'target_id': targetId,
      'is_read': isRead,
      'created_at': DateTime.now().toIso8601String(),
    };
