# Step 1-3: Profile Image Upload Implementation Summary

**Date:** 2026-02-17
**Status:** Completed

---

## Overview

Implemented profile image upload (Phase 1-3) for the Serifu app. Users can now upload a profile image from their camera or gallery. The image is stored on the backend's local filesystem and served as a static file. All screens that display user avatars now show the uploaded image when available, with a fallback to the gradient circle + initial pattern.

---

## Changes Summary

### Backend (Go + Gin + GORM)

#### Modified Files

| File | Change |
|------|--------|
| `internal/config/config.go` | Added `UploadConfig` struct (AvatarDir, MaxFileSizeMB), loads from `UPLOAD_AVATAR_DIR` / `UPLOAD_MAX_FILE_SIZE_MB` env vars |
| `internal/handlers/user.go` | Added `avatarDir` / `maxFileSizeMB` fields to `UserHandler`, updated constructor, added `UploadAvatar` handler |
| `internal/router/router.go` | Added `POST /:id/avatar` route, updated `NewUserHandler` call to pass upload config |

#### New API Endpoint

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/v1/users/:id/avatar` | Upload avatar image (multipart form, field: `avatar`) |

#### UploadAvatar Handler Logic

1. Validate user ID and ownership (only own avatar)
2. Parse multipart form with configurable max size (default 5MB)
3. Validate content type via `http.DetectContentType` — accepts `image/jpeg`, `image/png`, `image/webp`
4. Generate unique filename: `{userID}_{timestampMs}.{ext}`
5. Create upload directory if not exists (`os.MkdirAll`)
6. Save file to `./static/uploads/avatars/{filename}`
7. Delete old avatar file if user already had one
8. Update `User.Avatar` field in DB with URL path `/static/uploads/avatars/{filename}`
9. Return updated user object

#### Upload Config Defaults

| Env Variable | Default | Description |
|-------------|---------|-------------|
| `UPLOAD_AVATAR_DIR` | `./static/uploads/avatars` | Directory to store avatar files |
| `UPLOAD_MAX_FILE_SIZE_MB` | `5` | Maximum upload file size in MB |

#### Static File Serving

No additional config needed — `r.Static("/static", "./static")` in `main.go` already serves the entire `./static` directory. Upload directory is created on first upload via `os.MkdirAll`.

---

### Mobile (Flutter)

#### New Files

| File | Description |
|------|-------------|
| `lib/widgets/user_avatar.dart` | Shared `UserAvatar` widget — shows network image if avatar URL exists, falls back to gradient circle with initial |

#### Modified Files

| File | Change |
|------|--------|
| `pubspec.yaml` | Added `image_picker: ^1.1.2` dependency |
| `lib/api/api_client.dart` | Added `serverBaseUrl` static getter (strips `/api/v1` suffix), added `uploadFile()` method for multipart uploads |
| `lib/repositories/user_repository.dart` | Added `uploadAvatar(userId, imageFile)` method |
| `lib/screens/profile_screen.dart` | Added camera/gallery bottom sheet picker, `_pickAndUploadAvatar()` method, avatar shows camera icon overlay, uses `UserAvatar` |
| `lib/screens/user_profile_screen.dart` | Replaced inline avatar with `UserAvatar` (view-only) |
| `lib/widgets/answer_card.dart` | Replaced inline avatar with `UserAvatar`, added `Flexible` to prevent long username overflow |
| `lib/screens/notification_screen.dart` | Replaced inline avatar with `UserAvatar` |
| `lib/screens/home_screen.dart` | Replaced trending + rankings inline avatars with `UserAvatar` |
| `lib/screens/follow_list_screen.dart` | Replaced inline avatar with `UserAvatar` |
| `lib/screens/rankings_screen.dart` | Replaced inline avatar with `UserAvatar` |
| `lib/screens/comment_screen.dart` | Replaced inline avatar with `UserAvatar`, added `Flexible` to prevent overflow |
| `lib/screens/answer_detail_screen.dart` | Replaced inline avatar with `UserAvatar` |
| `lib/screens/feed_screen.dart` | Fixed header overflow: wrapped quiz title `Text` in `Expanded` with `TextOverflow.ellipsis` |

#### UserAvatar Widget

```dart
UserAvatar(
  avatarUrl: user.avatar,     // nullable, from User model
  initial: user.avatarInitial, // fallback initial letter
  size: 80,                    // diameter in pixels
)
```

- If `avatarUrl` is a full URL (starts with `http://` or `https://`): uses it directly (supports social login profile pictures from Google etc.)
- If `avatarUrl` is a relative path (e.g., `/static/uploads/avatars/...`): prepends `ApiClient.serverBaseUrl`
- If `avatarUrl` is null/empty or image fails to load: shows gradient circle with initial (existing pattern)

#### Upload Flow (ProfileScreen)

1. User taps avatar → bottom sheet appears with "Camera" / "Gallery" options
2. `ImagePicker.pickImage()` with `maxWidth: 512, maxHeight: 512`
3. `userRepository.uploadAvatar()` sends multipart POST to `/users/:id/avatar`
4. On success, `_user` state updates → UI refreshes immediately

---

## Bug Fixes (During Implementation)

### 1. URL Concatenation for External Avatar URLs

**Problem:** Social login users (Google) have full URLs as avatar (e.g., `https://lh3.googleusercontent.com/...`). The `UserAvatar` widget was prepending `serverBaseUrl`, producing invalid URLs like `http://10.0.2.2:8080https://lh3.googleusercontent.com/...`.

**Fix:** Added URL scheme check — if `avatarUrl` starts with `http://` or `https://`, use it directly without prepending.

### 2. RenderFlex Overflow on Feed Screen Header

**Problem:** `feed_screen.dart` header had an unconstrained `Text(widget.quiz?.title)` inside a `spaceBetween` Row. Long quiz titles caused horizontal overflow.

**Fix:** Wrapped the title `Text` in `Expanded` with `TextOverflow.ellipsis`.

### 3. Potential Overflow in Answer Card and Comment Screen

**Problem:** Username text inside inner `Row` widgets (answer_card, comment_screen) was unconstrained. Long usernames could overflow.

**Fix:** Wrapped in `Flexible` with `TextOverflow.ellipsis` and set inner Row to `mainAxisSize: MainAxisSize.min`.

---

## Verification Checklist

- [x] Backend: `POST /api/v1/users/:id/avatar` with multipart form saves file to `./static/uploads/avatars/`
- [x] Backend: `GET /static/uploads/avatars/{filename}` serves uploaded image
- [x] Backend: Rejects files > 5MB and non-image content types
- [x] Backend: Old avatar file is deleted when new one is uploaded
- [x] Backend: Only the user themselves can update their own avatar
- [x] Mobile: Tap avatar on ProfileScreen → picker opens → upload → avatar updates
- [x] Mobile: All 10 screens show network avatar image when user has uploaded one
- [x] Mobile: Fallback to initial-based gradient avatar when no image uploaded
- [x] Mobile: External avatar URLs (Google profile pictures) work correctly
- [x] Mobile: `flutter analyze` passes with no issues
- [x] Mobile: `flutter pub get` installs `image_picker` dependency
