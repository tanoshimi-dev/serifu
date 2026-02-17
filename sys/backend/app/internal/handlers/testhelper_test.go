package handlers_test

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/serifu/backend/internal/database"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

func init() {
	gin.SetMode(gin.TestMode)
}

func setupTestDB(t *testing.T) *gorm.DB {
	t.Helper()

	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Silent),
	})
	if err != nil {
		t.Fatalf("failed to open test database: %v", err)
	}

	// Register UUID generation callback for SQLite (PostgreSQL uses gen_random_uuid())
	db.Callback().Create().Before("gorm:create").Register("generate_uuid", func(tx *gorm.DB) {
		if tx.Statement.Schema == nil {
			return
		}
		for _, field := range tx.Statement.Schema.PrimaryFields {
			if field.DataType == "uuid" || field.GORMDataType == "uuid" {
				if val, isZero := field.ValueOf(tx.Statement.Context, tx.Statement.ReflectValue); isZero || val == uuid.Nil {
					_ = field.Set(tx.Statement.Context, tx.Statement.ReflectValue, uuid.New())
				}
			}
		}
	})

	// Create tables with raw SQL (SQLite-compatible, no gen_random_uuid())
	tables := []string{
		`CREATE TABLE IF NOT EXISTS users (
			id TEXT PRIMARY KEY,
			email TEXT UNIQUE NOT NULL,
			name TEXT NOT NULL,
			password_hash TEXT DEFAULT '',
			avatar TEXT DEFAULT '',
			bio TEXT DEFAULT '',
			total_likes INTEGER DEFAULT 0,
			status TEXT DEFAULT 'active',
			created_at DATETIME,
			updated_at DATETIME,
			deleted_at DATETIME
		)`,
		`CREATE TABLE IF NOT EXISTS categories (
			id TEXT PRIMARY KEY,
			name TEXT NOT NULL,
			description TEXT DEFAULT '',
			icon TEXT DEFAULT '',
			color TEXT DEFAULT '',
			sort_order INTEGER DEFAULT 0,
			status TEXT DEFAULT 'active',
			created_at DATETIME,
			updated_at DATETIME
		)`,
		`CREATE TABLE IF NOT EXISTS quizzes (
			id TEXT PRIMARY KEY,
			title TEXT NOT NULL,
			description TEXT DEFAULT '',
			requirement TEXT DEFAULT '',
			category_id TEXT,
			release_date DATETIME,
			status TEXT DEFAULT 'draft',
			answer_count INTEGER DEFAULT 0,
			created_at DATETIME,
			updated_at DATETIME,
			deleted_at DATETIME
		)`,
		`CREATE TABLE IF NOT EXISTS answers (
			id TEXT PRIMARY KEY,
			quiz_id TEXT NOT NULL,
			user_id TEXT NOT NULL,
			content TEXT NOT NULL,
			like_count INTEGER DEFAULT 0,
			comment_count INTEGER DEFAULT 0,
			view_count INTEGER DEFAULT 0,
			status TEXT DEFAULT 'active',
			created_at DATETIME,
			updated_at DATETIME,
			deleted_at DATETIME
		)`,
		`CREATE TABLE IF NOT EXISTS comments (
			id TEXT PRIMARY KEY,
			answer_id TEXT NOT NULL,
			user_id TEXT NOT NULL,
			content TEXT NOT NULL,
			status TEXT DEFAULT 'active',
			created_at DATETIME,
			updated_at DATETIME,
			deleted_at DATETIME
		)`,
		`CREATE TABLE IF NOT EXISTS likes (
			id TEXT PRIMARY KEY,
			answer_id TEXT NOT NULL,
			user_id TEXT NOT NULL,
			created_at DATETIME
		)`,
		`CREATE TABLE IF NOT EXISTS follows (
			id TEXT PRIMARY KEY,
			follower_id TEXT NOT NULL,
			following_id TEXT NOT NULL,
			created_at DATETIME
		)`,
		`CREATE TABLE IF NOT EXISTS notifications (
			id TEXT PRIMARY KEY,
			user_id TEXT NOT NULL,
			actor_id TEXT NOT NULL,
			type TEXT NOT NULL,
			target_type TEXT DEFAULT '',
			target_id TEXT DEFAULT '',
			is_read INTEGER DEFAULT 0,
			created_at DATETIME
		)`,
		`CREATE TABLE IF NOT EXISTS social_accounts (
			id TEXT PRIMARY KEY,
			user_id TEXT NOT NULL,
			provider TEXT NOT NULL,
			provider_id TEXT NOT NULL,
			email TEXT DEFAULT '',
			name TEXT DEFAULT '',
			avatar TEXT DEFAULT '',
			created_at DATETIME,
			updated_at DATETIME
		)`,
		`CREATE TABLE IF NOT EXISTS admin_users (
			id TEXT PRIMARY KEY,
			email TEXT UNIQUE NOT NULL,
			name TEXT NOT NULL,
			password_hash TEXT NOT NULL,
			role TEXT DEFAULT 'admin',
			status TEXT DEFAULT 'active',
			last_login_at DATETIME,
			created_at DATETIME,
			updated_at DATETIME
		)`,
		`CREATE TABLE IF NOT EXISTS admin_audit_logs (
			id TEXT PRIMARY KEY,
			admin_user_id TEXT NOT NULL,
			action TEXT NOT NULL,
			entity_type TEXT DEFAULT '',
			entity_id TEXT DEFAULT '',
			ip_address TEXT DEFAULT '',
			created_at DATETIME
		)`,
	}
	for _, sql := range tables {
		if err := db.Exec(sql).Error; err != nil {
			t.Fatalf("failed to create test table: %v\nSQL: %s", err, sql)
		}
	}

	// Set global DB for handlers
	database.DB = db

	return db
}

