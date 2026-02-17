package handlers_test

import (
	"net/http"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/serifu/backend/internal/database"
	"github.com/serifu/backend/internal/handlers"
)

func setupUserRouter() *gin.Engine {
	r := gin.New()
	userHandler := handlers.NewUserHandler(20, 100, "/tmp/test-avatars", 5)

	users := r.Group("/api/v1/users")
	{
		users.GET("/:id", userHandler.GetUser)
		users.GET("/:id/answers", userHandler.GetUserAnswers)
		users.PUT("/:id", userHandler.UpdateUser)
	}

	return r
}

func TestGetUserSuccess(t *testing.T) {
	db := setupTestDB(t)
	router := setupUserRouter()
	user := createTestUser(t, db, "TestUser", "user@test.com", "pass123")

	w := performRequest(router, "GET", "/api/v1/users/"+user.ID.String(), nil, nil)
	resp := parseResponse(t, w)

	if w.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", w.Code)
	}
	data := resp["data"].(map[string]interface{})
	if data["name"] != "TestUser" {
		t.Errorf("expected name=TestUser, got %v", data["name"])
	}
}

func TestGetUserNotFound(t *testing.T) {
	setupTestDB(t)
	router := setupUserRouter()

	w := performRequest(router, "GET", "/api/v1/users/"+uuid.New().String(), nil, nil)

	if w.Code != http.StatusNotFound {
		t.Errorf("expected 404, got %d", w.Code)
	}
}

func TestUpdateUserOwnProfile(t *testing.T) {
	db := setupTestDB(t)
	router := setupUserRouter()
	user := createTestUser(t, db, "Original", "user@test.com", "pass123")

	body := map[string]string{"name": "Updated"}
	headers := map[string]string{"X-User-ID": user.ID.String()}

	w := performRequest(router, "PUT", "/api/v1/users/"+user.ID.String(), body, headers)

	if w.Code != http.StatusOK {
		t.Errorf("expected 200, got %d: %s", w.Code, w.Body.String())
	}
}

func TestUpdateUserNotOwner(t *testing.T) {
	db := setupTestDB(t)
	router := setupUserRouter()
	user := createTestUser(t, db, "User", "user@test.com", "pass123")
	other := createTestUser(t, db, "Other", "other@test.com", "pass123")

	body := map[string]string{"name": "Hacked"}
	headers := map[string]string{"X-User-ID": other.ID.String()}

	w := performRequest(router, "PUT", "/api/v1/users/"+user.ID.String(), body, headers)

	if w.Code != http.StatusForbidden {
		t.Errorf("expected 403, got %d", w.Code)
	}
}

func TestUpdateUserMissingUserID(t *testing.T) {
	db := setupTestDB(t)
	router := setupUserRouter()
	user := createTestUser(t, db, "User", "user@test.com", "pass123")

	body := map[string]string{"name": "Updated"}

	w := performRequest(router, "PUT", "/api/v1/users/"+user.ID.String(), body, nil)

	if w.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", w.Code)
	}
}

func TestGetUserAnswersPaginated(t *testing.T) {
	db := setupTestDB(t)
	router := setupUserRouter()
	user := createTestUser(t, db, "User", "user@test.com", "pass123")
	quiz := createTestQuiz(t, db, "Quiz", "active", time.Now())
	createTestAnswer(t, db, quiz.ID, user.ID, "Answer 1")

	w := performRequest(router, "GET", "/api/v1/users/"+user.ID.String()+"/answers", nil, nil)
	resp := parseResponse(t, w)

	if w.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", w.Code)
	}
	if resp["pagination"] == nil {
		t.Errorf("expected pagination in response")
	}
}

func TestGetUserIsFollowingTrue(t *testing.T) {
	db := setupTestDB(t)
	router := setupUserRouter()
	user := createTestUser(t, db, "User", "user@test.com", "pass123")
	follower := createTestUser(t, db, "Follower", "follower@test.com", "pass123")

	// Create follow relationship
	follow := database.Follow{
		ID:          uuid.New(),
		FollowerID:  follower.ID,
		FollowingID: user.ID,
	}
	db.Create(&follow)

	headers := map[string]string{"X-User-ID": follower.ID.String()}
	w := performRequest(router, "GET", "/api/v1/users/"+user.ID.String(), nil, headers)
	resp := parseResponse(t, w)

	if w.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", w.Code)
	}
	data := resp["data"].(map[string]interface{})
	if data["is_following"] != true {
		t.Errorf("expected is_following=true, got %v", data["is_following"])
	}
}
