# Phase 2: Flutter Web ブラウザ版リリース 実装記録

## 概要

既存の Flutter モバイルアプリを Web 版として公開するために、プラットフォーム抽象化・URL ルーティング・レスポンシブレイアウト・Web 固有機能・デプロイ設定を実装した。

---

## Step 1: プラットフォーム抽象化

**目的**: `dart:io` や Web 非対応パッケージを条件分岐で分離し、`flutter build web` を通す

### 新規作成ファイル

| ファイル | 内容 |
|---------|------|
| `lib/utils/platform_utils.dart` | `kIsWeb`, `isIOS`, `isAndroid` のファサード (conditional import) |
| `lib/utils/platform_utils_stub.dart` | Web 用スタブ (dart:io なし) |
| `lib/utils/platform_utils_native.dart` | Native 用 (dart:io.Platform) |
| `lib/services/platform_init_service.dart` | 初期化サービス抽象クラス (conditional import) |
| `lib/services/platform_init_stub.dart` | Web 用 no-op 実装 |
| `lib/services/platform_init_native.dart` | Native 用 (flutter_native_splash + LINE SDK) |
| `lib/services/social_auth_stub.dart` | Web 用ソーシャル認証 (Google のみ) |
| `lib/services/social_auth_native.dart` | Native 用ソーシャル認証 (全プロバイダー) |
| `.env.web` | Web 用環境変数 (`API_BASE_URL=/api/v1`) |

### 修正ファイル

