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

func setupLikeRouter() *gin.Engine {
	r := gin.New()
	likeHandler := handlers.NewLikeHandler()

	answers := r.Group("/api/v1/answers")
	{
		answers.POST("/:id/like", likeHandler.LikeAnswer)
		answers.DELETE("/:id/like", likeHandler.UnlikeAnswer)
	}

	return r
}

func TestLikeAnswerSuccess(t *testing.T) {
	db := setupTestDB(t)
	router := setupLikeRouter()
	user := createTestUser(t, db, "Liker", "liker@test.com", "pass123")
	author := createTestUser(t, db, "Author", "author@test.com", "pass123")
	quiz := createTestQuiz(t, db, "Quiz", "active", time.Now())
	answer := createTestAnswer(t, db, quiz.ID, author.ID, "Answer")

	headers := map[string]string{"X-User-ID": user.ID.String()}
	w := performRequest(router, "POST", "/api/v1/answers/"+answer.ID.String()+"/like", nil, headers)

	if w.Code != http.StatusCreated {
		t.Errorf("expected 201, got %d: %s", w.Code, w.Body.String())
	}

	// Verify like_count incremented
	var updated database.Answer
	db.First(&updated, "id = ?", answer.ID)
	if updated.LikeCount != 1 {
		t.Errorf("expected like_count=1, got %d", updated.LikeCount)
	}

	// Verify total_likes incremented
	var updatedAuthor database.User
	db.First(&updatedAuthor, "id = ?", author.ID)
	if updatedAuthor.TotalLikes != 1 {
		t.Errorf("expected total_likes=1, got %d", updatedAuthor.TotalLikes)
	}

	// Verify notification created
	var notif database.Notification
	err := db.Where("user_id = ? AND actor_id = ? AND type = ?", author.ID, user.ID, "like").First(&notif).Error
	if err != nil {
		t.Errorf("expected notification to be created: %v", err)
	}
}

func TestLikeAnswerDuplicate(t *testing.T) {
	db := setupTestDB(t)
	router := setupLikeRouter()
	user := createTestUser(t, db, "User", "user@test.com", "pass123")
	quiz := createTestQuiz(t, db, "Quiz", "active", time.Now())
	answer := createTestAnswer(t, db, quiz.ID, user.ID, "Answer")

	// Create existing like
	like := database.Like{
		ID:       uuid.New(),
		AnswerID: answer.ID,
		UserID:   user.ID,
	}
	db.Create(&like)

	headers := map[string]string{"X-User-ID": user.ID.String()}
	w := performRequest(router, "POST", "/api/v1/answers/"+answer.ID.String()+"/like", nil, headers)

	if w.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", w.Code)
	}
}

func TestLikeAnswerNotFound(t *testing.T) {
	setupTestDB(t)
	router := setupLikeRouter()

	headers := map[string]string{"X-User-ID": uuid.New().String()}
	w := performRequest(router, "POST", "/api/v1/answers/"+uuid.New().String()+"/like", nil, headers)

	if w.Code != http.StatusNotFound {
		t.Errorf("expected 404, got %d", w.Code)
	}
}

func TestUnlikeAnswerSuccess(t *testing.T) {
	db := setupTestDB(t)
	router := setupLikeRouter()
	user := createTestUser(t, db, "User", "user@test.com", "pass123")
	quiz := createTestQuiz(t, db, "Quiz", "active", time.Now())
	answer := createTestAnswer(t, db, quiz.ID, user.ID, "Answer")
	db.Model(&answer).Update("like_count", 1)

	// Create existing like
	like := database.Like{ID: uuid.New(), AnswerID: answer.ID, UserID: user.ID}
	db.Create(&like)

	headers := map[string]string{"X-User-ID": user.ID.String()}
	w := performRequest(router, "DELETE", "/api/v1/answers/"+answer.ID.String()+"/like", nil, headers)

	if w.Code != http.StatusOK {
		t.Errorf("expected 200, got %d: %s", w.Code, w.Body.String())
	}

	// Verify like_count decremented
	var updated database.Answer
	db.First(&updated, "id = ?", answer.ID)
	if updated.LikeCount != 0 {
		t.Errorf("expected like_count=0, got %d", updated.LikeCount)
	}
}

func TestUnlikeAnswerNotLiked(t *testing.T) {
	db := setupTestDB(t)
	router := setupLikeRouter()
	user := createTestUser(t, db, "User", "user@test.com", "pass123")
	quiz := createTestQuiz(t, db, "Quiz", "active", time.Now())
	answer := createTestAnswer(t, db, quiz.ID, user.ID, "Answer")

	headers := map[string]string{"X-User-ID": user.ID.String()}
	w := performRequest(router, "DELETE", "/api/v1/answers/"+answer.ID.String()+"/like", nil, headers)

	if w.Code != http.StatusNotFound {
		t.Errorf("expected 404, got %d", w.Code)
	}
}

func TestLikeOwnAnswerNoNotification(t *testing.T) {
	db := setupTestDB(t)
	router := setupLikeRouter()
	user := createTestUser(t, db, "User", "user@test.com", "pass123")
	quiz := createTestQuiz(t, db, "Quiz", "active", time.Now())
	answer := createTestAnswer(t, db, quiz.ID, user.ID, "Answer")

	headers := map[string]string{"X-User-ID": user.ID.String()}
	w := performRequest(router, "POST", "/api/v1/answers/"+answer.ID.String()+"/like", nil, headers)

	if w.Code != http.StatusCreated {
		t.Errorf("expected 201, got %d", w.Code)
	}

	// Verify no notification created (self-like)
	var count int64
	db.Model(&database.Notification{}).Where("user_id = ? AND actor_id = ?", user.ID, user.ID).Count(&count)
	if count != 0 {
		t.Errorf("expected no self-notification, got %d", count)
	}
}
