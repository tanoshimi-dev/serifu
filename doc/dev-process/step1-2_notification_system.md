# Step 1-2: Notification System Implementation Summary

**Date:** 2026-02-17
**Status:** Completed

---

## Overview

Implemented the notification system (Phase 1-2) for the Serifu app. Users are now notified when someone likes their answer, comments on their answer, or follows them. This is essential for SNS functionality.

---

## Changes Summary

### Backend (Go + Gin + GORM)

#### New Files

| File | Description |
|------|-------------|
| `handlers/notification.go` | NotificationHandler with GetNotifications, MarkAllAsRead, GetUnreadCount + CreateNotification helper |

#### Modified Files

| File | Change |
|------|--------|
| `database/models.go` | Added `Notification` model (ID, UserID, ActorID, Type, TargetType, TargetID, IsRead, CreatedAt) |
| `database/database.go` | Added `&Notification{}` to AutoMigrate + composite index `idx_notifications_user_created` |
| `handlers/like.go` | Hook: creates "like" notification after successful like |
| `handlers/comment.go` | Hook: creates "comment" notification after successful comment |
| `handlers/follow.go` | Hook: creates "follow" notification after successful follow |
| `router/router.go` | Added 3 notification routes under `/api/v1/notifications` |

#### New API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/notifications` | Paginated notification list (preloads Actor) |
| PUT | `/api/v1/notifications/read-all` | Mark all notifications as read |
| GET | `/api/v1/notifications/unread-count` | Get unread notification count |

#### Notification Types

| Type | Trigger | target_type | target_id |
|------|---------|-------------|-----------|
| `like` | User likes an answer | `answer` | answer ID |
| `comment` | User comments on an answer | `answer` | answer ID |
| `follow` | User follows another user | `user` | target user ID |

#### Self-Notification Prevention

`CreateNotification()` skips notification creation when `actorID == userID` (e.g., liking your own answer does not create a notification).

---

### Mobile (Flutter)

#### New Files

| File | Description |
|------|-------------|
| `models/notification.dart` | `AppNotification` class with `fromJson`, `message` getter, `timeAgo` getter |
| `repositories/notification_repository.dart` | `getNotifications()`, `markAllAsRead()`, `getUnreadCount()` + singleton |
| `screens/notification_screen.dart` | Full notification screen with list, pull-to-refresh, tap-to-navigate |

#### Modified Files

| File | Change |
|------|--------|
| `widgets/bottom_nav_bar.dart` | Added Notifications tab (index 3), shifted Profile to index 4, added `notificationBadge` param with red badge |
| `screens/home_screen.dart` | Fetches unread count on load, passes badge to BottomNavBar, wired header bell icon with badge + navigation |
| `screens/profile_screen.dart` | Updated `currentIndex` to 4, added notification nav case (index 3) |
| `screens/write_screen.dart` | Added notification nav case (index 3), shifted profile to index 4 |
| `screens/feed_screen.dart` | Added notification nav case (index 3), shifted profile to index 4 |

#### BottomNavBar Tab Order (Updated)

```
Index 0: Home
Index 1: Feed
Index 2: Write
Index 3: Notifications (NEW)
Index 4: Profile (was index 3)
```

#### NotificationScreen Features

- Gradient header with bell icon
- ListView of notification items with actor avatar, type-specific icon overlay (heart/chat/person), message, time ago
- Pull-to-refresh
- Auto marks all as read on open
- Tap navigation: like/comment -> AnswerDetailScreen, follow -> UserProfileScreen
- Empty state message when no notifications

#### Notification Badge

- Red badge on BottomNavBar notification icon showing unread count
- Badge also shown on header bell icon in HomeScreen
- Count refreshes when returning from NotificationScreen
- Displays "99+" when count exceeds 99

---

## Database Schema

```
notifications
├── id          UUID (PK, auto-generated)
├── user_id     UUID (FK -> users.id, indexed, NOT NULL)  -- recipient
├── actor_id    UUID (FK -> users.id, indexed, NOT NULL)  -- who triggered
├── type        STRING(20) (NOT NULL)                     -- like, comment, follow
├── target_type STRING(20)                                -- answer, user
├── target_id   UUID                                      -- answer ID or user ID
├── is_read     BOOL (default: false)
├── created_at  TIMESTAMP
└── INDEX: idx_notifications_user_created (user_id, created_at DESC)
```

---

## Verification Checklist

- [x] Backend auto-migration creates `notifications` table
- [x] Like/comment/follow creates notification records in DB
- [x] `GET /api/v1/notifications` returns paginated list with actor info
- [x] `GET /api/v1/notifications/unread-count` returns correct count
- [x] `PUT /api/v1/notifications/read-all` marks all as read
- [x] Self-actions don't create notifications
- [x] NotificationScreen shows notifications with correct icons/messages
- [x] Badge appears on BottomNav when unread notifications exist
- [x] Tapping notification navigates to correct screen
- [x] All screens updated with new nav indices (Profile shifted to 4)
