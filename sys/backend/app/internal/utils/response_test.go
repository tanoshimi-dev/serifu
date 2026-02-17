package utils_test

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/serifu/backend/internal/utils"
)

func init() {
	gin.SetMode(gin.TestMode)
}

func TestSuccessResponse(t *testing.T) {
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)

	utils.SuccessResponse(c, gin.H{"key": "value"})

	if w.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", w.Code)
	}

	var resp map[string]interface{}
	json.Unmarshal(w.Body.Bytes(), &resp)

	if resp["success"] != true {
		t.Errorf("expected success=true")
	}
	data := resp["data"].(map[string]interface{})
	if data["key"] != "value" {
		t.Errorf("expected key=value")
	}
}

func TestErrorResponse(t *testing.T) {
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)

	utils.ErrorResponse(c, http.StatusBadRequest, "bad request")

	if w.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", w.Code)
	}

	var resp map[string]interface{}
	json.Unmarshal(w.Body.Bytes(), &resp)

	if resp["success"] != false {
		t.Errorf("expected success=false")
	}
	if resp["error"] != "bad request" {
		t.Errorf("expected error='bad request', got %v", resp["error"])
	}
}

func TestPaginatedSuccessResponseHasMore(t *testing.T) {
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)

	data := []string{"a", "b"}
	utils.PaginatedSuccessResponse(c, data, 1, 2, 5)

	if w.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", w.Code)
	}

	var resp map[string]interface{}
	json.Unmarshal(w.Body.Bytes(), &resp)

	pagination := resp["pagination"].(map[string]interface{})
	if pagination["total"] != float64(5) {
		t.Errorf("expected total=5, got %v", pagination["total"])
	}
	if pagination["total_pages"] != float64(3) {
		t.Errorf("expected total_pages=3, got %v", pagination["total_pages"])
	}
	if pagination["has_more"] != true {
		t.Errorf("expected has_more=true")
	}
}

func TestPaginatedSuccessResponseLastPage(t *testing.T) {
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)

	data := []string{"a"}
	utils.PaginatedSuccessResponse(c, data, 3, 2, 5)

	var resp map[string]interface{}
	json.Unmarshal(w.Body.Bytes(), &resp)

	pagination := resp["pagination"].(map[string]interface{})
	if pagination["has_more"] != false {
		t.Errorf("expected has_more=false for last page")
	}
}
