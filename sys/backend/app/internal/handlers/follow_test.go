package handlers_test

import (
	"net/http"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/serifu/backend/internal/database"
	"github.com/serifu/backend/internal/handlers"
)

func setupFollowRouter() *gin.Engine {
	r := gin.New()
	followHandler := handlers.NewFollowHandler(20, 100)

	users := r.Group("/api/v1/users")
	{
		users.POST("/:id/follow", followHandler.FollowUser)
		users.DELETE("/:id/follow", followHandler.UnfollowUser)
		users.GET("/:id/followers", followHandler.GetFollowers)
		users.GET("/:id/following", followHandler.GetFollowing)
	}

	return r
}

func TestFollowSuccess(t *testing.T) {
	db := setupTestDB(t)
	router := setupFollowRouter()
	follower := createTestUser(t, db, "Follower", "follower@test.com", "pass123")
	target := createTestUser(t, db, "Target", "target@test.com", "pass123")

	headers := map[string]string{"X-User-ID": follower.ID.String()}
	w := performRequest(router, "POST", "/api/v1/users/"+target.ID.String()+"/follow", nil, headers)

	if w.Code != http.StatusCreated {
		t.Errorf("expected 201, got %d: %s", w.Code, w.Body.String())
	}

	// Verify notification created
	var notif database.Notification
	err := db.Where("user_id = ? AND actor_id = ? AND type = ?", target.ID, follower.ID, "follow").First(&notif).Error
	if err != nil {
		t.Errorf("expected notification: %v", err)
	}
}

func TestFollowSelf(t *testing.T) {
	db := setupTestDB(t)
	router := setupFollowRouter()
	user := createTestUser(t, db, "User", "user@test.com", "pass123")

	headers := map[string]string{"X-User-ID": user.ID.String()}
	w := performRequest(router, "POST", "/api/v1/users/"+user.ID.String()+"/follow", nil, headers)

	if w.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", w.Code)
	}
}

func TestFollowDuplicate(t *testing.T) {
	db := setupTestDB(t)
	router := setupFollowRouter()
	follower := createTestUser(t, db, "Follower", "follower@test.com", "pass123")
	target := createTestUser(t, db, "Target", "target@test.com", "pass123")

	// Create existing follow
	follow := database.Follow{
		ID:          uuid.New(),
		FollowerID:  follower.ID,
		FollowingID: target.ID,
	}
	db.Create(&follow)

	headers := map[string]string{"X-User-ID": follower.ID.String()}
	w := performRequest(router, "POST", "/api/v1/users/"+target.ID.String()+"/follow", nil, headers)

	if w.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", w.Code)
	}
}

func TestFollowUserNotFound(t *testing.T) {
	db := setupTestDB(t)
	router := setupFollowRouter()
	follower := createTestUser(t, db, "Follower", "follower@test.com", "pass123")

	headers := map[string]string{"X-User-ID": follower.ID.String()}
	w := performRequest(router, "POST", "/api/v1/users/"+uuid.New().String()+"/follow", nil, headers)

	if w.Code != http.StatusNotFound {
		t.Errorf("expected 404, got %d", w.Code)
	}
}

func TestUnfollowSuccess(t *testing.T) {
	db := setupTestDB(t)
	router := setupFollowRouter()
	follower := createTestUser(t, db, "Follower", "follower@test.com", "pass123")
	target := createTestUser(t, db, "Target", "target@test.com", "pass123")

	// Create existing follow
	follow := database.Follow{
		ID:          uuid.New(),
		FollowerID:  follower.ID,
		FollowingID: target.ID,
	}
	db.Create(&follow)

	headers := map[string]string{"X-User-ID": follower.ID.String()}
	w := performRequest(router, "DELETE", "/api/v1/users/"+target.ID.String()+"/follow", nil, headers)

	if w.Code != http.StatusOK {
		t.Errorf("expected 200, got %d: %s", w.Code, w.Body.String())
	}
}

func TestGetFollowers(t *testing.T) {
	db := setupTestDB(t)
	router := setupFollowRouter()
	user := createTestUser(t, db, "User", "user@test.com", "pass123")
	follower := createTestUser(t, db, "Follower", "follower@test.com", "pass123")

	follow := database.Follow{
		ID:          uuid.New(),
		FollowerID:  follower.ID,
		FollowingID: user.ID,
	}
	db.Create(&follow)

	w := performRequest(router, "GET", "/api/v1/users/"+user.ID.String()+"/followers", nil, nil)
	resp := parseResponse(t, w)

	if w.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", w.Code)
	}
	if resp["pagination"] == nil {
		t.Errorf("expected pagination in response")
	}
}

func TestGetFollowing(t *testing.T) {
	db := setupTestDB(t)
	router := setupFollowRouter()
	user := createTestUser(t, db, "User", "user@test.com", "pass123")
	target := createTestUser(t, db, "Target", "target@test.com", "pass123")

	follow := database.Follow{
		ID:          uuid.New(),
		FollowerID:  user.ID,
		FollowingID: target.ID,
	}
	db.Create(&follow)

	w := performRequest(router, "GET", "/api/v1/users/"+user.ID.String()+"/following", nil, nil)
	resp := parseResponse(t, w)

	if w.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", w.Code)
	}
	if resp["pagination"] == nil {
		t.Errorf("expected pagination in response")
	}
}
