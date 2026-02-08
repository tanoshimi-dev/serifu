package admin

import (
	"bytes"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/serifu/backend/internal/admin/templates"
	"github.com/serifu/backend/internal/database"
)

func QuizListHandler(c *gin.Context) {
	admin := GetAdminFromContext(c)
	db := database.GetDB()

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	if page < 1 {
		page = 1
	}
	pageSize := parseSizeParam(c, 10)
	search := c.Query("search")
	status := c.Query("status")
	categoryID := c.Query("category_id")

	query := db.Model(&database.Quiz{}).Preload("Category")
	if search != "" {
		query = query.Where("title ILIKE ?", "%"+search+"%")
	}
	if status != "" {
		query = query.Where("status = ?", status)
	}
	if categoryID != "" {
		if catUUID, err := uuid.Parse(categoryID); err == nil {
			query = query.Where("category_id = ?", catUUID)
		}
	}

	var total int64
	query.Count(&total)

	var quizzes []database.Quiz
	query.Order("created_at DESC").
		Offset((page - 1) * pageSize).
		Limit(pageSize).
		Find(&quizzes)

	totalPages := int(total) / pageSize
	if int(total)%pageSize > 0 {
		totalPages++
	}

	var categories []database.Category
	db.Order("sort_order ASC, name ASC").Find(&categories)

	var buf bytes.Buffer
	templates.QuizList(admin.Name, quizzes, categories, search, status, categoryID, page, totalPages, int(total), pageSize).Render(c.Request.Context(), &buf)
	c.Data(http.StatusOK, "text/html; charset=utf-8", buf.Bytes())
}

func QuizNewHandler(c *gin.Context) {
	admin := GetAdminFromContext(c)
	db := database.GetDB()

	var categories []database.Category
	db.Where("status = ?", "active").Order("sort_order ASC, name ASC").Find(&categories)

	var buf bytes.Buffer
	templates.QuizForm(admin.Name, nil, categories, "").Render(c.Request.Context(), &buf)
	c.Data(http.StatusOK, "text/html; charset=utf-8", buf.Bytes())
}

func QuizCreateHandler(c *gin.Context) {
	admin := GetAdminFromContext(c)
	db := database.GetDB()

	title := c.PostForm("title")
	if title == "" {
		var categories []database.Category
		db.Where("status = ?", "active").Order("sort_order ASC, name ASC").Find(&categories)
		var buf bytes.Buffer
		templates.QuizForm(admin.Name, nil, categories, "タイトルは必須です").Render(c.Request.Context(), &buf)
		c.Data(http.StatusOK, "text/html; charset=utf-8", buf.Bytes())
		return
	}

	quiz := database.Quiz{
		Title:       title,
		Description: c.PostForm("description"),
		Requirement: c.PostForm("requirement"),
		Status:      c.DefaultPostForm("status", "draft"),
		ReleaseDate: time.Now(),
	}

	if catID := c.PostForm("category_id"); catID != "" {
		if catUUID, err := uuid.Parse(catID); err == nil {
			quiz.CategoryID = &catUUID
		}
	}

	if rd := c.PostForm("release_date"); rd != "" {
		if releaseDate, err := time.Parse("2006-01-02", rd); err == nil {
			quiz.ReleaseDate = releaseDate
		}
	}

	if err := db.Create(&quiz).Error; err != nil {
		var categories []database.Category
		db.Where("status = ?", "active").Order("sort_order ASC, name ASC").Find(&categories)
		var buf bytes.Buffer
		templates.QuizForm(admin.Name, nil, categories, "クイズの作成に失敗しました").Render(c.Request.Context(), &buf)
		c.Data(http.StatusOK, "text/html; charset=utf-8", buf.Bytes())
		return
	}

	db.Create(&database.AdminAuditLog{
		AdminUserID: admin.ID,
		Action:      "create_quiz",
		EntityType:  "quiz",
		EntityID:    quiz.ID.String(),
		IPAddress:   c.ClientIP(),
	})

	c.Redirect(http.StatusFound, "/admin/quizzes/"+quiz.ID.String())
}

