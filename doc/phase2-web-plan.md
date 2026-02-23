# Phase 2: Flutter Web ブラウザ版リリース 実装計画

## Context

Serifu のモバイルアプリ (Flutter) はほぼ完成しており、Phase 2 では同じ Flutter コードを Web 版として公開する。現在のアプリは `Navigator.push()` によるスタックベースのナビゲーション、`setState()` による状態管理、モバイル専用の BottomNavigationBar を使用している。Web 対応には、プラットフォーム抽象化、URL ルーティング、レスポンシブレイアウト、デプロイ設定が必要。

---

## Step 1: プラットフォーム抽象化 (Web でコンパイル可能にする)

**目的**: `dart:io` や Web 非対応パッケージを条件分岐で分離し、`flutter build web` を通す

### 新規作成ファイル

| ファイル | 内容 |
|---------|------|
| `lib/utils/platform_utils.dart` | `kIsWeb`, `isIOS`, `isAndroid` のファサード |
| `lib/utils/platform_utils_stub.dart` | Web 用スタブ (dart:io なし) |
| `lib/utils/platform_utils_native.dart` | Native 用 (dart:io.Platform) |
| `lib/services/platform_init_service.dart` | 初期化サービス抽象クラス |
| `lib/services/platform_init_stub.dart` | Web 用 no-op 実装 |
| `lib/services/platform_init_native.dart` | Native 用 (flutter_native_splash + LINE SDK) |
| `lib/services/social_auth_stub.dart` | Web 用ソーシャル認証 (Google のみ) |
| `lib/services/social_auth_native.dart` | Native 用ソーシャル認証 (全プロバイダー) |
| `.env.web` | Web 用環境変数 (`API_BASE_URL=/api/v1`) |

### 修正ファイル

- **`lib/main.dart`** -- `flutter_line_sdk` / `flutter_native_splash` の直接 import を条件分岐化、Web では `.env.web` をロード
- **`lib/api/api_client.dart`** -- `dart:io` 削除、Web では `API_BASE_URL=/api/v1`(同一オリジン)、`uploadFile` を bytes ベースに
- **`lib/services/social_auth_service.dart`** -- conditional import パターンで Web/Native 分岐
- **`lib/screens/login_screen.dart`** / **`register_screen.dart`** -- `Platform.isIOS` を `platform_utils.isIOS` に、Web では Google のみ表示
- **`lib/screens/profile_screen.dart`** -- `dart:io.File` を XFile に置換、Web ではカメラ選択肢を非表示
- **`lib/repositories/user_repository.dart`** -- `File` パラメータを bytes ベースに
- **`pubspec.yaml`** -- `.env.web` をアセットに追加

### 検証
`flutter build web --release` が成功すること。ブラウザでログイン画面が表示され、Google ログインボタンのみ表示されること。

---

## Step 2: go_router によるURL ルーティング

**目的**: `Navigator.push()` を `go_router` に移行し、ブラウザバック/フォワード・ディープリンクに対応

### 新規作成ファイル

| ファイル | 内容 |
|---------|------|
| `lib/router/app_router.dart` | GoRouter 設定 (認証ガード + ShellRoute) |
| `lib/widgets/app_shell.dart` | ナビゲーションシェル (後のステップでレスポンシブ化) |

### ルート定義

```
/login              -> LoginScreen
/register           -> RegisterScreen
/ (ShellRoute)
  /                 -> HomeScreen
  /feed             -> FeedScreen
  /write            -> WriteScreen
  /notifications    -> NotificationScreen
  /profile          -> ProfileScreen
  /rankings         -> RankingsScreen
  /quiz/:id         -> QuizDetailScreen
  /answer/:id       -> AnswerDetailScreen
  /answer/:id/comments -> CommentScreen
  /user/:id         -> UserProfileScreen
  /user/:id/followers -> FollowListScreen
  /user/:id/following -> FollowListScreen
  /category/:id     -> CategoryQuizzesScreen
```

### 修正ファイル

- **`lib/main.dart`** -- `MaterialApp` を `MaterialApp.router(routerConfig: appRouter)` に、AuthGate 削除
- **`lib/services/auth_service.dart`** -- 同期的な `isLoggedInSync` getter 追加
- **全14画面ファイル** -- `Navigator.push()` を `context.go()` / `context.push()` に
- **`lib/widgets/bottom_nav_bar.dart`** -- タブ切替を `context.go()` に
- **`pubspec.yaml`** -- `go_router: ^14.0.0` 追加
- **詳細画面 (QuizDetail, AnswerDetail 等)** -- `extra` が null の場合 API から ID でフェッチするフォールバック追加

