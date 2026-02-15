# Mobile App API List

Base URL: `http://<host>:8080/api/v1`

## Common

### Response Format

**Success:**
```json
{
  "success": true,
  "data": { ... }
}
```

**Paginated:**
```json
{
  "success": true,
  "data": [ ... ],
  "pagination": {
    "page": 1,
    "page_size": 20,
    "total": 100,
    "total_pages": 5,
    "has_more": true
  }
}
```

**Error:**
```json
{
  "success": false,
  "error": "Error message"
}
```

### Authentication

Protected endpoints require the header:
```
Authorization: Bearer <access_token>
```

### Pagination Parameters

| Param | Type | Default | Max | Description |
|-------|------|---------|-----|-------------|
| `page` | int | 1 | - | Page number |
| `page_size` | int | 20 | 100 | Items per page |

---

## 1. Auth

### 1-1. POST /auth/register

Create a new user account.

**Auth:** Not required

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "securePassword123",
  "name": "Display Name"
}
```

**Validation:**
- `email`: required, valid format, unique
- `password`: required, min 6 chars
- `name`: required

**Response (201):**
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGci...",
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "name": "Display Name",
      "avatar": "",
      "bio": "",
      "total_likes": 0,
      "status": "active",
      "created_at": "2026-01-30T00:00:00Z",
      "updated_at": "2026-01-30T00:00:00Z"
    }
  }
}
```

**Errors:**

| Code | Condition |
|------|-----------|
| 400 | Validation error (missing fields, invalid email, weak password) |
| 409 | Email already registered |

---

### 1-2. POST /auth/login

Login with email and password.

**Auth:** Not required

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "securePassword123"
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGci...",
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "name": "Display Name",
      "avatar": "...",
      "bio": "...",
      "total_likes": 42,
      "status": "active",
      "created_at": "...",
      "updated_at": "..."
    }
  }
}
```

**Errors:**

| Code | Condition |
|------|-----------|
| 400 | Missing email or password |
| 401 | Invalid email or password |

---

### 1-3. GET /auth/me

Get the authenticated user's profile.

**Auth:** Required

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "email": "user@example.com",
    "name": "Display Name",
    "avatar": "...",
    "bio": "...",
    "total_likes": 42,
    "status": "active",
    "created_at": "...",
    "updated_at": "...",
    "follower_count": 10,
    "following_count": 5,
    "answer_count": 23
  }
}
```

**Errors:**

| Code | Condition |
|------|-----------|
| 401 | Invalid or missing token |

---

## 2. Quiz

### 2-1. GET /quizzes/daily

Get today's quizzes.

**Auth:** Not required

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "title": "Quiz Title",
      "description": "...",
      "requirement": "...",
      "category_id": "uuid",
      "category": {
        "id": "uuid",
        "name": "Category Name",
        "description": "...",
        "icon": "...",
        "color": "#FF0000"
      },
      "release_date": "2026-02-16",
      "status": "active",
      "answer_count": 150,
      "created_at": "...",
      "updated_at": "..."
    }
  ]
}
```

---

### 2-2. GET /quizzes

Get quizzes with pagination and filters.

**Auth:** Not required

**Query Params:**

| Param | Type | Description |
|-------|------|-------------|
| `page` | int | Page number |
| `page_size` | int | Items per page |
| `category_id` | uuid | Filter by category |
| `status` | string | Filter by status |

**Response (200):** Paginated array of quiz objects (same structure as 2-1).

---

### 2-3. GET /quizzes/:id

Get a single quiz by ID.

**Auth:** Not required

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "title": "Quiz Title",
    "description": "...",
    "requirement": "...",
    "category_id": "uuid",
    "category": { ... },
    "release_date": "2026-02-16",
    "status": "active",
    "answer_count": 150,
    "created_at": "...",
    "updated_at": "..."
  }
}
```

**Errors:**

| Code | Condition |
|------|-----------|
| 404 | Quiz not found |

---

## 3. Answer

### 3-1. GET /quizzes/:id/answers

Get answers for a quiz.

**Auth:** Not required

**Query Params:**

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `page` | int | 1 | Page number |
| `page_size` | int | 20 | Items per page |
| `sort` | string | `latest` | Sort order: `latest`, `popular`, `trending` |

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "quiz_id": "uuid",
      "user_id": "uuid",
      "user": {
        "id": "uuid",
        "name": "User Name",
        "avatar": "..."
      },
      "content": "Answer text (max 150 chars)",
      "like_count": 42,
      "comment_count": 5,
      "view_count": 200,
      "status": "active",
      "created_at": "...",
      "updated_at": "..."
    }
  ],
  "pagination": { ... }
}
```

---

### 3-2. POST /quizzes/:id/answers

Submit an answer to a quiz.

**Auth:** Required

**Request Body:**
```json
{
  "content": "Answer text (max 150 chars)"
}
```

**Response (201):**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "quiz_id": "uuid",
    "user_id": "uuid",
    "content": "Answer text",
    "like_count": 0,
    "comment_count": 0,
    "view_count": 0,
    "status": "active",
    "created_at": "...",
    "updated_at": "..."
  }
}
```

