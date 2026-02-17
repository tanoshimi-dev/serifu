# Serifu 開発計画書

## 概要

Serifu (セリフ) は、AIが生成するシチュエーションクイズに対してクリエイティブなセリフを投稿し、コミュニティと交流するSNSアプリ。本書は、モバイルアプリ完成からWeb版展開までの開発ロードマップを定義する。

---

## 現状分析

### 完成度

| コンポーネント | 技術スタック | 完成度 | 状態 |
|---------------|-------------|--------|------|
| Backend API | Go + Gin + GORM + PostgreSQL | ~95% | 主要API完成、通知API実装済み |
| Mobile App | Flutter + Provider | ~85% | 14画面実装済 (通知画面追加)、UI改善中 |
| Web App | (未着手) | 0% | 構想のみ |
| Landing Page | Vue 3 + Vite | ~20% | 基本構造のみ |
| Admin Panel | Go templ | ~60% | クイズ管理・ユーザー管理 |

### 実装済み機能

- ユーザー認証 (JWT: 登録・ログイン)
- デイリークイズ表示 (毎日5問)
- セリフ投稿 (150文字制限)
- カテゴリー別閲覧 (8カテゴリー)
- いいね・コメント機能
- フォロー・フォロワー機能
- ランキング (デイリー/ウィークリー/全期間)
- トレンド表示
- 回答シェア機能
- 管理者ダッシュボード
- ソーシャルログイン (Google / Apple / LINE)
- 通知機能 (いいね・コメント・フォロー通知)

### 未実装の機能

- プロフィール画像アップロード
- プッシュ通知 (FCM)
- フォロー中ユーザーのタイムライン
- Web版アプリ
- ランディングページ完成

---

## 開発戦略: なぜ Flutter Web を選ぶか

### 選択肢の比較

| 方式 | コード共有率 | 開発コスト | 保守コスト | UI品質 |
|------|------------|-----------|-----------|--------|
| **Flutter Web (推奨)** | ~90% | 低 | 低 | 良 |
| React / Next.js | 0% | 高 | 高 | 優 |
| Vue.js / Nuxt.js | 0% | 高 | 高 | 優 |

### Flutter Web を推奨する理由

1. **コードの一元管理**: モバイルとWebで同じDartコードを使用。ビジネスロジック、モデル、API通信は100%共有
2. **開発速度**: 新機能を1回の実装で両プラットフォームに反映
3. **保守コスト削減**: バグ修正も1箇所で完了。2つのフロントエンドを保守する必要がない
4. **少人数開発に最適**: 1-2人のチームで両プラットフォームをカバー可能
5. **既存資産の活用**: pubspec.yaml に既にWeb対応の設定がある

### Flutter Web の注意点

- SEO対策が弱い (SPAのため) → ランディングページは別途Vue.jsで対応済み
- 初回読み込みが少し遅い → Service Worker + キャッシュで軽減可能
- Web特有のレスポンシブ対応が必要 → LayoutBuilder で分岐

---

## 開発フェーズ

### Phase 1: モバイルアプリ完成 + テスト公開

**目標**: 既存モバイルアプリを完成させ、テスト公開できる状態にする

#### 1-1. ソーシャルログイン (Google / Apple / LINE) ✅ 実装済み

ユーザー登録・ログインのハードルを下げるため、ソーシャルログインを導入する。

**Backend:**

```
# 新規テーブル
social_accounts:
  - id (UUID)
  - user_id (UUID)           # usersテーブルへの外部キー
  - provider (string)        # google, apple, line
  - provider_user_id (string) # 各プロバイダーのユーザーID
  - email (string, nullable)
  - display_name (string, nullable)
  - avatar_url (string, nullable)
  - access_token (string)
  - refresh_token (string, nullable)
  - token_expires_at (timestamp, nullable)
  - created_at (timestamp)
  - updated_at (timestamp)

# UNIQUE制約: (provider, provider_user_id)

# 新規エンドポイント
POST   /api/v1/auth/google    # Googleログイン (IDトークン検証)
POST   /api/v1/auth/apple     # Appleログイン (認証コード検証)
POST   /api/v1/auth/line      # LINEログイン (認証コード検証)
GET    /api/v1/users/me/social-accounts  # 連携済みソーシャルアカウント一覧
POST   /api/v1/users/me/social-accounts/link    # 既存アカウントにソーシャル連携追加
DELETE /api/v1/users/me/social-accounts/:provider # ソーシャル連携解除
```

