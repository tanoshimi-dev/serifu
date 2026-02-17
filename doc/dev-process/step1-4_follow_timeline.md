# Step 1-4: Follow Timeline Implementation Summary

**Date:** 2026-02-17
**Status:** Completed

---

## Overview

Implemented the follow timeline feature (Phase 1-4) for the Serifu app. Users can now view a chronological feed of answers from people they follow. The FeedScreen gains an "All" / "Following" tab toggle (visible only on the general feed, not quiz-specific views). The backend provides a new `GET /api/v1/timeline` endpoint that queries answers from followed users using a GORM subquery.

---

## Changes Summary

### Backend (Go + Gin + GORM)

#### Modified Files

| File | Change |
|------|--------|
| `internal/handlers/answer.go` | Added `GetTimeline` method to `AnswerHandler` |
| `internal/router/router.go` | Added `GET /timeline` route under `v1` group |

#### New API Endpoint

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/timeline` | Returns paginated answers from followed users, ordered by newest first |

#### GetTimeline Handler Logic

1. Validate `X-User-ID` header (401 if missing, 400 if invalid UUID)
2. Parse `page` and `page_size` query params (same pattern as `GetAnswersForQuiz`)
3. Build subquery: `SELECT following_id FROM follows WHERE follower_id = ?`
4. Query answers: `WHERE user_id IN (subquery) AND status = 'active'` with `ORDER BY created_at DESC`
5. Preload `User` and `Quiz` associations
6. Return paginated response via `utils.PaginatedSuccessResponse`

#### Key Design Decision

Uses GORM subquery (`db.Model(&database.Follow{}).Select("following_id").Where(...)`) instead of loading all follow records into memory. This keeps the query efficient as a single SQL statement with a subselect.

---

### Mobile (Flutter)

#### Modified Files

| File | Change |
|------|--------|
| `lib/repositories/answer_repository.dart` | Added `getTimeline()` method |
| `lib/screens/feed_screen.dart` | Added "All"/"Following" tab toggle, timeline data fetching, timeline list with load-more and empty state |

#### AnswerRepository Addition

```dart
Future<List<Answer>> getTimeline({int page = 1, int pageSize = 20})
```

Calls `GET /timeline` with pagination params. Same pattern as `getTrendingAnswers()`.

#### FeedScreen Changes

**New State Variables:**

| Variable | Type | Description |
|----------|------|-------------|
| `_selectedFeedTab` | `int` | 0 = All, 1 = Following |
| `_timelineAnswers` | `List<Answer>` | Answers for the Following tab |
| `_timelinePage` | `int` | Current page for timeline pagination |
| `_hasMoreTimeline` | `bool` | Whether more timeline pages exist |
| `_isLoadingTimeline` | `bool` | Loading state for timeline |
| `_timelineError` | `String?` | Error state for timeline |

**New Methods:**

| Method | Description |
|--------|-------------|
| `_onFeedTabChanged(int)` | Switches between All/Following tabs; lazy-loads timeline on first switch |
| `_loadTimeline()` | Fetches page 1 of timeline, resets pagination state |
| `_loadMoreTimeline()` | Fetches next page and appends to list |
| `_buildFeedTabs()` | Builds the "All" / "Following" chip toggle row |
| `_buildTimelineList()` | Builds the timeline ListView with loading, error, empty, and content states |

**UI Behavior:**

- Tab toggle only appears when `widget.quiz == null` (general feed view)
- "All" tab shows existing behavior (trending / category-filtered answers with sort tabs)
- "Following" tab shows reverse-chronological list with infinite scroll load-more
- Pull-to-refresh works on both tabs
- Like toggling syncs across both tabs via shared `_updateAnswerInList` helper
- Empty state message: "フォロー中のユーザーの投稿がここに表示されます"
- Tab styling matches existing sort tabs (rounded containers with active/inactive colors)

---

## API Specification

### GET `/api/v1/timeline`

#### Request

| Header | Value |
|--------|-------|
| `Authorization` | `Bearer {jwt_token}` |
| `X-User-ID` | `{user_id}` |

| Query Param | Type | Default | Description |
|-------------|------|---------|-------------|
| `page` | int | 1 | Page number |
| `page_size` | int | 20 | Items per page |

#### Response (200 OK)

```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "quiz_id": "uuid",
      "user_id": "uuid",
      "content": "...",
      "like_count": 5,
      "comment_count": 2,
      "view_count": 100,
      "status": "active",
      "created_at": "2026-02-17T12:00:00Z",
      "user": { "id": "...", "name": "...", "avatar": "..." },
      "quiz": { "id": "...", "title": "...", "situation": "..." }
    }
  ],
  "pagination": {
    "page": 1,
    "page_size": 20,
    "total": 42,
    "total_pages": 3
  }
}
```

#### Error Responses

| Status | Condition |
|--------|-----------|
| 400 | Invalid user ID |
| 401 | Missing X-User-ID header |
| 500 | Database query failure |

---

## Verification Checklist

- [x] Backend: `GET /api/v1/timeline` with valid `X-User-ID` returns answers from followed users only
- [x] Backend: Returns empty list when user follows nobody
- [x] Backend: Pagination works correctly (`page=1`, `page=2`, etc.)
- [x] Backend: Answers ordered by `created_at DESC`
- [x] Mobile: FeedScreen shows "All" / "Following" tabs on general feed
- [x] Mobile: "Following" tab loads timeline and displays AnswerCards
- [x] Mobile: Pull-to-refresh works on both tabs
- [x] Mobile: Empty state shown when following feed has no answers
- [x] Mobile: Tabs hidden when viewing quiz-specific feed (`widget.quiz != null`)
- [x] Mobile: Like toggling syncs between All and Following tabs
- [x] Mobile: `flutter analyze` passes with no issues