- **`lib/main.dart`** — `flutter_line_sdk` / `flutter_native_splash` の直接 import を条件分岐化、Web では `.env.web` をロード
- **`lib/api/api_client.dart`** — `dart:io` 削除、Web では `API_BASE_URL=/api/v1`(同一オリジン）、`uploadFile` を bytes ベースに変更
- **`lib/services/social_auth_service.dart`** — abstract class + conditional import パターンで Web/Native 分岐
- **`lib/screens/login_screen.dart`** / **`register_screen.dart`** — `Platform.isIOS` を `socialAuthService.isAppleSignInAvailable` / `isLineSignInAvailable` に変更
- **`lib/screens/profile_screen.dart`** — `dart:io.File` を `Uint8List` bytes に置換、Web ではカメラ選択肢を非表示
- **`lib/repositories/user_repository.dart`** — `File` パラメータを `Uint8List bytes, String filename` に変更
- **`pubspec.yaml`** — `.env.web` をアセットに追加

### 技術的ポイント

- **Conditional import パターン**: `import 'stub.dart' if (dart.library.io) 'native.dart'` で Web/Native を分岐
- **bytes ベースのファイルアップロード**: `dart:io.File` は Web で使えないため `Uint8List` + `String filename` に統一
- **Google Sign-In Web 対応**: `google_sign_in_web` プラグインは OAuth2 implicit flow を使用し `access_token` のみ返す（`id_token` は null）。Native は `id_token` を返す。Web stub では `idToken ?? accessToken` でフォールバック
- **Google Sign-In メタタグ**: `google_sign_in_web` は Flutter 起動前に `<meta name="google-signin-client_id">` からクライアント ID を読み取るため、`web/index.html` にメタタグが必須。`GoogleSignIn()` コンストラクタの `serverClientId` は Web では使用不可（assertion error になる）
- **People API 必須**: `google_sign_in_web` はユーザープロフィール取得に People API を使用。Google Cloud Console で有効化が必要（無料）
- **Backend access_token 対応**: Web から送られる access_token を検証するため、バックエンドの `GoogleLogin` を id_token / access_token 両対応に変更。id_token は `tokeninfo?id_token=` で検証、access_token は `googleapis.com/oauth2/v3/userinfo` で検証
- **開発時の API_BASE_URL**: `.env.web` は本番では `/api/v1`（nginx プロキシ経由）だが、開発時は `http://localhost:8080/api/v1`（Flutter dev server はポート 8888 で API プロキシなし）

---

## Step 2: go_router による URL ルーティング

**目的**: `Navigator.push()` を `go_router` に移行し、ブラウザバック/フォワード・ディープリンクに対応

### 新規作成ファイル

| ファイル | 内容 |
|---------|------|
| `lib/router/app_router.dart` | GoRouter 設定 (認証リダイレクト + ShellRoute) |
| `lib/widgets/app_shell.dart` | シェルウィジェット (BottomNavBar をタブ画面のみ表示) |

### 修正ファイル

- **`lib/services/auth_service.dart`** — `_cachedToken` フィールドと `isLoggedInSync` getter を追加 (GoRouter redirect は同期的に認証状態を判定する必要があるため)
- **`lib/main.dart`** — `MaterialApp.router(routerConfig: appRouter)` に変更、`runApp` 前に認証復元
- **`pubspec.yaml`** — `go_router: ^14.0.0` を追加

### 全 14 画面の修正

| 画面 | 主な変更 |
|-----|---------|
| `home_screen.dart` | Scaffold/BottomNavBar 削除、Column に変更、`context.push()` |
| `feed_screen.dart` | 同上 |
| `write_screen.dart` | 同上 |
| `notification_screen.dart` | 同上 |
| `profile_screen.dart` | 同上 + `context.go('/login')` でログアウト |
| `login_screen.dart` | `context.go('/')` / `context.go('/register')` |
| `register_screen.dart` | `context.go('/')` / `context.go('/login')` |
| `quiz_detail_screen.dart` | `quizId` 必須 + optional `quiz`、API fallback 追加 |
| `answer_detail_screen.dart` | `answerId` 必須 + optional `answer`、API fallback 追加 |
| `comment_screen.dart` | `answerId` 必須 + optional `answer`、API fallback 追加 |
| `user_profile_screen.dart` | go_router ナビゲーション |
| `rankings_screen.dart` | go_router ナビゲーション |
| `follow_list_screen.dart` | go_router ナビゲーション |
| `category_quizzes_screen.dart` | `categoryId` 必須 + optional `category`、API fallback 追加 |

### ルート一覧

```
/login, /register
/ (home), /feed, /write, /notifications, /profile  ← ShellRoute (タブ画面)
/rankings
/quiz/:id, /answer/:id, /answer/:id/comments
/user/:id, /user/:id/followers, /user/:id/following
/category/:id
```

### 技術的ポイント

- **ShellRoute**: タブ画面は AppShell でラップし、BottomNavBar を共有。タブ画面は Column を返す (Scaffold なし)
- **Detail screen fallback**: `state.extra` で model を渡すが、直接 URL アクセス時は `state.pathParameters['id']` で API から取得
- **Dialog の Navigator.pop**: ダイアログ/BottomSheet の dismiss は `Navigator.pop(context, value)` のまま（ルートではなくオーバーレイを閉じるため）

---

## Step 3: レスポンシブレイアウト

**目的**: Mobile/Tablet/Desktop でレイアウトを切り替え

### ブレークポイント

- Mobile: < 768px (既存レイアウトそのまま)
- Tablet: 768-1024px (Desktop と同じ)
- Desktop: >= 1024px (TopNav + サイドバー + メインコンテンツ)

### 新規作成ファイル

| ファイル | 内容 |
|---------|------|
| `lib/widgets/responsive_layout.dart` | `LayoutBuilder` でブレークポイント分岐 (`isMobile`, `isTablet`, `isDesktop` static メソッド付き) |
| `lib/widgets/content_constraint.dart` | `maxWidth` 制約ラッパー (デフォルト 680px) |
| `lib/widgets/desktop_nav_bar.dart` | デスクトップ用トップナビ (グラデーション背景、ロゴ、ナビアイテム、検索アイコン) |
| `lib/widgets/desktop_sidebar.dart` | 右サイドバー (300px) — Daily Rankings (Top 5) + Categories 表示 |

### 修正ファイル

- **`lib/widgets/app_shell.dart`** — `ResponsiveLayout` で Mobile/Desktop シェルを切替:
  - **Mobile**: `Scaffold` + `BottomNavBar`
  - **Desktop**: `Column(DesktopNavBar, Expanded(Row(ContentConstraint(child), DesktopSidebar)))`
  - サイドバーはタブ画面のみ表示

---

## Step 4: Web 固有の機能

**目的**: ブラウザ体験の最適化

### 新規作成ファイル

| ファイル | 内容 |
|---------|------|
| `lib/widgets/hover_card.dart` | `MouseRegion` によるホバーエフェクト (シャドウ + Y 軸アニメーション、`kIsWeb` のみ有効) |
| `lib/widgets/keyboard_shortcuts.dart` | グローバルキーボードショートカット (`CallbackShortcuts`、`kIsWeb` のみ有効) |

### キーボードショートカット

| キー | アクション |
|-----|---------|
| `H` | Home |
| `F` | Feed |
| `W` | Write |
| `N` | Notifications |
| `P` | Profile |
| `Esc` | Back (Navigator.pop) |

### 修正ファイル

- **`lib/widgets/answer_card.dart`** — `HoverCard` でラップ
- **`lib/widgets/app_shell.dart`** — `KeyboardShortcuts` でラップ (GoRouter context 内で配置)
- **`web/index.html`** — OGP メタタグ追加 (`og:title`, `og:description`, `og:image`, `og:url`, Twitter Card)、`theme-color` を `#6C5CE7` に設定、タイトルを "Serifu" に更新、`<meta name="google-signin-client_id">` 追加
- **`web/manifest.json`** — アプリ名を "Serifu - Quiz + SNS" に更新、`theme_color` を `#6C5CE7`、`background_color` を `#FFFFFF` に変更
- **`lib/services/social_auth_stub.dart`** — `serverClientId` 削除（Web 非対応）、`idToken ?? accessToken` でフォールバック
- **`sys/backend/app/internal/handlers/social_auth.go`** — `GoogleLogin` を id_token / access_token 両対応に変更（`verifyGoogleIDToken` + `verifyGoogleAccessToken` ヘルパー追加）

---

## Step 5: デプロイ設定

**目的**: Flutter Web を既存インフラで配信

### 新規作成ファイル

| ファイル | 内容 |
|---------|------|
| `sys/scripts/build-web.sh` | ビルドスクリプト — `flutter clean` → `flutter pub get` → `flutter build web --release` → `nginx/web/` にコピー |

### 修正ファイル

- **`sys/backend/nginx/nginx.conf`**:
  - `root /usr/share/nginx/html/web` を追加
  - SPA ルーティング: `try_files $uri $uri/ /index.html`
  - 静的アセットキャッシュ: `expires 1y` + `Cache-Control: public, immutable` (js, css, wasm, 画像, フォント)
  - gzip types に `application/wasm` を追加
  - 404 エラーページを削除 (SPA ルーティングで処理)
- **`sys/backend/nginx/Dockerfile`** — `COPY web/ /usr/share/nginx/html/web/` を追加
- **`sys/backend/docker-compose.prod.yml`** — `./nginx/web:/usr/share/nginx/html/web:ro` ボリュームマウントを追加

### デプロイ手順

```bash
# 1. Web ビルド
./sys/scripts/build-web.sh

# 2. Docker デプロイ
cd sys/backend
docker-compose -f docker-compose.prod.yml up --build -d
```

---

## 変更ファイル一覧

### 新規作成 (18 ファイル)

| # | ファイル |
|---|---------|
| 1 | `doc/phase2-web-plan.md` |
| 2 | `lib/utils/platform_utils.dart` |
| 3 | `lib/utils/platform_utils_stub.dart` |
| 4 | `lib/utils/platform_utils_native.dart` |
| 5 | `lib/services/platform_init_service.dart` |
| 6 | `lib/services/platform_init_stub.dart` |
| 7 | `lib/services/platform_init_native.dart` |
| 8 | `lib/services/social_auth_stub.dart` |
| 9 | `lib/services/social_auth_native.dart` |
| 10 | `.env.web` |
| 11 | `lib/router/app_router.dart` |
| 12 | `lib/widgets/app_shell.dart` |
| 13 | `lib/widgets/responsive_layout.dart` |
| 14 | `lib/widgets/content_constraint.dart` |
| 15 | `lib/widgets/desktop_nav_bar.dart` |
| 16 | `lib/widgets/desktop_sidebar.dart` |
| 17 | `lib/widgets/hover_card.dart` |
| 18 | `lib/widgets/keyboard_shortcuts.dart` |
| 19 | `sys/scripts/build-web.sh` |

### 修正 (22 ファイル)

| # | ファイル |
|---|---------|
| 1 | `lib/main.dart` |
| 2 | `lib/api/api_client.dart` |
| 3 | `lib/services/auth_service.dart` |
| 4 | `lib/services/social_auth_service.dart` |
| 5 | `lib/repositories/user_repository.dart` |
| 6 | `pubspec.yaml` |
| 7 | `lib/screens/home_screen.dart` |
| 8 | `lib/screens/feed_screen.dart` |
| 9 | `lib/screens/write_screen.dart` |
| 10 | `lib/screens/notification_screen.dart` |
| 11 | `lib/screens/profile_screen.dart` |
| 12 | `lib/screens/login_screen.dart` |
| 13 | `lib/screens/register_screen.dart` |
| 14 | `lib/screens/quiz_detail_screen.dart` |
| 15 | `lib/screens/answer_detail_screen.dart` |
| 16 | `lib/screens/comment_screen.dart` |
| 17 | `lib/screens/user_profile_screen.dart` |
| 18 | `lib/screens/rankings_screen.dart` |
| 19 | `lib/screens/follow_list_screen.dart` |
| 20 | `lib/screens/category_quizzes_screen.dart` |
| 21 | `lib/widgets/answer_card.dart` |
| 22 | `web/index.html` |
| 23 | `web/manifest.json` |
| 24 | `sys/backend/nginx/nginx.conf` |
| 25 | `sys/backend/nginx/Dockerfile` |
| 26 | `sys/backend/docker-compose.prod.yml` |
