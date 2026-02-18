# Step 1-6: Test Guide — How to Run & Maintain Tests

**Last updated:** 2026-02-19

This document explains how to re-run all automated tests and what to check when adding new features.

---

## 1. Flutter Unit Tests

### Run all tests

```bash
cd sys/frontend/user/mobile/serifu
flutter test
```

### Run a specific test file

```bash
flutter test test/models/user_test.dart
```

### Run with verbose output

```bash
flutter test --reporter expanded
```

### Expected result

```
00:09 +68: All tests passed!
```

(48 unit tests + 20 E2E tests)

### Test file locations

```
test/
├── models/
│   ├── user_test.dart        # User fromJson, avatarInitial, displayName, copyWith
│   ├── quiz_test.dart        # Quiz/Category fromJson, toJson
│   ├── answer_test.dart      # Answer/Comment fromJson, toJson, copyWith
│   └── notification_test.dart # AppNotification fromJson, message, timeAgo
├── utils/
│   └── time_utils_test.dart  # timeAgo() Japanese format
├── theme/
│   └── app_theme_test.dart   # Color constants, ThemeData
├── api/
│   └── api_client_test.dart  # ApiException, token/userId management
├── helpers/
│   ├── mock_api.dart         # MockClient factory + response helpers
│   ├── test_data.dart        # Canned JSON response factories
│   └── test_app.dart         # Test DI setup + MaterialApp wrapper
└── e2e/
    ├── login_home_test.dart       # Scenario 1: Login → Home (3 tests)
    ├── quiz_answer_test.dart      # Scenario 2: Quiz → Answer (3 tests)
    ├── like_comment_test.dart     # Scenario 3: Like & Comment (4 tests)
    ├── profile_edit_test.dart     # Scenario 4: Profile Edit (4 tests)
    ├── notification_test.dart     # Scenario 5: Notifications (3 tests)
    └── follow_unfollow_test.dart  # Scenario 6: Follow/Unfollow (3 tests)
```

### When to update

- **Added a new model field?** → Update `fromJson` tests, add field assertion
- **Changed a model's `copyWith`?** → Update copyWith tests
- **Changed `toJson` serialization?** → Update toJson tests
- **Added a new util function?** → Add test file under `test/utils/`
- **Changed theme colors?** → Update `app_theme_test.dart`

---

## 2. Flutter E2E Tests (Widget Tests with Mocked HTTP)

Full user-flow tests using `flutter_test` widget tests with `MockClient` from `package:http/testing.dart`. No running backend, device/emulator, or LINE SDK required.

### Run all E2E tests

```bash
cd sys/frontend/user/mobile/serifu
flutter test test/e2e/
```

### Run a specific scenario

```bash
flutter test test/e2e/login_home_test.dart
flutter test test/e2e/quiz_answer_test.dart
flutter test test/e2e/like_comment_test.dart
flutter test test/e2e/profile_edit_test.dart
flutter test test/e2e/notification_test.dart
flutter test test/e2e/follow_unfollow_test.dart
```

### Expected result

```
00:05 +20: All tests passed!
```

### Test scenarios (20 tests)

| Scenario | File | Tests | Description |
|----------|------|-------|-------------|
| 1. Login → Home | `login_home_test.dart` | 3 | Login success → HomeScreen, login failure error, login ↔ register navigation |
| 2. Quiz → Answer | `quiz_answer_test.dart` | 3 | Quiz list → detail → submit answer, empty answer validation, See Other Answers → FeedScreen |
| 3. Like & Comment | `like_comment_test.dart` | 4 | Like (optimistic UI), unlike, navigate to comments + post, empty comments state |
| 4. Profile Edit | `profile_edit_test.dart` | 4 | Display user info + stats, edit mode save, cancel edit, logout → LoginScreen |
| 5. Notifications | `notification_test.dart` | 3 | Display notifications (like/comment/follow), tap → AnswerDetailScreen, empty state |
| 6. Follow/Unfollow | `follow_unfollow_test.dart` | 3 | Follow user, unfollow user, own profile redirects to ProfileScreen |

### How it works

