# User Registration / Login Authentication Spec

## Overview

Add user registration and login authentication to the Serifu public API. Currently the API uses an unauthenticated `X-User-ID` header for user identification. This spec defines JWT-based authentication with email/password registration and login.

---

## Current State

| Item | Status |
|------|--------|
| User model | Exists (`database.User`) - no password field |
| Admin auth | Session-based with bcrypt (separate `AdminUser` model) |
| Public API auth | None - uses `X-User-ID` header without verification |
| Mobile app (Flutter) | No auth implementation |

---

## Architecture Decision

| Option | Choice |
|--------|--------|
| Auth method | **JWT (Access Token + Refresh Token)** |
| Password hashing | **bcrypt** (already used for admin) |
| Token storage (mobile) | **flutter_secure_storage** |
| Token transport | **Authorization: Bearer \<token\>** header |

### Why JWT over Session

- Stateless - scales horizontally without shared session store
- Better fit for mobile app (Flutter) and future web client
- No server-side session storage needed

---

## Database Changes

### User Model (update existing)

```go
type User struct {
    // Existing fields
    ID         uuid.UUID
    Email      string         // uniqueIndex;not null
    Name       string         // not null
    Avatar     string
    Bio        string
    TotalLikes int            // default:0
    Status     string         // default:active
    CreatedAt  time.Time
    UpdatedAt  time.Time
    DeletedAt  gorm.DeletedAt

    // New fields
    PasswordHash string `gorm:"not null" json:"-"`
}
```

### Refresh Token Model (new)

```go
type RefreshToken struct {
    ID        uuid.UUID  // primaryKey
    UserID    uuid.UUID  // index;not null
    Token     string     // uniqueIndex;not null
    ExpiresAt time.Time  // not null
    CreatedAt time.Time
    RevokedAt *time.Time // null = active

    User *User
}
```

---

## API Endpoints

### POST /api/v1/auth/register

Create a new user account.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "securePassword123",
  "name": "Display Name"
}
```

**Validation:**
- `email`: required, valid email format, unique
- `password`: required, min 8 characters
- `name`: required, 1-50 characters

**Response (201):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "name": "Display Name",
      "avatar": "",
      "bio": "",
      "total_likes": 0,
      "status": "active",
      "created_at": "2026-01-30T00:00:00Z"
    },
    "access_token": "eyJhbGci...",
    "refresh_token": "eyJhbGci...",
    "expires_in": 900
  }
}
```

**Errors:**
| Code | Condition |
|------|-----------|
| 400 | Validation error (missing fields, weak password) |
| 409 | Email already registered |

---

### POST /api/v1/auth/login

Authenticate an existing user.

**Request:**
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
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "name": "Display Name",
      "avatar": "...",
      "bio": "...",
      "total_likes": 42,
      "status": "active"
    },
    "access_token": "eyJhbGci...",
    "refresh_token": "eyJhbGci...",
    "expires_in": 900
  }
}
```

**Errors:**
| Code | Condition |
|------|-----------|
| 400 | Missing email or password |
| 401 | Invalid email or password |
| 403 | Account suspended |

---

### POST /api/v1/auth/refresh

Refresh an expired access token.

**Request:**
```json
{
  "refresh_token": "eyJhbGci..."
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "access_token": "eyJhbGci...",
    "refresh_token": "eyJhbGci...",
    "expires_in": 900
  }
}
```

**Errors:**
| Code | Condition |
|------|-----------|
| 401 | Invalid or expired refresh token |

---

### POST /api/v1/auth/logout

Revoke the current refresh token.

**Request:**
```json
{
  "refresh_token": "eyJhbGci..."
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "message": "Logged out successfully"
  }
}
```

---

### GET /api/v1/auth/me

Get the authenticated user's profile.

**Headers:** `Authorization: Bearer <access_token>`

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
    "follower_count": 10,
    "following_count": 5,
    "answer_count": 23
  }
}
```

---

## Token Configuration

| Parameter | Value | Env Variable |
|-----------|-------|--------------|
| Access token TTL | 15 minutes | `JWT_ACCESS_TTL_MINUTES` |
| Refresh token TTL | 30 days | `JWT_REFRESH_TTL_DAYS` |
| JWT signing key | (secret) | `JWT_SECRET` |
| JWT algorithm | HS256 | - |

### Access Token Payload (JWT Claims)

```json
{
  "sub": "user-uuid",
  "exp": 1706600000,
  "iat": 1706599100,
  "type": "access"
}
```

### Refresh Token Payload (JWT Claims)

```json
{
  "sub": "user-uuid",
  "jti": "refresh-token-uuid",
  "exp": 1709191100,
  "iat": 1706599100,
  "type": "refresh"
}
```

---

## Auth Middleware

### New: `AuthRequired` middleware for public API

```
Authorization: Bearer <access_token>
```

1. Extract token from `Authorization` header
2. Validate JWT signature and expiry
3. Parse `sub` claim as user UUID
4. Query user from DB, ensure `status = "active"`
5. Set `user_id` (uuid.UUID) and `user` (*User) in gin context
6. Call `c.Next()`

**On failure:** Return `401 Unauthorized`

### Route Protection

