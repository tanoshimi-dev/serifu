# Notification System Spec

## Overview

Serifu の通知システムは、ユーザー間のインタラクション (いいね・コメント・フォロー) をリアルタイムで通知する機能。初期実装はポーリングベースで、将来的に Push 通知 (FCM) への拡張を想定。

---

## Architecture

```
User Action                    Backend                         Mobile
    |                            |                               |
    |--- Like/Comment/Follow --->|                               |
    |                            |                               |
    |                   1. Execute action                        |
    |                   2. CreateNotification()                  |
    |                      (skip if actor == recipient)          |
    |                   3. Store in notifications table          |
    |                            |                               |
    |                            |<-- GET /notifications --------|
    |                            |--- Return paginated list ---->|
    |                            |                               |
    |                            |<-- GET /unread-count ---------|
    |                            |--- Return { count } --------->|
    |                            |                               |
    |                            |<-- PUT /read-all -------------|
    |                            |--- Mark all as read --------->|
```

---

## Database Schema

### notifications table

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PK, auto-generated | |
| user_id | UUID | FK -> users.id, NOT NULL, indexed | 通知を受け取るユーザー |
| actor_id | UUID | FK -> users.id, NOT NULL, indexed | アクションを起こしたユーザー |
| type | STRING(20) | NOT NULL | like, comment, follow |
| target_type | STRING(20) | | answer, user |
| target_id | UUID | | 対象の ID |
| is_read | BOOL | default: false | 既読フラグ |
| created_at | TIMESTAMP | | |

### Indexes

| Name | Columns | Purpose |
|------|---------|---------|
| idx_notifications_user_created | (user_id, created_at DESC) | ユーザーの通知一覧取得を高速化 |

---

## Notification Types

### Like Notification

| Field | Value |
|-------|-------|
| type | `like` |
| target_type | `answer` |
| target_id | liked answer's ID |
| user_id | answer owner |
| actor_id | user who liked |
| Message | "{actor_name} liked your answer" |

**Trigger:** `LikeAnswer` handler (like.go) — after successful like creation

### Comment Notification

| Field | Value |
|-------|-------|
| type | `comment` |
| target_type | `answer` |
| target_id | commented answer's ID |
| user_id | answer owner |
| actor_id | user who commented |
| Message | "{actor_name} commented on your answer" |

**Trigger:** `CreateComment` handler (comment.go) — after successful comment creation

### Follow Notification

| Field | Value |
|-------|-------|
| type | `follow` |
| target_type | `user` |
| target_id | followed user's ID |
| user_id | followed user |
| actor_id | user who followed |
| Message | "{actor_name} started following you" |

**Trigger:** `FollowUser` handler (follow.go) — after successful follow creation

---

## Self-Notification Prevention

`CreateNotification()` は `actorID == userID` の場合、通知を作成しない。
自分の回答にいいね・コメントしても通知は発生しない。

---

## API Endpoints

### GET /api/v1/notifications

通知一覧をページネーション付きで取得。Actor (アクションを起こしたユーザー) の情報をプリロード。

**Headers:** `X-User-ID: {uuid}`

**Query Parameters:**

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| page | int | 1 | ページ番号 |
| page_size | int | 20 | 1ページのサイズ |

**Response:**

```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "user_id": "uuid",
      "actor_id": "uuid",
      "type": "like",
      "target_type": "answer",
      "target_id": "uuid",
      "is_read": false,
      "created_at": "2026-02-17T10:00:00Z",
      "actor": {
        "id": "uuid",
        "email": "user@example.com",
        "name": "Taro",
        "avatar": "",
        "bio": "",
        "total_likes": 5,
        "status": "active",
        "created_at": "2026-01-01T00:00:00Z",
        "updated_at": "2026-01-01T00:00:00Z"
      }
    }
  ],
  "pagination": {
    "page": 1,
    "page_size": 20,
    "total": 42,
    "total_pages": 3,
    "has_more": true
  }
}
```

### GET /api/v1/notifications/unread-count

未読通知数を取得。

**Headers:** `X-User-ID: {uuid}`

**Response:**

```json
{
  "success": true,
  "data": {
    "unread_count": 5
  }
}
```

### PUT /api/v1/notifications/read-all

全通知を既読にする。

**Headers:** `X-User-ID: {uuid}`

**Response:**

```json
{
  "success": true,
  "data": {
    "message": "All notifications marked as read"
  }
}
```

---

## Mobile Implementation

### Model: AppNotification

```dart
class AppNotification {
  final String id;
  final String userId;
  final String actorId;
  final User? actor;
  final String type;       // like, comment, follow
  final String targetType; // answer, user
  final String targetId;
  final bool isRead;
  final DateTime createdAt;

  String get message;  // Human-readable message
  String get timeAgo;  // Relative time (e.g., "5m ago")
}
```

### Repository: NotificationRepository

| Method | Return | Description |
|--------|--------|-------------|
| `getNotifications({page, pageSize})` | `List<AppNotification>` | GET /notifications |
| `markAllAsRead()` | void | PUT /notifications/read-all |
| `getUnreadCount()` | int | GET /notifications/unread-count |

### Screen: NotificationScreen

- Gradient header with bell icon + "Notifications" title
- ListView of notification items
- Each item: actor avatar (gradient circle) + type icon overlay + message + time ago
- Pull-to-refresh
- Auto marks all as read on screen open
- Tap navigation:
  - like/comment → fetch answer → AnswerDetailScreen
  - follow → UserProfileScreen (actor's profile)
- Empty state: bell icon + "No notifications yet" message

### Type Icon Overlay

| Type | Icon | Color |
|------|------|-------|
| like | Icons.favorite | likeRed |
| comment | Icons.chat_bubble | primaryStart |
| follow | Icons.person_add | #4CAF50 (green) |

### BottomNavBar Badge

- `notificationBadge` parameter on BottomNavBar
- Red circular badge on notification icon when unread > 0
- Shows count (max "99+")
- HomeScreen header bell icon also shows badge

### Navigation Tab Order

```
Index 0: Home      (Icons.home)
Index 1: Feed      (Icons.local_fire_department)
Index 2: Write     (Icons.edit)
Index 3: Notify    (Icons.notifications_outlined) — NEW
Index 4: Profile   (Icons.person) — was index 3
```

All screens updated: home_screen, feed_screen, write_screen, profile_screen, notification_screen.

---

## Future Enhancements

### Phase 2: Push Notifications (FCM)

- Firebase Cloud Messaging integration
- Backend sends push notification when creating notification record
- Mobile registers FCM token on login
- New endpoint: `POST /api/v1/devices` (register device token)

### Phase 2: Individual Read Status

- `PUT /api/v1/notifications/:id/read` — mark single notification as read
- Update is_read on notification tap in mobile

### Phase 2: Notification Preferences

- User settings to enable/disable notification types
- New table: `notification_preferences` (user_id, type, enabled)

### Phase 3: WebSocket Real-Time

- Replace polling with WebSocket connection
- Instant badge update without page refresh
- New endpoint: `WS /api/v1/ws/notifications`
