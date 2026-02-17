# Profile Image Upload Spec

## Overview

ユーザーがプロフィール画像を設定できる機能。カメラまたはギャラリーから画像を選択してアップロードし、アプリ内の全画面でアバターとして表示される。画像未設定時はグラデーション円 + 名前の頭文字にフォールバックする。

---

## Architecture

```
Mobile                              Backend                         Storage
  |                                   |                               |
  |-- pickImage (camera/gallery) -->  |                               |
  |                                   |                               |
  |-- POST /users/:id/avatar ------->|                               |
  |   (multipart form: "avatar")      |                               |
  |                                   |-- Validate (size, type) -->   |
  |                                   |-- Save file --------------> ./static/uploads/avatars/
  |                                   |-- Update User.Avatar in DB    |
  |                                   |                               |
  |<-- { user with avatar URL } ------|                               |
  |                                   |                               |
  |-- GET /static/uploads/... ------->|-- Serve static file --------->|
```

---

## API

### POST `/api/v1/users/:id/avatar`

プロフィール画像をアップロードする。

#### Request

| Header | Value |
|--------|-------|
| `Authorization` | `Bearer {jwt_token}` |
| `X-User-ID` | `{user_id}` |
| `Content-Type` | `multipart/form-data` |

| Form Field | Type | Required | Description |
|------------|------|----------|-------------|
| `avatar` | File | Yes | 画像ファイル (JPEG, PNG, WebP) |

#### Validation

| Rule | Value | Error Message |
|------|-------|---------------|
| Max file size | 5MB | `File size exceeds 5MB limit` |
| Allowed types | `image/jpeg`, `image/png`, `image/webp` | `Only JPEG, PNG, and WebP images are allowed` |
| Ownership | `:id` == `X-User-ID` | `You can only update your own avatar` |

Content type is validated by reading the first 512 bytes and using `http.DetectContentType()` (magic bytes check, not Content-Type header).

#### Response (200 OK)

```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "email": "user@example.com",
    "name": "Username",
    "avatar": "/static/uploads/avatars/uuid_1708123456789.jpg",
    "bio": "...",
    "total_likes": 42,
    "status": "active",
    "created_at": "2026-01-01T00:00:00Z",
    "updated_at": "2026-02-17T12:00:00Z"
  }
}
```

#### Error Responses

| Status | Condition |
|--------|-----------|
| 400 | Invalid user ID, file too large, invalid file type, no file |
| 401 | Missing X-User-ID header |
| 403 | Trying to update another user's avatar |
| 404 | User not found |
| 500 | File save or DB update failure |

---

## File Storage

### Storage Path

```
./static/uploads/avatars/{userID}_{timestampMs}.{ext}
```

例: `./static/uploads/avatars/550e8400-e29b-41d4-a716-446655440000_1708123456789.jpg`

### URL Path (DB に保存)

```
/static/uploads/avatars/{userID}_{timestampMs}.{ext}
```

### Static File Serving

Gin の `r.Static("/static", "./static")` で自動配信。追加設定不要。

### Old File Cleanup

新しいアバターがアップロードされると、既存の古いアバターファイルは削除される。`User.Avatar` のパスから先頭の `/` を除去してファイルパスを取得し `os.Remove()` で削除。

---

## Backend Config

| Env Variable | Default | Description |
|-------------|---------|-------------|
| `UPLOAD_AVATAR_DIR` | `./static/uploads/avatars` | アバター保存ディレクトリ |
| `UPLOAD_MAX_FILE_SIZE_MB` | `5` | 最大ファイルサイズ (MB) |

---

## Mobile Implementation

### UserAvatar Widget

全画面で共有されるアバター表示ウィジェット。

```dart
UserAvatar(
  avatarUrl: String?,   // User.avatar (nullable)
  initial: String,      // フォールバック用の頭文字
  size: double,         // 直径 (default: 80)
)
```

#### URL Resolution Logic

```
avatarUrl が null or 空       → フォールバック (グラデーション円 + 頭文字)
avatarUrl が http(s):// で始まる → そのまま使用 (ソーシャルログインのプロフィール画像)
avatarUrl が / で始まる         → serverBaseUrl + avatarUrl で完全 URL を構築
画像読み込み失敗                 → フォールバック (errorBuilder)
```

`serverBaseUrl` は `ApiClient.baseUrl` から `/api/v1` サフィックスを除去して取得。

#### Usage Sizes

| Screen | Size | Context |
|--------|------|---------|
| ProfileScreen | 80 | Own profile (with camera icon overlay) |
| UserProfileScreen | 80 | Other user's profile |
| AnswerDetailScreen | 48 | Answer author |
| NotificationScreen | 44 | Notification actor |
| FollowListScreen | 44 | User list item |
| AnswerCard | 40 | Answer card header |
| HomeScreen (rankings) | 36 | Rankings list |
| HomeScreen (trending) | 32 | Trending answers |
| CommentScreen | 32 | Comment author |
| RankingsScreen | 36 | Rankings list |

### Upload Flow

1. プロフィール画面でアバターをタップ
2. BottomSheet 表示: 「Camera」/「Gallery」選択
3. `ImagePicker.pickImage(source: source, maxWidth: 512, maxHeight: 512)`
4. `userRepository.uploadAvatar(userId, File(picked.path))`
5. `ApiClient.uploadFile()` が `http.MultipartRequest` で POST 送信
6. 成功時: `_user` state 更新 → UI 即座に反映

### Upload UI (ProfileScreen のみ)

- アバター右下に青丸カメラアイコンのオーバーレイ (28x28)
- `GestureDetector` でタップ可能
- 他ユーザーのプロフィール画面ではアップロード UI なし (表示のみ)

---

## Database

`users` テーブルの既存 `avatar` カラム (STRING) を使用。新規カラム追加なし。

```
users.avatar: "/static/uploads/avatars/uuid_1708123456789.jpg"
              "https://lh3.googleusercontent.com/..." (ソーシャルログイン)
              "" (未設定)
```

---

## Screens Using UserAvatar

| Screen | File | Type |
|--------|------|------|
| ProfileScreen | `screens/profile_screen.dart` | Upload + Display |
| UserProfileScreen | `screens/user_profile_screen.dart` | Display only |
| AnswerCard | `widgets/answer_card.dart` | Display only |
| AnswerDetailScreen | `screens/answer_detail_screen.dart` | Display only |
| NotificationScreen | `screens/notification_screen.dart` | Display only |
| HomeScreen | `screens/home_screen.dart` | Display only (trending + rankings) |
| FollowListScreen | `screens/follow_list_screen.dart` | Display only |
| RankingsScreen | `screens/rankings_screen.dart` | Display only |
| CommentScreen | `screens/comment_screen.dart` | Display only |

---

## Future Considerations

- **Image Compression:** 現在は `ImagePicker` の `maxWidth/maxHeight: 512` でリサイズ。サーバーサイドでのリサイズ/サムネイル生成は未実装
- **Cloud Storage:** 本番環境では S3/GCS などのオブジェクトストレージに移行を検討
- **CDN:** 画像配信の最適化 (キャッシュヘッダー、CDN 経由)
- **Image Cropping:** アップロード前の画像トリミング UI
