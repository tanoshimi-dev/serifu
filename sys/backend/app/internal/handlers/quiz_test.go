package handlers_test

import (
	"net/http"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/serifu/backend/internal/handlers"
)

func setupQuizRouter() *gin.Engine {
	r := gin.New()
	quizHandler := handlers.NewQuizHandler(20, 100)

	quizzes := r.Group("/api/v1/quizzes")
	{
		quizzes.GET("/daily", quizHandler.GetDailyQuizzes)
		quizzes.GET("", quizHandler.ListQuizzes)
		quizzes.GET("/:id", quizHandler.GetQuiz)
		quizzes.POST("", quizHandler.CreateQuiz)
	}

	return r
}

func TestGetDailyQuizzes(t *testing.T) {
	db := setupTestDB(t)
	router := setupQuizRouter()

	// Create a quiz with today's release date
	today := time.Now().Truncate(24 * time.Hour)
	createTestQuiz(t, db, "Today Quiz", "active", today)

	// Create a quiz from yesterday (should not appear)
	yesterday := today.AddDate(0, 0, -1)
	createTestQuiz(t, db, "Yesterday Quiz", "active", yesterday)

	w := performRequest(router, "GET", "/api/v1/quizzes/daily", nil, nil)
	resp := parseResponse(t, w)

	if w.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", w.Code)
	}
	data := resp["data"].([]interface{})
	if len(data) != 1 {
		t.Errorf("expected 1 daily quiz, got %d", len(data))
	}
}

func TestGetQuizSuccess(t *testing.T) {
	db := setupTestDB(t)
	router := setupQuizRouter()
	quiz := createTestQuiz(t, db, "Test Quiz", "active", time.Now())

	w := performRequest(router, "GET", "/api/v1/quizzes/"+quiz.ID.String(), nil, nil)

	if w.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", w.Code)
	}
}

func TestGetQuizNotFound(t *testing.T) {
	setupTestDB(t)
	router := setupQuizRouter()

	w := performRequest(router, "GET", "/api/v1/quizzes/"+uuid.New().String(), nil, nil)

	if w.Code != http.StatusNotFound {
		t.Errorf("expected 404, got %d", w.Code)
	}
}

func TestListQuizzesPagination(t *testing.T) {
	db := setupTestDB(t)
	router := setupQuizRouter()

	// Create 3 active quizzes
	for i := 0; i < 3; i++ {
		createTestQuiz(t, db, "Quiz", "active", time.Now())
	}

	w := performRequest(router, "GET", "/api/v1/quizzes?page=1&page_size=2", nil, nil)
	resp := parseResponse(t, w)

	if w.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", w.Code)
	}
	pagination := resp["pagination"].(map[string]interface{})
	if pagination["total"] != float64(3) {
		t.Errorf("expected total=3, got %v", pagination["total"])
	}
	if pagination["has_more"] != true {
		t.Errorf("expected has_more=true")
	}
}

func TestListQuizzesCategoryFilter(t *testing.T) {
	db := setupTestDB(t)
	router := setupQuizRouter()
	cat := createTestCategory(t, db, "Science", 1)

	// Create quiz with category
	catID := cat.ID
	quiz := createTestQuiz(t, db, "Science Quiz", "active", time.Now())
	db.Model(&quiz).Update("category_id", catID)

	// Create quiz without category
	createTestQuiz(t, db, "No Category Quiz", "active", time.Now())

	w := performRequest(router, "GET", "/api/v1/quizzes?category_id="+cat.ID.String(), nil, nil)
	resp := parseResponse(t, w)

	if w.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", w.Code)
	}
	data := resp["data"].([]interface{})
	if len(data) != 1 {
		t.Errorf("expected 1 quiz with category, got %d", len(data))
	}
}

func TestCreateQuizSuccess(t *testing.T) {
	setupTestDB(t)
	router := setupQuizRouter()

	body := map[string]string{
		"title":       "New Quiz",
		"description": "A quiz description",
	}

	w := performRequest(router, "POST", "/api/v1/quizzes", body, nil)

	if w.Code != http.StatusCreated {
		t.Errorf("expected 201, got %d: %s", w.Code, w.Body.String())
	}
}
