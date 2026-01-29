package handlers

import (
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/serifu/backend/internal/database"
	"github.com/serifu/backend/internal/utils"
)

type QuizHandler struct {
	defaultPageSize int
	maxPageSize     int
}

func NewQuizHandler(defaultPageSize, maxPageSize int) *QuizHandler {
	return &QuizHandler{
		defaultPageSize: defaultPageSize,
		maxPageSize:     maxPageSize,
	}
}

type CreateQuizRequest struct {
	Title       string `json:"title" binding:"required"`
	Description string `json:"description"`
	Requirement string `json:"requirement"`
	CategoryID  string `json:"category_id"`
	ReleaseDate string `json:"release_date"`
	Status      string `json:"status"`
}

type UpdateQuizRequest struct {
	Title       string `json:"title"`
	Description string `json:"description"`
	Requirement string `json:"requirement"`
	CategoryID  string `json:"category_id"`
	ReleaseDate string `json:"release_date"`
	Status      string `json:"status"`
}

func (h *QuizHandler) GetDailyQuizzes(c *gin.Context) {
	db := database.GetDB()

	today := time.Now().Truncate(24 * time.Hour)
	tomorrow := today.Add(24 * time.Hour)

	var quizzes []database.Quiz
	if err := db.Preload("Category").
		Where("release_date >= ? AND release_date < ? AND status = ?", today, tomorrow, "active").
		Order("created_at DESC").
		Find(&quizzes).Error; err != nil {
		utils.InternalErrorResponse(c, "Failed to fetch daily quizzes")
		return
	}

	utils.SuccessResponse(c, quizzes)
}

func (h *QuizHandler) GetQuiz(c *gin.Context) {
	db := database.GetDB()
	id := c.Param("id")

	quizID, err := uuid.Parse(id)
	if err != nil {
		utils.BadRequestResponse(c, "Invalid quiz ID")
		return
	}

	var quiz database.Quiz
	if err := db.Preload("Category").First(&quiz, "id = ?", quizID).Error; err != nil {
		utils.NotFoundResponse(c, "Quiz not found")
		return
	}

	utils.SuccessResponse(c, quiz)
}

func (h *QuizHandler) ListQuizzes(c *gin.Context) {
	db := database.GetDB()

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", strconv.Itoa(h.defaultPageSize)))
	if pageSize > h.maxPageSize {
		pageSize = h.maxPageSize
	}
	if page < 1 {
		page = 1
	}

	categoryID := c.Query("category_id")
	status := c.DefaultQuery("status", "active")

	query := db.Model(&database.Quiz{}).Preload("Category")

	if categoryID != "" {
		if catUUID, err := uuid.Parse(categoryID); err == nil {
			query = query.Where("category_id = ?", catUUID)
		}
	}

	if status != "" {
		query = query.Where("status = ?", status)
	}

	var total int64
	query.Count(&total)

	var quizzes []database.Quiz
	offset := (page - 1) * pageSize
	if err := query.Order("release_date DESC").Offset(offset).Limit(pageSize).Find(&quizzes).Error; err != nil {
		utils.InternalErrorResponse(c, "Failed to fetch quizzes")
		return
	}

	utils.PaginatedSuccessResponse(c, quizzes, page, pageSize, total)
}

func (h *QuizHandler) CreateQuiz(c *gin.Context) {
	db := database.GetDB()

	var req CreateQuizRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid request body")
		return
	}

	quiz := database.Quiz{
		Title:       req.Title,
		Description: req.Description,
		Requirement: req.Requirement,
		Status:      "draft",
		ReleaseDate: time.Now(),
	}

	if req.Status != "" {
		quiz.Status = req.Status
	}

	if req.CategoryID != "" {
		if catUUID, err := uuid.Parse(req.CategoryID); err == nil {
			quiz.CategoryID = &catUUID
		}
	}

	if req.ReleaseDate != "" {
		if releaseDate, err := time.Parse("2006-01-02", req.ReleaseDate); err == nil {
			quiz.ReleaseDate = releaseDate
		}
	}

	if err := db.Create(&quiz).Error; err != nil {
		utils.InternalErrorResponse(c, "Failed to create quiz")
		return
	}

	db.Preload("Category").First(&quiz, "id = ?", quiz.ID)

	utils.CreatedResponse(c, quiz)
}

func (h *QuizHandler) UpdateQuiz(c *gin.Context) {
	db := database.GetDB()
	id := c.Param("id")

	quizID, err := uuid.Parse(id)
	if err != nil {
		utils.BadRequestResponse(c, "Invalid quiz ID")
		return
	}

	var quiz database.Quiz
	if err := db.First(&quiz, "id = ?", quizID).Error; err != nil {
		utils.NotFoundResponse(c, "Quiz not found")
		return
	}

	var req UpdateQuizRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid request body")
		return
	}

	updates := map[string]interface{}{}

	if req.Title != "" {
		updates["title"] = req.Title
	}
	if req.Description != "" {
		updates["description"] = req.Description
	}
	if req.Requirement != "" {
		updates["requirement"] = req.Requirement
	}
	if req.Status != "" {
		updates["status"] = req.Status
	}
	if req.CategoryID != "" {
		if catUUID, err := uuid.Parse(req.CategoryID); err == nil {
			updates["category_id"] = catUUID
		}
	}
	if req.ReleaseDate != "" {
		if releaseDate, err := time.Parse("2006-01-02", req.ReleaseDate); err == nil {
			updates["release_date"] = releaseDate
		}
	}

	if err := db.Model(&quiz).Updates(updates).Error; err != nil {
		utils.InternalErrorResponse(c, "Failed to update quiz")
		return
	}

	db.Preload("Category").First(&quiz, "id = ?", quiz.ID)

	utils.SuccessResponse(c, quiz)
}
