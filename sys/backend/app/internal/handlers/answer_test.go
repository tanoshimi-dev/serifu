package handlers_test

import (
	"net/http"
	"strings"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/serifu/backend/internal/database"
	"github.com/serifu/backend/internal/handlers"
)

func setupAnswerRouter() *gin.Engine {
	r := gin.New()
	answerHandler := handlers.NewAnswerHandler(20, 100)

	quizzes := r.Group("/api/v1/quizzes")
	{
		quizzes.POST("/:id/answers", answerHandler.CreateAnswer)
		quizzes.GET("/:id/answers", answerHandler.GetAnswersForQuiz)
	}

	answers := r.Group("/api/v1/answers")
	{
		answers.GET("/:id", answerHandler.GetAnswer)
		answers.PUT("/:id", answerHandler.UpdateAnswer)
		answers.DELETE("/:id", answerHandler.DeleteAnswer)
	}

	return r
}

func TestCreateAnswerSuccess(t *testing.T) {
	db := setupTestDB(t)
	router := setupAnswerRouter()
	user := createTestUser(t, db, "User", "user@test.com", "pass123")
	quiz := createTestQuiz(t, db, "Quiz 1", "active", time.Now())

	body := map[string]string{"content": "My answer"}
	headers := map[string]string{"X-User-ID": user.ID.String()}

	w := performRequest(router, "POST", "/api/v1/quizzes/"+quiz.ID.String()+"/answers", body, headers)

	if w.Code != http.StatusCreated {
		t.Errorf("expected 201, got %d: %s", w.Code, w.Body.String())
	}
}

func TestCreateAnswerContentTooLong(t *testing.T) {
	db := setupTestDB(t)
	router := setupAnswerRouter()
	user := createTestUser(t, db, "User", "user@test.com", "pass123")
	quiz := createTestQuiz(t, db, "Quiz 1", "active", time.Now())

	longContent := strings.Repeat("a", 151)
	body := map[string]string{"content": longContent}
	headers := map[string]string{"X-User-ID": user.ID.String()}

	w := performRequest(router, "POST", "/api/v1/quizzes/"+quiz.ID.String()+"/answers", body, headers)

	if w.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", w.Code)
	}
}

func TestCreateAnswerDuplicate(t *testing.T) {
	db := setupTestDB(t)
	router := setupAnswerRouter()
	user := createTestUser(t, db, "User", "user@test.com", "pass123")
	quiz := createTestQuiz(t, db, "Quiz 1", "active", time.Now())
	createTestAnswer(t, db, quiz.ID, user.ID, "First answer")

	body := map[string]string{"content": "Second answer"}
	headers := map[string]string{"X-User-ID": user.ID.String()}

	w := performRequest(router, "POST", "/api/v1/quizzes/"+quiz.ID.String()+"/answers", body, headers)

	if w.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d: %s", w.Code, w.Body.String())
	}
}

func TestCreateAnswerQuizNotFound(t *testing.T) {
	db := setupTestDB(t)
	router := setupAnswerRouter()
	user := createTestUser(t, db, "User", "user@test.com", "pass123")

	body := map[string]string{"content": "My answer"}
	headers := map[string]string{"X-User-ID": user.ID.String()}

	w := performRequest(router, "POST", "/api/v1/quizzes/"+uuid.New().String()+"/answers", body, headers)

	if w.Code != http.StatusNotFound {
		t.Errorf("expected 404, got %d", w.Code)
	}
}

func TestCreateAnswerMissingUserID(t *testing.T) {
	db := setupTestDB(t)
	router := setupAnswerRouter()
	quiz := createTestQuiz(t, db, "Quiz 1", "active", time.Now())

	body := map[string]string{"content": "My answer"}

	w := performRequest(router, "POST", "/api/v1/quizzes/"+quiz.ID.String()+"/answers", body, nil)

	if w.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", w.Code)
	}
}

