package middleware_test

import (
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/serifu/backend/internal/middleware"
)

func init() {
	gin.SetMode(gin.TestMode)
}

const testSecret = "test-jwt-secret"

func generateTestToken(userID string) string {
	claims := jwt.MapClaims{
		"sub": userID,
		"iat": time.Now().Unix(),
		"exp": time.Now().Add(time.Hour).Unix(),
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, _ := token.SignedString([]byte(testSecret))
	return tokenString
}

func setupAuthMiddlewareRouter() *gin.Engine {
	r := gin.New()
	r.GET("/protected", middleware.JWTAuthMiddleware(testSecret), func(c *gin.Context) {
		userID := middleware.GetUserIDFromContext(c)
		c.JSON(http.StatusOK, gin.H{"user_id": userID})
	})
	return r
}

func TestValidBearerToken(t *testing.T) {
	router := setupAuthMiddlewareRouter()
	token := generateTestToken("user-123")

	req, _ := http.NewRequest("GET", "/protected", nil)
	req.Header.Set("Authorization", "Bearer "+token)

	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("expected 200, got %d: %s", w.Code, w.Body.String())
	}
}

func TestInvalidBearerTokenWithoutFallback(t *testing.T) {
	router := setupAuthMiddlewareRouter()

	req, _ := http.NewRequest("GET", "/protected", nil)
	req.Header.Set("Authorization", "Bearer invalid-token")

	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	if w.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", w.Code)
	}
}

func TestXUserIDFallback(t *testing.T) {
	router := setupAuthMiddlewareRouter()

	req, _ := http.NewRequest("GET", "/protected", nil)
	req.Header.Set("X-User-ID", "user-456")

	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", w.Code)
	}
}

func TestNoAuthHeaders(t *testing.T) {
	router := setupAuthMiddlewareRouter()

	req, _ := http.NewRequest("GET", "/protected", nil)

	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	if w.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", w.Code)
	}
}

func TestGetUserIDFromContext(t *testing.T) {
	c, _ := gin.CreateTestContext(httptest.NewRecorder())
	c.Set("userID", "test-user-id")

	result := middleware.GetUserIDFromContext(c)
	if result != "test-user-id" {
		t.Errorf("expected test-user-id, got %s", result)
	}

	// Test with no userID in context
	c2, _ := gin.CreateTestContext(httptest.NewRecorder())
	result2 := middleware.GetUserIDFromContext(c2)
	if result2 != "" {
		t.Errorf("expected empty string, got %s", result2)
	}
}