### 検証
ブラウザの URL バーにパスが反映される。戻る/進むボタンが正常動作。`/quiz/:id` に直接アクセスして画面が表示される。モバイルアプリも正常動作。

---

## Step 3: レスポンシブレイアウト

**目的**: Mobile/Tablet/Desktop でレイアウトを切り替え

### ブレークポイント
- Mobile: < 768px (既存レイアウトそのまま)
- Tablet: 768-1024px (2カラム)
- Desktop: > 1024px (TopNav + サイドバー + メインコンテンツ)

### 新規作成ファイル

| ファイル | 内容 |
|---------|------|
| `lib/widgets/responsive_layout.dart` | LayoutBuilder でブレークポイント分岐 |
| `lib/widgets/desktop_nav_bar.dart` | デスクトップ用トップナビ (グラデーション背景) |
| `lib/widgets/desktop_sidebar.dart` | 右サイドバー (ランキング、トレンド、カテゴリ) |
| `lib/widgets/content_constraint.dart` | maxWidth 制約ラッパー (680px) |

### 修正ファイル

- **`lib/widgets/app_shell.dart`** -- `ResponsiveLayout` で Mobile/Desktop シェルを切替
- **各画面ファイル** -- BottomNavBar を各画面から削除 (シェルに委任)
- **`lib/screens/home_screen.dart`** -- `_onNavTap` / BottomNavBar 削除
- **`lib/screens/feed_screen.dart`** / **`write_screen.dart`** -- Desktop では GridView 表示

### 検証
ブラウザのウィンドウサイズ変更でレイアウトが切り替わる。Desktop ではサイドバーにランキング・トレンドが表示される。モバイルビルドは変更なし。

---

## Step 4: Web 固有の機能

**目的**: ブラウザ体験の最適化

### 新規作成ファイル

| ファイル | 内容 |
|---------|------|
| `lib/widgets/hover_card.dart` | MouseRegion によるホバーエフェクト |
| `lib/widgets/keyboard_shortcuts.dart` | グローバルキーボードショートカット |

### 修正ファイル

- **`lib/widgets/answer_card.dart`** / **`quiz_card.dart`** -- HoverCard でラップ
- **`lib/main.dart`** -- KeyboardShortcuts ウィジェットでラップ
- **`web/index.html`** -- OGP メタタグ追加
- **`web/manifest.json`** -- テーマカラー `#6C5CE7`、アプリ名更新

### キーボードショートカット
- `H`: Home、`F`: Feed、`W`: Write、`N`: Notifications、`P`: Profile、`Esc`: Back

### 検証
カードにマウスホバーでシャドウアニメーション。キーボードでタブ切替。OGP タグが SNS シェア時に表示。

---

## Step 5: デプロイ

**目的**: Flutter Web を既存インフラで配信

### 修正ファイル

- **`sys/backend/nginx/nginx.conf`** -- SPA ルーティング追加
- **`sys/backend/nginx/Dockerfile`** -- `COPY web/ /usr/share/nginx/html/web/`
- **`sys/backend/docker-compose.prod.yml`** -- web ビルド成果物のマウント追加

### 新規作成ファイル

| ファイル | 内容 |
|---------|------|
| `sys/scripts/build-web.sh` | `flutter build web` -> nginx/web/ にコピー |

### 検証
`docker-compose up` で Web アプリがルート URL で表示。`/api/` は引き続きバックエンドにプロキシ。SPA ルーティングで `/feed` 等に直接アクセス可能。

---

## 実装順序

| # | ステップ | 新規ファイル | 修正ファイル |
|---|---------|-------------|-------------|
| 1 | Platform 抽象化 + .env.web | 9 | 8 |
| 2 | go_router 導入 | 2 | 16 |
| 3 | レスポンシブレイアウト | 4 | 6 |
| 4 | Web 固有機能 | 2 | 5 |
| 5 | デプロイ | 1 | 3 |

**合計**: 新規 18 ファイル、修正 ~25 ファイル

---

## 主要リスクと対策

| リスク | 対策 |
|--------|------|
| go_router 移行中にモバイルが壊れる | 画面を1つずつ移行、各画面後にテスト |
| `flutter_line_sdk` が Web で import エラー | conditional import (stub/native 分割) で完全隔離 |
| 詳細画面に直接 URL アクセスで extra が null | ID から API フェッチするフォールバック実装 |
| 初回バンドルサイズが大きい | Service Worker キャッシュ、`--dart2js-optimization O4` |