- **`test/helpers/mock_api.dart`** — Creates `MockClient` that dispatches on `METHOD /path` patterns (supports `:id` wildcards)
- **`test/helpers/test_data.dart`** — Canned JSON factories (`testUserJson()`, `testQuizJson()`, etc.) matching model `fromJson` contracts
- **`test/helpers/test_app.dart`** — `setupTestApiClient()` overrides global singletons with test `ApiClient` using `MockClient`; `testApp()` wraps screens in `MaterialApp`
- Each test calls `setupTestApiClient(mockClient)` in setup and `tearDownTestApiClient()` in tearDown
- Production code change: global singletons (`apiClient`, repositories, `authService`) are reassignable (`var` instead of `final`) for DI in tests — zero behavioral change in production

### When to update

- **Added a new screen/flow?** → Add E2E test under `test/e2e/`
- **Changed API response format?** → Update `test/helpers/test_data.dart` JSON factories
- **Added a new API endpoint?** → Add handler in test's `createMockClient(handlers: {...})`
- **Changed UI text/labels?** → Update `find.text()` / `find.textContaining()` assertions
- **Added a new repository singleton?** → Add override in `test/helpers/test_app.dart` `setupTestApiClient()`

---

## 3. Flutter Static Analysis

### Run

```bash
cd sys/frontend/user/mobile/serifu
flutter analyze
```

### Expected result

```
Analyzing serifu...
No issues found!
```

Run this after every code change to catch lint issues early.

---

## 4. Go Backend Unit Tests

### Run via Docker (recommended)

No Go installation needed. Uses `Dockerfile.test` with the full Go toolchain.

```bash
cd sys/backend
docker compose -f docker-compose.dev.yml run --rm --build test
```

This builds a test image from `app/Dockerfile.test`, runs all tests with CGO enabled, and removes the container when done.

### Run locally (requires Go)

Prerequisites: Go 1.21+, CGO enabled (required for SQLite driver)

```bash
cd sys/backend/app
go mod tidy
CGO_ENABLED=1 go test ./... -v
```

### Run tests for a specific package

```bash
# Handler tests only
CGO_ENABLED=1 go test ./internal/handlers/ -v

# Middleware tests only
CGO_ENABLED=1 go test ./internal/middleware/ -v

# Utils tests only
CGO_ENABLED=1 go test ./internal/utils/ -v
```

### Run a specific test

```bash
CGO_ENABLED=1 go test ./internal/handlers/ -v -run TestRegisterSuccess
```

### Expected result

All ~71 tests should pass.

### Test file locations

```
internal/
├── handlers/
│   ├── testhelper_test.go      # Shared: setupTestDB, createTest*, performRequest, parseResponse
│   ├── auth_test.go            # Register, Login, GetMe (10 tests)
│   ├── answer_test.go          # CRUD answers, pagination, ownership (11 tests)
│   ├── like_test.go            # Like/unlike, counts, notifications (6 tests)
│   ├── comment_test.go         # CRUD comments, notifications (6 tests)
│   ├── follow_test.go          # Follow/unfollow, lists (7 tests)
│   ├── user_test.go            # Profile, update, ownership (7 tests)
│   ├── notification_test.go    # Notifications, mark read, unread count (5 tests)
│   ├── quiz_test.go            # Daily, CRUD, pagination, category filter (6 tests)
│   └── ranking_test.go         # Trending, daily, all-time, categories (4 tests)
├── middleware/
│   └── auth_test.go            # JWT, X-User-ID fallback, no auth (5 tests)
└── utils/
    └── response_test.go        # Success, error, paginated responses (4 tests)
```

### How tests work