func createTestUser(t *testing.T, db *gorm.DB, name, email, password string) database.User {
	t.Helper()

	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.MinCost)
	if err != nil {
		t.Fatalf("failed to hash password: %v", err)
	}

	user := database.User{
		ID:           uuid.New(),
		Email:        email,
		Name:         name,
		PasswordHash: string(hash),
		Status:       "active",
		CreatedAt:    time.Now(),
		UpdatedAt:    time.Now(),
	}

	if err := db.Create(&user).Error; err != nil {
		t.Fatalf("failed to create test user: %v", err)
	}

	return user
}

func createTestQuiz(t *testing.T, db *gorm.DB, title, status string, releaseDate time.Time) database.Quiz {
	t.Helper()

	quiz := database.Quiz{
		ID:          uuid.New(),
		Title:       title,
		Description: "Test description",
		Requirement: "Test requirement",
		Status:      status,
		ReleaseDate: releaseDate,
		CreatedAt:   time.Now(),
		UpdatedAt:   time.Now(),
	}

	if err := db.Create(&quiz).Error; err != nil {
		t.Fatalf("failed to create test quiz: %v", err)
	}

	return quiz
}

func createTestAnswer(t *testing.T, db *gorm.DB, quizID, userID uuid.UUID, content string) database.Answer {
	t.Helper()

	answer := database.Answer{
		ID:        uuid.New(),
		QuizID:    quizID,
		UserID:    userID,
		Content:   content,
		Status:    "active",
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	if err := db.Create(&answer).Error; err != nil {
		t.Fatalf("failed to create test answer: %v", err)
	}

	return answer
}

func createTestCategory(t *testing.T, db *gorm.DB, name string, sortOrder int) database.Category {
	t.Helper()

	cat := database.Category{
		ID:        uuid.New(),
		Name:      name,
		SortOrder: sortOrder,
		Status:    "active",
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	if err := db.Create(&cat).Error; err != nil {
		t.Fatalf("failed to create test category: %v", err)
	}

	return cat
}

func performRequest(router *gin.Engine, method, path string, body interface{}, headers map[string]string) *httptest.ResponseRecorder {
	var reqBody *bytes.Buffer
	if body != nil {
		jsonBytes, _ := json.Marshal(body)
		reqBody = bytes.NewBuffer(jsonBytes)
	} else {
		reqBody = bytes.NewBuffer(nil)
	}

	req, _ := http.NewRequest(method, path, reqBody)
	req.Header.Set("Content-Type", "application/json")
	for k, v := range headers {
		req.Header.Set(k, v)
	}

	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)
	return w
}

func parseResponse(t *testing.T, w *httptest.ResponseRecorder) map[string]interface{} {
	t.Helper()
	var result map[string]interface{}
	if err := json.Unmarshal(w.Body.Bytes(), &result); err != nil {
		t.Fatalf("failed to parse response body: %v\nbody: %s", err, w.Body.String())
	}
	return result
}