**Errors:**

| Code | Condition |
|------|-----------|
| 400 | Content empty, exceeds 150 chars, or already answered this quiz |
| 404 | Quiz not found |

---

### 3-3. GET /answers/:id

Get a single answer. Increments view count.

**Auth:** Not required

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "quiz_id": "uuid",
    "user_id": "uuid",
    "user": { ... },
    "content": "...",
    "like_count": 42,
    "comment_count": 5,
    "view_count": 201,
    "status": "active",
    "created_at": "...",
    "updated_at": "..."
  }
}
```

**Errors:**

| Code | Condition |
|------|-----------|
| 404 | Answer not found |

---

### 3-4. PUT /answers/:id

Update own answer.

**Auth:** Required (owner only)

**Request Body:**
```json
{
  "content": "Updated answer text"
}
```

**Response (200):** Updated answer object.

**Errors:**

| Code | Condition |
|------|-----------|
| 403 | Not the owner |
| 404 | Answer not found |

---

### 3-5. DELETE /answers/:id

Delete own answer.

**Auth:** Required (owner only)

**Response (200):**
```json
{
  "success": true,
  "data": { "message": "Answer deleted successfully" }
}
```

**Errors:**

| Code | Condition |
|------|-----------|
| 403 | Not the owner |
| 404 | Answer not found |

---

## 4. Like

### 4-1. POST /answers/:id/like

Like an answer.

**Auth:** Required

**Response (201):**
```json
{
  "success": true,
  "data": { "message": "Liked" }
}
```

**Errors:**

| Code | Condition |
|------|-----------|
| 400 | Already liked |
| 404 | Answer not found |

---

### 4-2. DELETE /answers/:id/like

Unlike an answer.

**Auth:** Required

**Response (200):**
```json
{
  "success": true,
  "data": { "message": "Unliked" }
}
```

**Errors:**

| Code | Condition |
|------|-----------|
| 404 | Like not found |

---

## 5. Comment

### 5-1. GET /answers/:id/comments

Get comments for an answer.

**Auth:** Not required

**Query Params:** `page`, `page_size`

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "answer_id": "uuid",
      "user_id": "uuid",
      "user": {
        "id": "uuid",
        "name": "User Name",
        "avatar": "..."
      },
      "content": "Comment text",
      "status": "active",
      "created_at": "...",
      "updated_at": "..."
    }
  ],
  "pagination": { ... }
}
```

---

### 5-2. POST /answers/:id/comments

Add a comment to an answer.

**Auth:** Required

**Request Body:**
```json
{
  "content": "Comment text"
}
```

**Response (201):** Comment object.

**Errors:**

| Code | Condition |
|------|-----------|
| 400 | Content empty |
| 404 | Answer not found |

---

### 5-3. DELETE /comments/:id

Delete own comment.

**Auth:** Required (owner only)

**Response (200):**
```json
{
  "success": true,
  "data": { "message": "Comment deleted successfully" }
}
```

**Errors:**

| Code | Condition |
|------|-----------|
| 403 | Not the owner |
| 404 | Comment not found |

---

## 6. User

### 6-1. GET /users/:id

Get a user's profile.

**Auth:** Not required (but if authenticated, includes `is_following` flag)

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "email": "user@example.com",
    "name": "Display Name",
    "avatar": "...",
    "bio": "...",
    "total_likes": 42,
    "status": "active",
    "created_at": "...",
    "updated_at": "...",
    "follower_count": 10,
    "following_count": 5,
    "answer_count": 23,
    "is_following": true
  }
}
```

**Errors:**

| Code | Condition |
|------|-----------|
| 404 | User not found |

---

### 6-2. GET /users/:id/answers

Get a user's answers.

**Auth:** Not required

**Query Params:** `page`, `page_size`

**Response (200):** Paginated array of answer objects.

---

### 6-3. PUT /users/:id

Update own profile.

**Auth:** Required (owner only)

**Request Body:**
```json
{
  "name": "New Name",
  "avatar": "new_avatar_url",
  "bio": "New bio text"
}
```

All fields are optional.

**Response (200):** Updated user object.

**Errors:**

| Code | Condition |
|------|-----------|
| 403 | Not the owner |
| 404 | User not found |

---

## 7. Follow

### 7-1. POST /users/:id/follow

Follow a user.

**Auth:** Required

**Response (201):**
```json
{
  "success": true,
  "data": { "message": "Followed" }
}
```

**Errors:**

| Code | Condition |
|------|-----------|
| 400 | Self-follow or already following |

---

### 7-2. DELETE /users/:id/follow

Unfollow a user.

**Auth:** Required

**Response (200):**
```json
{
  "success": true,
  "data": { "message": "Unfollowed" }
}
```

---

### 7-3. GET /users/:id/followers

Get a user's followers.

**Auth:** Not required

**Query Params:** `page`, `page_size`

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "name": "Follower Name",
      "avatar": "...",
      "bio": "..."
    }
  ],
  "pagination": { ... }
}
```