- Each test calls `setupTestDB(t)` which creates a **fresh in-memory SQLite** database
- Tests are fully isolated — no shared state between tests
- A GORM `BeforeCreate` callback generates UUIDs (replacing PostgreSQL's `gen_random_uuid()`)
- Helper functions (`createTestUser`, `createTestQuiz`, etc.) set up test data
- `performRequest()` sends HTTP requests to Gin router via `httptest`
- **No external services required** — no PostgreSQL, no network

### When to update

- **Added a new handler?** → Create `{handler}_test.go`, add tests for success + error cases
- **Added a new route?** → Test via the appropriate handler test file
- **Changed validation rules?** → Update the corresponding test (e.g., max length, required fields)
- **Added a new model?** → Add to `setupTestDB()` AutoMigrate list and create helper function
- **Changed response format?** → Update `parseResponse` assertions

---

## 5. Flutter Integration Tests

### Prerequisites

- iOS Simulator or Android emulator running
- **Note:** These tests do NOT require a running backend server

### Run on simulator

```bash
cd sys/frontend/user/mobile/serifu
flutter test integration_test/
```

### Run with a specific device

```bash
flutter test integration_test/ -d "iPhone 16"
```

### Test file locations

```
integration_test/
└── app_test.dart            # Screen rendering, navigation, theme (7 tests)

test_driver/
└── integration_test.dart    # Standard integration test driver
```

### What is tested

| Test | Description |
|------|-------------|
| Login screen renders | Verifies TextFormField widgets and login text |
| Register screen renders | Verifies form fields exist |
| Home screen loading | Verifies Scaffold renders in loading state |
| Notification screen renders | Verifies screen structure |
| Profile screen renders | Verifies screen structure |
| Login → Register navigation | Taps "アカウント" link, verifies RegisterScreen |
| Theme colors applied | Verifies theme is applied to scaffold |

### Design note

`main()` calls `LineSDK.instance.setup()` which throws `MissingPluginException` in tests. Integration tests wrap individual screens in `MaterialApp` instead of launching the full app.

### When to update

- **Added a new screen?** → Add a render test wrapping it in `MaterialApp`
- **Changed navigation flow?** → Update navigation tests
- **Changed screen layout significantly?** → Update finder assertions

---

## 6. CI/CD Checklist

When setting up CI, run these commands in order:

```bash
# 1. Flutter unit tests + E2E tests + analysis
cd sys/frontend/user/mobile/serifu
flutter pub get
flutter analyze
flutter test              # runs all 68 tests (unit + E2E)
flutter test test/e2e/    # E2E tests only (optional, already included above)

# 2. Go backend tests (via Docker)
cd sys/backend
docker compose -f docker-compose.dev.yml run --rm --build test

# 2b. Or locally if Go is installed
# cd sys/backend/app
# go mod tidy
# CGO_ENABLED=1 go test ./... -v

# 3. Flutter integration tests (requires simulator — typically skipped in CI)
# cd sys/frontend/user/mobile/serifu
# flutter test integration_test/
```

---

## 7. Adding Tests for New Features

### Flutter model tests

```dart
// test/models/{model}_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:serifu/models/{model}.dart';

void main() {
  group('{Model}.fromJson', () {
    test('parses full fields', () {
      final json = { /* all fields */ };
      final model = Model.fromJson(json);
      expect(model.field, expectedValue);
    });

    test('uses defaults for null fields', () {
      final json = { /* minimal fields */ };
      final model = Model.fromJson(json);
      expect(model.optionalField, defaultValue);
    });
  });
}
```

### Go handler tests

```go
// internal/handlers/{handler}_test.go
func TestNewEndpointSuccess(t *testing.T) {
    db := setupTestDB(t)
    router := setupYourRouter()  // Create Gin router with your handler
    // Create test data with helpers
    user := createTestUser(t, db, "User", "user@test.com", "pass123")

    body := map[string]string{"field": "value"}
    headers := map[string]string{"X-User-ID": user.ID.String()}

    w := performRequest(router, "POST", "/api/v1/your-endpoint", body, headers)

    if w.Code != http.StatusCreated {
        t.Errorf("expected 201, got %d: %s", w.Code, w.Body.String())
    }
}
```

---

## 8. Troubleshooting

| Problem | Solution |
|---------|----------|
| `flutter test` fails with dotenv error | Unit tests don't use `dotenv`. Check you're not importing `main.dart` in tests |
| E2E test `pumpAndSettle` times out | Add `SharedPreferences.setMockInitialValues({})` in `setUp`. Use `pump(Duration)` instead of `pumpAndSettle` for screens with `Image.asset` |
| E2E test can't find widget (off-screen) | Use `tester.ensureVisible()` before tap, or `tester.drag()` for lazy `ListView` |
| E2E test "Too many elements" on scroll | Use `tester.drag(find.byType(ListView), Offset(0, -400))` instead of `scrollUntilVisible` |
| Go tests fail with `CGO_ENABLED` error | Set `CGO_ENABLED=1` before `go test`. SQLite requires CGO |
| Go tests fail with `database locked` | Each test should call `setupTestDB(t)` for a fresh DB |
| Integration tests crash with `MissingPluginException` | Don't launch full app. Wrap screens in `MaterialApp` individually |
| `go mod tidy` fails | Run `go get gorm.io/driver/sqlite` first |
| `go: not found` in Docker container | The runtime container has no Go (multi-stage build). Use `docker compose -f docker-compose.dev.yml run --rm --build test` instead |
| `go: not found` on Mac | Go is not installed locally. Use the Docker test command above |