**各プロバイダーの認証フロー:**

| プロバイダー | モバイル側 | Backend検証 |
|-------------|-----------|------------|
| Google | `google_sign_in` パッケージでIDトークン取得 | Google公開鍵でIDトークン検証 |
| Apple | `sign_in_with_apple` パッケージで認証コード取得 | Apple TokenエンドポイントでIDトークン取得・検証 |
| LINE | `flutter_line_sdk` パッケージでアクセストークン取得 | LINE Profile APIでユーザー情報取得・検証 |

**Backend 実装詳細:**

- `social_auth.go` ハンドラー追加
- 各プロバイダーごとの検証ロジック:
  - **Google**: `google.golang.org/api/idtoken` でIDトークン検証
  - **Apple**: JWKSエンドポイントから公開鍵取得、JWTを検証
  - **LINE**: アクセストークンを使って `https://api.line.me/v2/profile` を呼び出し
- 共通処理: プロバイダーユーザーIDで既存ユーザー検索 → 存在すればログイン、なければ新規作成
- 既存メール/パスワードアカウントとの連携 (同一メールアドレスの場合は自動リンク)
- JWTトークン発行 (既存の認証フローと統一)

**Mobile 実装:**

- ログイン画面にソーシャルログインボタン追加 (Google / Apple / LINE)
- 各プロバイダーのFlutterパッケージ導入:
  - `google_sign_in` (Google)
  - `sign_in_with_apple` (Apple)
  - `flutter_line_sdk` (LINE)
- `SocialAuthRepository` 追加
- 設定画面にソーシャルアカウント連携管理UI追加
- Apple Sign In は iOS のみ表示 (Appleガイドライン準拠)

**各プロバイダーのセットアップ:**

- **Google**: Google Cloud Console でOAuth 2.0クライアントID作成 (iOS / Android / Web)
- **Apple**: Apple Developer Portal で Sign in with Apple 設定、Service ID作成
- **LINE**: LINE Developers Console でチャネル作成、Callback URL設定

#### 1-2. 通知システム (Backend + Mobile) ✅ 実装済み

**Backend 追加API:**

```
# 新規テーブル
notifications:
  - id (UUID)
  - user_id (UUID)        # 通知を受け取るユーザー
  - actor_id (UUID)       # アクションを起こしたユーザー
  - type (string)         # like, comment, follow
  - target_type (string)  # answer, comment, user
  - target_id (UUID)      # 対象のID
  - is_read (bool)        # 既読フラグ
  - created_at (timestamp)

# 新規エンドポイント
GET    /api/v1/notifications          # 通知一覧 (認証必須)
PUT    /api/v1/notifications/read-all # 全件既読 (認証必須)
GET    /api/v1/notifications/unread-count # 未読数 (認証必須)
```

**Mobile 実装:**
- `NotificationScreen` 画面追加
- `NotificationRepository` 追加
- `NotificationModel` 追加
- BottomNavigationBar にバッジ表示 (未読数)
- 通知タップで該当画面に遷移

**Backend 実装:**
- `Notification` モデル追加 (GORM)
- `notification.go` ハンドラー追加
- いいね・コメント・フォロー時に通知レコード自動作成
- ルーターに通知エンドポイント追加

#### 1-3. プロフィール画像アップロード

**Backend:**
- `POST /api/v1/users/avatar` エンドポイント追加
- マルチパートフォームデータ対応
- 画像保存先: ローカルストレージ
- 画像リサイズ処理 (サムネイル生成)
- 静的ファイル配信設定

**Mobile:**
- `image_picker` パッケージ追加
- プロフィール画面に画像選択・アップロードUI
- カメラ or ギャラリーから選択

#### 1-4. フォロータイムライン

**Backend:**
- `GET /api/v1/timeline` エンドポイント追加
- フォロー中ユーザーの回答を時系列で取得
- ページネーション対応

**Mobile:**
- Feed画面にタブ追加: 「全体」「フォロー中」
- Pull-to-refresh対応

#### 1-5. UI/UX仕上げ

