package handlers_test

import (
	"net/http"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/serifu/backend/internal/handlers"
	"github.com/serifu/backend/internal/middleware"
)

func setupAuthRouter() *gin.Engine {
	r := gin.New()
	authHandler := handlers.NewAuthHandler("test-secret", 24)
	auth := r.Group("/api/v1/auth")
	{
		auth.POST("/register", authHandler.Register)
		auth.POST("/login", authHandler.Login)
		auth.GET("/me", middleware.JWTAuthMiddleware("test-secret"), authHandler.GetMe)
	}
	return r
}

func TestRegisterSuccess(t *testing.T) {
	setupTestDB(t)
	router := setupAuthRouter()

	body := map[string]string{
		"email":    "test@example.com",
		"name":     "TestUser",
		"password": "password123",
	}

	w := performRequest(router, "POST", "/api/v1/auth/register", body, nil)
	resp := parseResponse(t, w)

	if w.Code != http.StatusCreated {
		t.Errorf("expected 201, got %d: %v", w.Code, resp)
	}
	if resp["success"] != true {
		t.Errorf("expected success=true")
	}
	data := resp["data"].(map[string]interface{})
	if data["token"] == nil || data["token"] == "" {
		t.Errorf("expected token in response")
	}
}

func TestRegisterInvalidEmail(t *testing.T) {
	setupTestDB(t)
	router := setupAuthRouter()

	body := map[string]string{
		"email":    "not-an-email",
		"name":     "TestUser",
		"password": "password123",
	}

	w := performRequest(router, "POST", "/api/v1/auth/register", body, nil)

	if w.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", w.Code)
	}
}

func TestRegisterShortPassword(t *testing.T) {
	setupTestDB(t)
	router := setupAuthRouter()

	body := map[string]string{
		"email":    "test@example.com",
		"name":     "TestUser",
		"password": "12345",
	}

	w := performRequest(router, "POST", "/api/v1/auth/register", body, nil)

	if w.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", w.Code)
	}
}

func TestRegisterDuplicateEmail(t *testing.T) {
	db := setupTestDB(t)
	router := setupAuthRouter()
	createTestUser(t, db, "Existing", "dup@example.com", "password123")

	body := map[string]string{
		"email":    "dup@example.com",
		"name":     "NewUser",
		"password": "password123",
	}

	w := performRequest(router, "POST", "/api/v1/auth/register", body, nil)

	if w.Code != http.StatusConflict {
		t.Errorf("expected 409, got %d", w.Code)
	}
}

func TestRegisterMissingFields(t *testing.T) {
	setupTestDB(t)
	router := setupAuthRouter()

	body := map[string]string{
		"email": "test@example.com",
	}

	w := performRequest(router, "POST", "/api/v1/auth/register", body, nil)

	if w.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", w.Code)
	}
}

func TestLoginSuccess(t *testing.T) {
	db := setupTestDB(t)
	router := setupAuthRouter()
	createTestUser(t, db, "LoginUser", "login@example.com", "password123")

	body := map[string]string{
		"email":    "login@example.com",
		"password": "password123",
	}

	w := performRequest(router, "POST", "/api/v1/auth/login", body, nil)
	resp := parseResponse(t, w)

	if w.Code != http.StatusOK {
		t.Errorf("expected 200, got %d: %v", w.Code, resp)
	}
	data := resp["data"].(map[string]interface{})
	if data["token"] == nil || data["token"] == "" {
		t.Errorf("expected token in response")
	}
}

func TestLoginWrongPassword(t *testing.T) {
	db := setupTestDB(t)
	router := setupAuthRouter()
	createTestUser(t, db, "User", "wrong@example.com", "correctpassword")

	body := map[string]string{
		"email":    "wrong@example.com",
		"password": "wrongpassword",
	}

	w := performRequest(router, "POST", "/api/v1/auth/login", body, nil)

	if w.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", w.Code)
	}
}

func TestLoginNonexistentEmail(t *testing.T) {
	setupTestDB(t)
	router := setupAuthRouter()

	body := map[string]string{
		"email":    "nobody@example.com",
		"password": "password123",
	}

	w := performRequest(router, "POST", "/api/v1/auth/login", body, nil)

	if w.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", w.Code)
	}
}

func TestGetMeWithValidUserID(t *testing.T) {
	db := setupTestDB(t)
	router := setupAuthRouter()
	user := createTestUser(t, db, "MeUser", "me@example.com", "password123")

	headers := map[string]string{
		"X-User-ID": user.ID.String(),
	}

	w := performRequest(router, "GET", "/api/v1/auth/me", nil, headers)
	resp := parseResponse(t, w)

	if w.Code != http.StatusOK {
		t.Errorf("expected 200, got %d: %v", w.Code, resp)
	}
	data := resp["data"].(map[string]interface{})
	if data["name"] != "MeUser" {
		t.Errorf("expected name=MeUser, got %v", data["name"])
	}
}

func TestGetMeWithoutAuth(t *testing.T) {
	setupTestDB(t)
	router := setupAuthRouter()

	w := performRequest(router, "GET", "/api/v1/auth/me", nil, nil)

	if w.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", w.Code)
	}
}
