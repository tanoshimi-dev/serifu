package handlers_test

import (
	"net/http"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/serifu/backend/internal/database"
	"github.com/serifu/backend/internal/handlers"
)

func setupNotificationRouter() *gin.Engine {
	r := gin.New()
	notificationHandler := handlers.NewNotificationHandler(20, 100)

	notifications := r.Group("/api/v1/notifications")
	{
		notifications.GET("", notificationHandler.GetNotifications)
		notifications.PUT("/read-all", notificationHandler.MarkAllAsRead)
		notifications.GET("/unread-count", notificationHandler.GetUnreadCount)
	}

	return r
}

func TestGetNotificationsPaginated(t *testing.T) {
	db := setupTestDB(t)
	router := setupNotificationRouter()
	user := createTestUser(t, db, "User", "user@test.com", "pass123")
	actor := createTestUser(t, db, "Actor", "actor@test.com", "pass123")

	// Create a notification
	notif := database.Notification{
		ID:         uuid.New(),
		UserID:     user.ID,
		ActorID:    actor.ID,
		Type:       "like",
		TargetType: "answer",
		TargetID:   uuid.New(),
	}
	db.Create(&notif)

	headers := map[string]string{"X-User-ID": user.ID.String()}
	w := performRequest(router, "GET", "/api/v1/notifications", nil, headers)
	resp := parseResponse(t, w)

	if w.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", w.Code)
	}
	if resp["pagination"] == nil {
		t.Errorf("expected pagination in response")
	}
}

func TestMarkAllAsRead(t *testing.T) {
	db := setupTestDB(t)
	router := setupNotificationRouter()
	user := createTestUser(t, db, "User", "user@test.com", "pass123")
	actor := createTestUser(t, db, "Actor", "actor@test.com", "pass123")

	// Create unread notifications
	for i := 0; i < 3; i++ {
		notif := database.Notification{
			ID:         uuid.New(),
			UserID:     user.ID,
			ActorID:    actor.ID,
			Type:       "like",
			TargetType: "answer",
			TargetID:   uuid.New(),
			IsRead:     false,
		}
		db.Create(&notif)
	}

	headers := map[string]string{"X-User-ID": user.ID.String()}
	w := performRequest(router, "PUT", "/api/v1/notifications/read-all", nil, headers)

	if w.Code != http.StatusOK {
		t.Errorf("expected 200, got %d: %s", w.Code, w.Body.String())
	}

	// Verify all are read
	var unreadCount int64
	db.Model(&database.Notification{}).Where("user_id = ? AND is_read = ?", user.ID, false).Count(&unreadCount)
	if unreadCount != 0 {
		t.Errorf("expected 0 unread, got %d", unreadCount)
	}
}

func TestGetUnreadCount(t *testing.T) {
	db := setupTestDB(t)
	router := setupNotificationRouter()
	user := createTestUser(t, db, "User", "user@test.com", "pass123")
	actor := createTestUser(t, db, "Actor", "actor@test.com", "pass123")

	// Create 2 unread notifications
	for i := 0; i < 2; i++ {
		notif := database.Notification{
			ID:         uuid.New(),
			UserID:     user.ID,
			ActorID:    actor.ID,
			Type:       "like",
			TargetType: "answer",
			TargetID:   uuid.New(),
			IsRead:     false,
		}
		db.Create(&notif)
	}

	headers := map[string]string{"X-User-ID": user.ID.String()}
	w := performRequest(router, "GET", "/api/v1/notifications/unread-count", nil, headers)
	resp := parseResponse(t, w)

	if w.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", w.Code)
	}
	data := resp["data"].(map[string]interface{})
	if data["unread_count"] != float64(2) {
		t.Errorf("expected unread_count=2, got %v", data["unread_count"])
	}
}

func TestCreateNotificationSkipsSelfNotify(t *testing.T) {
	db := setupTestDB(t)
	user := createTestUser(t, db, "User", "user@test.com", "pass123")

	handlers.CreateNotification(db, user.ID, user.ID, "like", "answer", uuid.New())

	var count int64
	db.Model(&database.Notification{}).Where("user_id = ?", user.ID).Count(&count)
	if count != 0 {
		t.Errorf("expected 0 notifications for self-notify, got %d", count)
	}
}

func TestNotificationsRequireUserID(t *testing.T) {
	setupTestDB(t)
	router := setupNotificationRouter()

	w := performRequest(router, "GET", "/api/v1/notifications", nil, nil)

	if w.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", w.Code)
	}
}