- ホーム画面のデザイン統一
- カラーパレット適用 (Primary: #6C5CE7)
- ローディングインジケーター追加
- エラー画面・空状態の表示改善
- スプラッシュスクリーン
- アプリアイコン設定

#### 1-6. テスト公開準備

- iOS: TestFlight配信設定
- Android: Google Play内部テスト設定
- バグ修正・動作確認

---

### Phase 2: Flutter Web でブラウザ版リリース

**目標**: 既存のFlutterコードをWeb版として公開

#### 2-1. レスポンシブ対応

```dart
// lib/widgets/responsive_layout.dart
// LayoutBuilder を使って画面幅に応じてレイアウトを切り替え
// Mobile: < 768px  (既存レイアウトそのまま)
// Tablet: 768-1024px (2カラム)
// Desktop: > 1024px (サイドバー + メインコンテンツ)
```

**対応内容:**
- `ResponsiveLayout` ウィジェット作成
- デスクトップ用サイドバー (ランキング、トレンド、おすすめユーザー)
- ナビゲーションの切り替え (モバイル: BottomNav → デスクトップ: TopNav + Sidebar)
- クイズカード・回答カードのグリッド表示 (デスクトップ)

#### 2-2. Web固有の対応

- URL ルーティング (GoRouter or go_router)
- ブラウザバック/フォワード対応
- キーボードショートカット
- マウスホバー効果
- Service Worker設定 (オフライン対応・キャッシュ)
- favicon, OGP タグ設定

#### 2-3. デプロイ

- `flutter build web` でビルド
- Nginx設定追加 (Web版配信)
- Docker Compose にWeb版追加
- SSL証明書設定 (Let's Encrypt)

---

### Phase 3: ランディングページ完成 + 公開

**目標**: アプリへの導線となるLPを完成させる

#### 3-1. LP コンテンツ完成

既存のVue 3プロジェクト (`sys/frontend/lp`) を完成させる:

- **HeroSection**: キャッチコピー + アプリスクリーンショット + DLボタン
- **FeaturesSection**: 主要機能3-4つの紹介
- **HowItWorks**: 使い方ステップ (3ステップ)
- **ExampleSection**: 実際のクイズ例とセリフ例を表示
- **CategoriesSection**: 8カテゴリーのビジュアル紹介
- **CtaSection**: ダウンロードCTA + Web版リンク
- **FooterSection**: プライバシーポリシー、利用規約、お問い合わせ

#### 3-2. LP デプロイ

- カスタムドメイン設定
- SEO対策 (meta tags, sitemap.xml)
- Google Analytics導入
- App Store / Google Play リンク設置

---

### Phase 4: 新機能追加 (差別化)

**目標**: ユーザーエンゲージメントを高める新機能

#### 4-1. バトルモード (対決機能)

2人のユーザーが同じお題で対決し、他のユーザーの投票で勝敗を決める。

**Backend:**
```
# 新規テーブル
battles:
  - id (UUID)
  - quiz_id (UUID)
  - challenger_answer_id (UUID)
  - opponent_answer_id (UUID)
  - status (pending/active/finished)
  - challenger_votes (int)
  - opponent_votes (int)
  - winner_id (UUID, nullable)
  - expires_at (timestamp)

battle_votes:
  - id (UUID)
  - battle_id (UUID)
  - user_id (UUID)
  - voted_for (UUID)  # answer_id

# 新規エンドポイント
POST   /api/v1/battles                 # バトル申請
GET    /api/v1/battles/active          # 開催中バトル一覧
GET    /api/v1/battles/:id             # バトル詳細
POST   /api/v1/battles/:id/vote       # 投票
```

**Mobile/Web:**
- バトル一覧画面
- バトル詳細画面 (2つの回答を左右に表示 + 投票ボタン)
- バトル結果画面
- バトル申請フロー

#### 4-2. バッジ/称号システム

ユーザーの活動に応じてバッジを付与し、モチベーションを維持。

**バッジ例:**

| バッジ名 | 条件 | アイコン |
|---------|------|---------|
| はじめてのセリフ | 初回回答 | 初心者マーク |
| 連続3日 | 3日連続回答 | 炎 |
| 連続7日 | 7日連続回答 | 星 |
| 連続30日 | 30日連続回答 | 王冠 |
| いいね100 | 累計いいね100獲得 | ハート |
| 人気者 | フォロワー50人 | メガホン |
| デイリーチャンプ | デイリーランキング1位 | トロフィー |

**Backend:**
```
# 新規テーブル
badges:
  - id (UUID)
  - name (string)
  - description (string)
  - icon (string)
  - condition_type (string)  # streak, total_likes, follower_count, ranking
  - condition_value (int)

user_badges:
  - id (UUID)
  - user_id (UUID)
  - badge_id (UUID)
  - earned_at (timestamp)

# 新規エンドポイント
GET    /api/v1/badges                  # バッジ一覧
GET    /api/v1/users/:id/badges       # ユーザーのバッジ
```

#### 4-3. AI回答ヒント

既存のGemini API連携を活用し、回答のヒントを提供。

**仕様:**
- クイズ詳細画面に「ヒントを見る」ボタン
- タップするとAIが3つのアプローチ例を提示 (直接的な回答ではない)
- 1日3回まで使用可能 (制限)

**Backend:**
```
POST   /api/v1/quizzes/:id/hint       # AIヒント生成
```

#### 4-4. シェア画像生成

回答をおしゃれなカード画像として生成し、X(Twitter)やInstagramでシェア可能に。

**仕様:**
- 回答詳細画面に「画像でシェア」ボタン
- サーバーサイドで画像生成 (Go: fogleman/gg 等)
- テンプレート: カテゴリー色 + クイズタイトル + セリフ + ユーザー名 + アプリロゴ

---

## 技術的な注意事項

### Backend

- **画像アップロード**: 本番環境ではS3互換ストレージ (AWS S3 or MinIO) を推奨
- **通知のリアルタイム性**: 初期はポーリング、将来的にWebSocket導入を検討
- **バッジ判定**: 非同期ジョブ (cron) で定期チェック、またはイベント駆動で即時判定
- **レート制限**: APIにレート制限を追加 (特にAIヒント機能)
- **ソーシャルログイン**: 各プロバイダーのクライアントID/シークレットは環境変数で管理。Apple Sign In はiOS必須 (App Store審査要件)、LINE は日本市場向けに重要

### Mobile / Web

- **状態管理**: Provider で十分だが、機能が増えた場合は Riverpod への移行を検討
- **画像キャッシュ**: `cached_network_image` パッケージ導入
- **オフライン対応**: 最低限のキャッシュ (デイリークイズ、自分の回答)
- **ディープリンク**: Web版公開後、アプリとWebの相互リンク設定

### インフラ

- **本番環境**: VPS or クラウド (AWS/GCP/ConoHa等)
- **CI/CD**: GitHub Actions でビルド・デプロイ自動化を推奨
- **監視**: 基本的なログ収集 + ヘルスチェック
- **バックアップ**: PostgreSQL の定期バックアップ設定

---

## 優先順位まとめ

```
Phase 1 (最優先)
├── 1-1. ソーシャルログイン    ✅ 実装済み (Google/Apple/LINE)
├── 1-2. 通知システム          ✅ 実装済み
├── 1-3. プロフィール画像      ← ユーザー体験に直結
├── 1-4. フォロータイムライン  ← SNS感を強化
├── 1-5. UI/UX仕上げ          ← 公開品質に必要
└── 1-6. テスト公開           ← フィードバック収集

Phase 2
├── 2-1. レスポンシブ対応      ← Web版の基盤
├── 2-2. Web固有の対応        ← ブラウザ体験の最適化
└── 2-3. デプロイ             ← 公開

Phase 3
├── 3-1. LP コンテンツ完成    ← 集客の入口
└── 3-2. LP デプロイ          ← 公開

Phase 4 (差別化)
├── 4-1. バトルモード         ← エンゲージメント向上
├── 4-2. バッジ/称号          ← リテンション向上
├── 4-3. AI回答ヒント         ← ユーザー体験向上
└── 4-4. シェア画像生成       ← 拡散力向上
```

---

## 更新履歴

| 日付 | 内容 |
|------|------|
| 2026-02-16 | 初版作成 |
| 2026-02-16 | Phase 1 にソーシャルログイン (Google/Apple/LINE) を追加 |
| 2026-02-17 | ソーシャルログイン実装完了に伴い 1-1 に移動、他ステップの順序を更新 |
| 2026-02-17 | 通知システム (1-2) 実装完了: Backend通知API + Mobile通知画面 + BottomNavBarバッジ |