---

### 7-4. GET /users/:id/following

Get users that this user follows.

**Auth:** Not required

**Query Params:** `page`, `page_size`

**Response (200):** Same structure as 7-3.

---

## 8. Trending & Rankings

### 8-1. GET /trending/answers

Get trending answers (last 7 days).

**Auth:** Not required

**Query Params:** `page`, `page_size`

**Sort Score:** `likes + (comments * 2) + (views * 0.1)` DESC

**Response (200):** Paginated array of answer objects (with user preloaded).

---

### 8-2. GET /rankings/daily

Get today's top answers ranked by likes.

**Auth:** Not required

**Query Params:** `page`, `page_size`

**Response (200):** Paginated array of answer objects.

---

### 8-3. GET /rankings/weekly

Get this week's top answers ranked by likes.

**Auth:** Not required

**Query Params:** `page`, `page_size`

**Response (200):** Paginated array of answer objects.

---

### 8-4. GET /rankings/all-time

Get all-time top answers ranked by likes.

**Auth:** Not required

**Query Params:** `page`, `page_size`

**Response (200):** Paginated array of answer objects.

---

## 9. Category

### 9-1. GET /categories

Get all active categories.

**Auth:** Not required

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "name": "Category Name",
      "description": "...",
      "icon": "icon_name",
      "color": "#FF0000",
      "sort_order": 1,
      "status": "active",
      "created_at": "...",
      "updated_at": "..."
    }
  ]
}
```

---

## 10. Health Check

### 10-1. GET /health

**Auth:** Not required

**Response (200):**
```json
{
  "status": "ok",
  "service": "serifu-api"
}
```

---

## API Summary Table

| # | Method | Endpoint | Auth | Description |
|---|--------|----------|------|-------------|
| 1-1 | POST | `/auth/register` | - | Register |
| 1-2 | POST | `/auth/login` | - | Login |
| 1-3 | GET | `/auth/me` | Required | Get my profile |
| 2-1 | GET | `/quizzes/daily` | - | Get today's quizzes |
| 2-2 | GET | `/quizzes` | - | List quizzes |
| 2-3 | GET | `/quizzes/:id` | - | Get quiz detail |
| 3-1 | GET | `/quizzes/:id/answers` | - | List answers for quiz |
| 3-2 | POST | `/quizzes/:id/answers` | Required | Submit answer |
| 3-3 | GET | `/answers/:id` | - | Get answer detail |
| 3-4 | PUT | `/answers/:id` | Required | Update answer |
| 3-5 | DELETE | `/answers/:id` | Required | Delete answer |
| 4-1 | POST | `/answers/:id/like` | Required | Like answer |
| 4-2 | DELETE | `/answers/:id/like` | Required | Unlike answer |
| 5-1 | GET | `/answers/:id/comments` | - | List comments |
| 5-2 | POST | `/answers/:id/comments` | Required | Add comment |
| 5-3 | DELETE | `/comments/:id` | Required | Delete comment |
| 6-1 | GET | `/users/:id` | - | Get user profile |
| 6-2 | GET | `/users/:id/answers` | - | List user's answers |
| 6-3 | PUT | `/users/:id` | Required | Update profile |
| 7-1 | POST | `/users/:id/follow` | Required | Follow user |
| 7-2 | DELETE | `/users/:id/follow` | Required | Unfollow user |
| 7-3 | GET | `/users/:id/followers` | - | List followers |
| 7-4 | GET | `/users/:id/following` | - | List following |
| 8-1 | GET | `/trending/answers` | - | Trending answers |
| 8-2 | GET | `/rankings/daily` | - | Daily ranking |
| 8-3 | GET | `/rankings/weekly` | - | Weekly ranking |
| 8-4 | GET | `/rankings/all-time` | - | All-time ranking |
| 9-1 | GET | `/categories` | - | List categories |
| 10-1 | GET | `/health` | - | Health check |