func QuizDetailHandler(c *gin.Context) {
	admin := GetAdminFromContext(c)
	db := database.GetDB()

	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.Redirect(http.StatusFound, "/admin/quizzes")
		return
	}

	var quiz database.Quiz
	if err := db.Preload("Category").First(&quiz, "id = ?", id).Error; err != nil {
		c.Redirect(http.StatusFound, "/admin/quizzes")
		return
	}

	// Load recent answers separately
	var answers []database.Answer
	db.Preload("User").Where("quiz_id = ?", id).Order("created_at DESC").Limit(10).Find(&answers)

	var buf bytes.Buffer
	templates.QuizDetail(admin.Name, quiz, answers).Render(c.Request.Context(), &buf)
	c.Data(http.StatusOK, "text/html; charset=utf-8", buf.Bytes())
}

func QuizEditHandler(c *gin.Context) {
	admin := GetAdminFromContext(c)
	db := database.GetDB()

	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.Redirect(http.StatusFound, "/admin/quizzes")
		return
	}

	var quiz database.Quiz
	if err := db.Preload("Category").First(&quiz, "id = ?", id).Error; err != nil {
		c.Redirect(http.StatusFound, "/admin/quizzes")
		return
	}

	var categories []database.Category
	db.Where("status = ?", "active").Order("sort_order ASC, name ASC").Find(&categories)

	var buf bytes.Buffer
	templates.QuizForm(admin.Name, &quiz, categories, "").Render(c.Request.Context(), &buf)
	c.Data(http.StatusOK, "text/html; charset=utf-8", buf.Bytes())
}

func QuizUpdateHandler(c *gin.Context) {
	admin := GetAdminFromContext(c)
	db := database.GetDB()

	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.Redirect(http.StatusFound, "/admin/quizzes")
		return
	}

	var quiz database.Quiz
	if err := db.First(&quiz, "id = ?", id).Error; err != nil {
		c.Redirect(http.StatusFound, "/admin/quizzes")
		return
	}

	title := c.PostForm("title")
	if title == "" {
		var categories []database.Category
		db.Where("status = ?", "active").Order("sort_order ASC, name ASC").Find(&categories)
		var buf bytes.Buffer
		templates.QuizForm(admin.Name, &quiz, categories, "タイトルは必須です").Render(c.Request.Context(), &buf)
		c.Data(http.StatusOK, "text/html; charset=utf-8", buf.Bytes())
		return
	}

	updates := map[string]interface{}{
		"title":       title,
		"description": c.PostForm("description"),
		"requirement": c.PostForm("requirement"),
		"status":      c.DefaultPostForm("status", "draft"),
	}

	if catID := c.PostForm("category_id"); catID != "" {
		if catUUID, err := uuid.Parse(catID); err == nil {
			updates["category_id"] = catUUID
		}
	} else {
		updates["category_id"] = nil
	}

	if rd := c.PostForm("release_date"); rd != "" {
		if releaseDate, err := time.Parse("2006-01-02", rd); err == nil {
			updates["release_date"] = releaseDate
		}
	}

	db.Model(&quiz).Updates(updates)

	db.Create(&database.AdminAuditLog{
		AdminUserID: admin.ID,
		Action:      "update_quiz",
		EntityType:  "quiz",
		EntityID:    quiz.ID.String(),
		IPAddress:   c.ClientIP(),
	})

	c.Redirect(http.StatusFound, "/admin/quizzes/"+quiz.ID.String())
}

func QuizDeleteHandler(c *gin.Context) {
	admin := GetAdminFromContext(c)
	db := database.GetDB()

	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.Redirect(http.StatusFound, "/admin/quizzes")
		return
	}

	var quiz database.Quiz
	if err := db.First(&quiz, "id = ?", id).Error; err != nil {
		c.Redirect(http.StatusFound, "/admin/quizzes")
		return
	}

	db.Delete(&quiz)

	db.Create(&database.AdminAuditLog{
		AdminUserID: admin.ID,
		Action:      "delete_quiz",
		EntityType:  "quiz",
		EntityID:    id.String(),
		IPAddress:   c.ClientIP(),
	})

	c.Redirect(http.StatusFound, "/admin/quizzes")
}