| Routes | Auth |
|--------|------|
| `POST /api/v1/auth/register` | Public |
| `POST /api/v1/auth/login` | Public |
| `POST /api/v1/auth/refresh` | Public |
| `GET /api/v1/quizzes/*` | Public |
| `GET /api/v1/answers/:id` | Public |
| `GET /api/v1/users/:id` | Public |
| `GET /api/v1/trending/*` | Public |
| `GET /api/v1/rankings/*` | Public |
| `GET /api/v1/categories` | Public |
| `POST /api/v1/quizzes/:id/answers` | **Auth Required** |
| `PUT /api/v1/answers/:id` | **Auth Required** |
| `DELETE /api/v1/answers/:id` | **Auth Required** |
| `POST /api/v1/answers/:id/like` | **Auth Required** |
| `DELETE /api/v1/answers/:id/like` | **Auth Required** |
| `POST /api/v1/answers/:id/comments` | **Auth Required** |
| `DELETE /api/v1/comments/:id` | **Auth Required** |
| `PUT /api/v1/users/:id` | **Auth Required** |
| `POST /api/v1/users/:id/follow` | **Auth Required** |
| `DELETE /api/v1/users/:id/follow` | **Auth Required** |
| `GET /api/v1/auth/me` | **Auth Required** |
| `POST /api/v1/auth/logout` | **Auth Required** |

---

## Mobile App (Flutter) Screens

### Register Screen

```
+----------------------------------+
|  <-                              |
|                                  |
|         SERIFU                   |
|    Create Your Account           |
|                                  |
|  +----------------------------+  |
|  |  Name                      |  |
|  +----------------------------+  |
|                                  |
|  +----------------------------+  |
|  |  Email                     |  |
|  +----------------------------+  |
|                                  |
|  +----------------------------+  |
|  |  Password           [eye]  |  |
|  +----------------------------+  |
|                                  |
|  +----------------------------+  |
|  |  Confirm Password   [eye]  |  |
|  +----------------------------+  |
|                                  |
|  [      Create Account        ]  |
|                                  |
|  Already have an account?        |
|  -> Log in                       |
|                                  |
+----------------------------------+
```

**Behavior:**
- Client-side validation on all fields
- Password visibility toggle
- Confirm password match check
- Show inline error messages per field
- Show loading indicator on submit
- On success: navigate to Home screen
- On error (409): show "Email already registered"

---

### Login Screen

```
+----------------------------------+
|  <-                              |
|                                  |
|         SERIFU                   |
|    Welcome Back                  |
|                                  |
|  +----------------------------+  |
|  |  Email                     |  |
|  +----------------------------+  |
|                                  |
|  +----------------------------+  |
|  |  Password           [eye]  |  |
|  +----------------------------+  |
|                                  |
|  [        Log In              ]  |
|                                  |
|  Don't have an account?          |
|  -> Create Account               |
|                                  |
+----------------------------------+
```

**Behavior:**
- Client-side validation (email format, password not empty)
- Password visibility toggle
- Show loading indicator on submit
- On success: store tokens in secure storage, navigate to Home
- On error (401): show "Invalid email or password"
- On error (403): show "Account has been suspended"

---

### Auth Flow (Flutter)

```
App Launch
    |
    v
Check secure storage for tokens
    |
    +-- No tokens --> Show Login Screen
    |
    +-- Has tokens --> Validate access token
                          |
                          +-- Valid --> Home Screen
                          |
                          +-- Expired --> Call /auth/refresh
                                            |
                                            +-- Success --> Home Screen
                                            |
                                            +-- Fail --> Show Login Screen
```

---

## Backend File Structure (new/modified files)

```
internal/
├── auth/                          # NEW
│   ├── handler.go                 # Register, Login, Refresh, Logout, Me
│   ├── jwt.go                     # JWT generation and validation
│   └── middleware.go              # AuthRequired middleware
├── database/
│   └── models.go                  # MODIFY: add PasswordHash to User, add RefreshToken
├── config/
│   └── config.go                  # MODIFY: add JWTConfig
├── router/
│   └── router.go                  # MODIFY: add auth routes, apply middleware
└── middleware/
    └── cors.go                    # MODIFY: keep Authorization header
```

---

## Configuration Changes

Add to `config.go`:

```go
type JWTConfig struct {
    Secret          string // env: JWT_SECRET
    AccessTTLMin    int    // env: JWT_ACCESS_TTL_MINUTES, default: 15
    RefreshTTLDays  int    // env: JWT_REFRESH_TTL_DAYS, default: 30
}
```

Add to `.env.example`:

```
JWT_SECRET=your-jwt-secret-change-me
JWT_ACCESS_TTL_MINUTES=15
JWT_REFRESH_TTL_DAYS=30
```

---

## Go Dependencies (new)

```
go get github.com/golang-jwt/jwt/v5
```

(`golang.org/x/crypto` already exists for bcrypt)

---

## Security Considerations

- Passwords hashed with bcrypt (cost = default 10)
- Access tokens short-lived (15 min)
- Refresh tokens stored in DB, can be revoked
- Refresh token rotation on each refresh (old token revoked, new token issued)
- `PasswordHash` excluded from JSON responses (`json:"-"`)
- Rate limiting on login/register endpoints (future: implement with middleware)
- Suspended users rejected at middleware level

---

## Migration Notes

- Existing seed users have no password. After adding `PasswordHash` to the User model:
  - Update `seed_data.sql` to include password hashes
  - Or make `PasswordHash` nullable during migration, require it only on new registrations
  - Recommended: add `NOT NULL DEFAULT ''` and require password on register

---

## Implementation Order

1. Add `PasswordHash` to User model, add `RefreshToken` model
2. Add JWT config to `config.go`
3. Implement `internal/auth/jwt.go` (token generation/validation)
4. Implement `internal/auth/handler.go` (register, login, refresh, logout, me)
5. Implement `internal/auth/middleware.go` (AuthRequired)
6. Update `router.go` - add auth routes, apply middleware to protected routes
7. Update seed data
8. Implement Flutter auth screens and token management
