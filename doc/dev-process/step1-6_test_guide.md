# Step 1-6: Test Guide — How to Run & Maintain Tests

**Last updated:** 2026-02-17

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
00:07 +48: All tests passed!
```

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
└── api/
    └── api_client_test.dart  # ApiException, token/userId management
```

### When to update

- **Added a new model field?** → Update `fromJson` tests, add field assertion
- **Changed a model's `copyWith`?** → Update copyWith tests
- **Changed `toJson` serialization?** → Update toJson tests
- **Added a new util function?** → Add test file under `test/utils/`
- **Changed theme colors?** → Update `app_theme_test.dart`

---

## 2. Flutter Static Analysis

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

## 3. Go Backend Unit Tests

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

## 4. Flutter Integration Tests

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

## 5. CI/CD Checklist

When setting up CI, run these commands in order:

```bash
# 1. Flutter unit tests + analysis
cd sys/frontend/user/mobile/serifu
flutter pub get
flutter analyze
flutter test

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

## 6. Adding Tests for New Features

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

## 7. Troubleshooting

| Problem | Solution |
|---------|----------|
| `flutter test` fails with dotenv error | Unit tests don't use `dotenv`. Check you're not importing `main.dart` in tests |
| Go tests fail with `CGO_ENABLED` error | Set `CGO_ENABLED=1` before `go test`. SQLite requires CGO |
| Go tests fail with `database locked` | Each test should call `setupTestDB(t)` for a fresh DB |
| Integration tests crash with `MissingPluginException` | Don't launch full app. Wrap screens in `MaterialApp` individually |
| `go mod tidy` fails | Run `go get gorm.io/driver/sqlite` first |
| `go: not found` in Docker container | The runtime container has no Go (multi-stage build). Use `docker compose -f docker-compose.dev.yml run --rm --build test` instead |
| `go: not found` on Mac | Go is not installed locally. Use the Docker test command above |
