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

func setupCommentRouter() *gin.Engine {
	r := gin.New()
	commentHandler := handlers.NewCommentHandler(20, 100)

	answers := r.Group("/api/v1/answers")
	{
		answers.GET("/:id/comments", commentHandler.GetCommentsForAnswer)
		answers.POST("/:id/comments", commentHandler.CreateComment)
	}

	comments := r.Group("/api/v1/comments")
	{
		comments.DELETE("/:id", commentHandler.DeleteComment)
	}

	return r
}

func TestGetCommentsSuccess(t *testing.T) {
	db := setupTestDB(t)
	router := setupCommentRouter()
	user := createTestUser(t, db, "User", "user@test.com", "pass123")
	quiz := createTestQuiz(t, db, "Quiz", "active", time.Now())
	answer := createTestAnswer(t, db, quiz.ID, user.ID, "Answer")

	// Create a comment
	comment := database.Comment{
		ID:       uuid.New(),
		AnswerID: answer.ID,
		UserID:   user.ID,
		Content:  "Great answer!",
		Status:   "active",
	}
	db.Create(&comment)

	w := performRequest(router, "GET", "/api/v1/answers/"+answer.ID.String()+"/comments", nil, nil)
	resp := parseResponse(t, w)

	if w.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", w.Code)
	}
	if resp["pagination"] == nil {
		t.Errorf("expected pagination in response")
	}
}

func TestCreateCommentSuccess(t *testing.T) {
	db := setupTestDB(t)
	router := setupCommentRouter()
	user := createTestUser(t, db, "User", "user@test.com", "pass123")
	author := createTestUser(t, db, "Author", "author@test.com", "pass123")
	quiz := createTestQuiz(t, db, "Quiz", "active", time.Now())
	answer := createTestAnswer(t, db, quiz.ID, author.ID, "Answer")

	body := map[string]string{"content": "Nice!"}
	headers := map[string]string{"X-User-ID": user.ID.String()}

	w := performRequest(router, "POST", "/api/v1/answers/"+answer.ID.String()+"/comments", body, headers)

	if w.Code != http.StatusCreated {
		t.Errorf("expected 201, got %d: %s", w.Code, w.Body.String())
	}

	// Verify comment_count incremented
	var updated database.Answer
	db.First(&updated, "id = ?", answer.ID)
	if updated.CommentCount != 1 {
		t.Errorf("expected comment_count=1, got %d", updated.CommentCount)
	}

	// Verify notification created
	var notif database.Notification
	err := db.Where("user_id = ? AND actor_id = ? AND type = ?", author.ID, user.ID, "comment").First(&notif).Error
	if err != nil {
		t.Errorf("expected notification: %v", err)
	}
}

func TestCreateCommentAnswerNotFound(t *testing.T) {
	db := setupTestDB(t)
	router := setupCommentRouter()
	user := createTestUser(t, db, "User", "user@test.com", "pass123")

	body := map[string]string{"content": "Comment"}
	headers := map[string]string{"X-User-ID": user.ID.String()}

	w := performRequest(router, "POST", "/api/v1/answers/"+uuid.New().String()+"/comments", body, headers)

	if w.Code != http.StatusNotFound {
		t.Errorf("expected 404, got %d", w.Code)
	}
}

func TestCreateCommentMissingContent(t *testing.T) {
	db := setupTestDB(t)
	router := setupCommentRouter()
	user := createTestUser(t, db, "User", "user@test.com", "pass123")
	quiz := createTestQuiz(t, db, "Quiz", "active", time.Now())
	answer := createTestAnswer(t, db, quiz.ID, user.ID, "Answer")

	body := map[string]string{}
	headers := map[string]string{"X-User-ID": user.ID.String()}

	w := performRequest(router, "POST", "/api/v1/answers/"+answer.ID.String()+"/comments", body, headers)

	if w.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", w.Code)
	}
}

func TestDeleteCommentOwner(t *testing.T) {
	db := setupTestDB(t)
	router := setupCommentRouter()
	user := createTestUser(t, db, "User", "user@test.com", "pass123")
	quiz := createTestQuiz(t, db, "Quiz", "active", time.Now())
	answer := createTestAnswer(t, db, quiz.ID, user.ID, "Answer")
	db.Model(&answer).Update("comment_count", 1)

	comment := database.Comment{
		ID:       uuid.New(),
		AnswerID: answer.ID,
		UserID:   user.ID,
		Content:  "To delete",
		Status:   "active",
	}
	db.Create(&comment)

	headers := map[string]string{"X-User-ID": user.ID.String()}
	w := performRequest(router, "DELETE", "/api/v1/comments/"+comment.ID.String(), nil, headers)

	if w.Code != http.StatusOK {
		t.Errorf("expected 200, got %d: %s", w.Code, w.Body.String())
	}
}

func TestDeleteCommentNotOwner(t *testing.T) {
	db := setupTestDB(t)
	router := setupCommentRouter()
	user := createTestUser(t, db, "User", "user@test.com", "pass123")
	other := createTestUser(t, db, "Other", "other@test.com", "pass123")
	quiz := createTestQuiz(t, db, "Quiz", "active", time.Now())
	answer := createTestAnswer(t, db, quiz.ID, user.ID, "Answer")

	comment := database.Comment{
		ID:       uuid.New(),
		AnswerID: answer.ID,
		UserID:   user.ID,
		Content:  "My comment",
		Status:   "active",
	}
	db.Create(&comment)

	headers := map[string]string{"X-User-ID": other.ID.String()}
	w := performRequest(router, "DELETE", "/api/v1/comments/"+comment.ID.String(), nil, headers)

	if w.Code != http.StatusForbidden {
		t.Errorf("expected 403, got %d", w.Code)
	}
}
