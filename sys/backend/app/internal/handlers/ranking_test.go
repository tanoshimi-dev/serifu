package handlers_test

import (
	"net/http"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/serifu/backend/internal/handlers"
)

func setupRankingRouter() *gin.Engine {
	r := gin.New()
	rankingHandler := handlers.NewRankingHandler(20, 100)

	trending := r.Group("/api/v1/trending")
	{
		trending.GET("/answers", rankingHandler.GetTrendingAnswers)
	}

	rankings := r.Group("/api/v1/rankings")
	{
		rankings.GET("/daily", rankingHandler.GetDailyRankings)
		rankings.GET("/all-time", rankingHandler.GetAllTimeRankings)
	}

	categories := r.Group("/api/v1/categories")
	{
		categories.GET("", rankingHandler.GetCategories)
	}

	return r
}

func TestGetTrendingAnswers(t *testing.T) {
	db := setupTestDB(t)
	router := setupRankingRouter()
	user := createTestUser(t, db, "User", "user@test.com", "pass123")
	quiz := createTestQuiz(t, db, "Quiz", "active", time.Now())
	answer := createTestAnswer(t, db, quiz.ID, user.ID, "Trending answer")

	// Set some engagement
	db.Model(&answer).Updates(map[string]interface{}{
		"like_count":    5,
		"comment_count": 2,
		"view_count":    100,
	})

	w := performRequest(router, "GET", "/api/v1/trending/answers", nil, nil)
	resp := parseResponse(t, w)

	if w.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", w.Code)
	}
	if resp["pagination"] == nil {
		t.Errorf("expected pagination in response")
	}
}

func TestGetDailyRankings(t *testing.T) {
	db := setupTestDB(t)
	router := setupRankingRouter()
	user := createTestUser(t, db, "User", "user@test.com", "pass123")
	quiz := createTestQuiz(t, db, "Quiz", "active", time.Now())
	createTestAnswer(t, db, quiz.ID, user.ID, "Today's answer")

	w := performRequest(router, "GET", "/api/v1/rankings/daily", nil, nil)

	if w.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", w.Code)
	}
}

func TestGetAllTimeRankings(t *testing.T) {
	db := setupTestDB(t)
	router := setupRankingRouter()
	user := createTestUser(t, db, "User", "user@test.com", "pass123")
	quiz := createTestQuiz(t, db, "Quiz", "active", time.Now())
	createTestAnswer(t, db, quiz.ID, user.ID, "All-time answer")

	w := performRequest(router, "GET", "/api/v1/rankings/all-time", nil, nil)

	if w.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", w.Code)
	}
}

func TestGetCategories(t *testing.T) {
	db := setupTestDB(t)
	router := setupRankingRouter()
	createTestCategory(t, db, "Science", 2)
	createTestCategory(t, db, "Fun", 1)

	w := performRequest(router, "GET", "/api/v1/categories", nil, nil)
	resp := parseResponse(t, w)

	if w.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", w.Code)
	}
	data := resp["data"].([]interface{})
	if len(data) != 2 {
		t.Errorf("expected 2 categories, got %d", len(data))
	}
	// Verify sort order (Fun=1 should come before Science=2)
	first := data[0].(map[string]interface{})
	if first["name"] != "Fun" {
		t.Errorf("expected first category=Fun (sort_order=1), got %v", first["name"])
	}
}
