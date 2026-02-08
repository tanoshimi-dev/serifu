package admin

import (
	"bytes"
	"encoding/json"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/serifu/backend/internal/admin/templates"
	"github.com/serifu/backend/internal/database"
)

func BulkQuizPageHandler(c *gin.Context) {
	admin := GetAdminFromContext(c)
	db := database.GetDB()

	var categories []database.Category
	db.Where("status = ?", "active").Order("sort_order ASC, name ASC").Find(&categories)

	categoriesJSON, _ := json.Marshal(categories)

	var buf bytes.Buffer
	templates.BulkQuizPage(admin.Name, string(categoriesJSON)).Render(c.Request.Context(), &buf)
	c.Data(http.StatusOK, "text/html; charset=utf-8", buf.Bytes())
}

type generateRequest struct {
	Rows []GenerateRow `json:"rows"`
}

func BulkQuizGenerateHandler(c *gin.Context) {
	var req generateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "リクエストの形式が不正です"})
		return
	}

	if len(req.Rows) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "カテゴリを1つ以上選択してください"})
		return
	}

	// Validate: no duplicate categories, count in range, total <= 50
	seen := make(map[string]bool)
	totalCount := 0
	for _, row := range req.Rows {
		if row.CategoryID == "" || row.CategoryName == "" {
			c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "全ての行でカテゴリを選択してください"})
			return
		}
		if seen[row.CategoryID] {
			c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "カテゴリが重複しています"})
			return
		}
		seen[row.CategoryID] = true
		if row.Count < 1 || row.Count > 20 {
			c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "件数は1〜20の範囲で指定してください"})
			return
		}
		totalCount += row.Count
	}
	if totalCount > 50 {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "合計件数は50件以下にしてください"})
		return
	}

	// Validate category IDs exist in DB
	db := database.GetDB()
	for _, row := range req.Rows {
		catUUID, err := uuid.Parse(row.CategoryID)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "カテゴリIDが不正です"})
			return
		}
		var count int64
		db.Model(&database.Category{}).Where("id = ? AND status = ?", catUUID, "active").Count(&count)
		if count == 0 {
			c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "存在しないカテゴリが含まれています"})
			return
		}
	}

	quizzes, err := GenerateQuizzes(c.Request.Context(), req.Rows)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": "クイズの生成に失敗しました: " + err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"quizzes": quizzes,
		},
	})
}

type saveQuizItem struct {
	CategoryID  string `json:"category_id"`
	Title       string `json:"title"`
	Description string `json:"description"`
}

type saveRequest struct {
	ReleaseDate string         `json:"release_date"`
	Status      string         `json:"status"`
	Quizzes     []saveQuizItem `json:"quizzes"`
}

func BulkQuizSaveHandler(c *gin.Context) {
	admin := GetAdminFromContext(c)

	var req saveRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "リクエストの形式が不正です"})
		return
	}

	if len(req.Quizzes) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "保存するクイズがありません"})
		return
	}

	// Validate release_date
	releaseDate, err := time.Parse("2006-01-02", req.ReleaseDate)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "公開日の形式が不正です"})
		return
	}

	// Validate status
	if req.Status != "draft" && req.Status != "active" {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "ステータスが不正です"})
		return
	}

	// Validate each quiz
	db := database.GetDB()
	for _, q := range req.Quizzes {
		if q.Title == "" {
			c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "タイトルが空のクイズがあります"})
			return
		}
		catUUID, err := uuid.Parse(q.CategoryID)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "カテゴリIDが不正です"})
			return
		}
		var count int64
		db.Model(&database.Category{}).Where("id = ?", catUUID).Count(&count)
		if count == 0 {
			c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "存在しないカテゴリが含まれています"})
			return
		}
	}

	// Save in transaction
	tx := db.Begin()
	createdCount := 0
	for _, q := range req.Quizzes {
		catUUID, _ := uuid.Parse(q.CategoryID)
		quiz := database.Quiz{
			Title:       q.Title,
			Description: q.Description,
			CategoryID:  &catUUID,
			ReleaseDate: releaseDate,
			Status:      req.Status,
		}
		if err := tx.Create(&quiz).Error; err != nil {
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": "クイズの保存に失敗しました"})
			return
		}

		tx.Create(&database.AdminAuditLog{
			AdminUserID: admin.ID,
			Action:      "create_quiz",
			EntityType:  "quiz",
			EntityID:    quiz.ID.String(),
			IPAddress:   c.ClientIP(),
		})
		createdCount++
	}
	tx.Commit()

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"created_count": createdCount,
			"redirect_url":  "/admin/quizzes",
		},
	})
}