func TestGetAnswersForQuizSuccess(t *testing.T) {
	db := setupTestDB(t)
	router := setupAnswerRouter()
	user := createTestUser(t, db, "User", "user@test.com", "pass123")
	quiz := createTestQuiz(t, db, "Quiz 1", "active", time.Now())
	createTestAnswer(t, db, quiz.ID, user.ID, "Answer 1")

	w := performRequest(router, "GET", "/api/v1/quizzes/"+quiz.ID.String()+"/answers", nil, nil)
	resp := parseResponse(t, w)

	if w.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", w.Code)
	}
	if resp["pagination"] == nil {
		t.Errorf("expected pagination in response")
	}
}

func TestGetAnswerSuccess(t *testing.T) {
	db := setupTestDB(t)
	router := setupAnswerRouter()
	user := createTestUser(t, db, "User", "user@test.com", "pass123")
	quiz := createTestQuiz(t, db, "Quiz 1", "active", time.Now())
	answer := createTestAnswer(t, db, quiz.ID, user.ID, "My answer")

	w := performRequest(router, "GET", "/api/v1/answers/"+answer.ID.String(), nil, nil)
	resp := parseResponse(t, w)

	if w.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", w.Code)
	}

	// Verify view_count was incremented
	var updated database.Answer
	db.First(&updated, "id = ?", answer.ID)
	if updated.ViewCount != 1 {
		t.Errorf("expected view_count=1, got %d", updated.ViewCount)
	}
	_ = resp
}

func TestUpdateAnswerOwnerOnly(t *testing.T) {
	db := setupTestDB(t)
	router := setupAnswerRouter()
	user := createTestUser(t, db, "User", "user@test.com", "pass123")
	quiz := createTestQuiz(t, db, "Quiz 1", "active", time.Now())
	answer := createTestAnswer(t, db, quiz.ID, user.ID, "Original")

	body := map[string]string{"content": "Updated"}
	headers := map[string]string{"X-User-ID": user.ID.String()}

	w := performRequest(router, "PUT", "/api/v1/answers/"+answer.ID.String(), body, headers)

	if w.Code != http.StatusOK {
		t.Errorf("expected 200, got %d: %s", w.Code, w.Body.String())
	}
}

func TestUpdateAnswerNotOwner(t *testing.T) {
	db := setupTestDB(t)
	router := setupAnswerRouter()
	user := createTestUser(t, db, "User", "user@test.com", "pass123")
	other := createTestUser(t, db, "Other", "other@test.com", "pass123")
	quiz := createTestQuiz(t, db, "Quiz 1", "active", time.Now())
	answer := createTestAnswer(t, db, quiz.ID, user.ID, "Original")

	body := map[string]string{"content": "Hacked"}
	headers := map[string]string{"X-User-ID": other.ID.String()}

	w := performRequest(router, "PUT", "/api/v1/answers/"+answer.ID.String(), body, headers)

	if w.Code != http.StatusForbidden {
		t.Errorf("expected 403, got %d", w.Code)
	}
}

func TestDeleteAnswerSuccess(t *testing.T) {
	db := setupTestDB(t)
	router := setupAnswerRouter()
	user := createTestUser(t, db, "User", "user@test.com", "pass123")
	quiz := createTestQuiz(t, db, "Quiz 1", "active", time.Now())
	// Set answer_count to 1
	db.Model(&quiz).Update("answer_count", 1)
	answer := createTestAnswer(t, db, quiz.ID, user.ID, "To delete")

	headers := map[string]string{"X-User-ID": user.ID.String()}

	w := performRequest(router, "DELETE", "/api/v1/answers/"+answer.ID.String(), nil, headers)

	if w.Code != http.StatusOK {
		t.Errorf("expected 200, got %d: %s", w.Code, w.Body.String())
	}
}

func TestDeleteAnswerNotOwner(t *testing.T) {
	db := setupTestDB(t)
	router := setupAnswerRouter()
	user := createTestUser(t, db, "User", "user@test.com", "pass123")
	other := createTestUser(t, db, "Other", "other@test.com", "pass123")
	quiz := createTestQuiz(t, db, "Quiz 1", "active", time.Now())
	answer := createTestAnswer(t, db, quiz.ID, user.ID, "My answer")

	headers := map[string]string{"X-User-ID": other.ID.String()}

	w := performRequest(router, "DELETE", "/api/v1/answers/"+answer.ID.String(), nil, headers)

	if w.Code != http.StatusForbidden {
		t.Errorf("expected 403, got %d", w.Code)
	}
}
