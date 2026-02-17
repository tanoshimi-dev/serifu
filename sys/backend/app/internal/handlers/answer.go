package handlers

import (
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/serifu/backend/internal/database"
	"github.com/serifu/backend/internal/utils"
)

type AnswerHandler struct {
	defaultPageSize int
	maxPageSize     int
}

func NewAnswerHandler(defaultPageSize, maxPageSize int) *AnswerHandler {
	return &AnswerHandler{
		defaultPageSize: defaultPageSize,
		maxPageSize:     maxPageSize,
	}
}

type CreateAnswerRequest struct {
	Content string `json:"content" binding:"required,max=150"`
}

type UpdateAnswerRequest struct {
	Content string `json:"content" binding:"max=150"`
}

func (h *AnswerHandler) GetAnswersForQuiz(c *gin.Context) {
	db := database.GetDB()
	quizID := c.Param("id")

	quizUUID, err := uuid.Parse(quizID)
	if err != nil {
		utils.BadRequestResponse(c, "Invalid quiz ID")
		return
	}

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", strconv.Itoa(h.defaultPageSize)))
	if pageSize > h.maxPageSize {
		pageSize = h.maxPageSize
	}
	if page < 1 {
		page = 1
	}

	sort := c.DefaultQuery("sort", "latest")

	query := db.Model(&database.Answer{}).
		Preload("User").
		Where("quiz_id = ? AND status = ?", quizUUID, "active")

	var total int64
	query.Count(&total)

	switch sort {
	case "popular":
		query = query.Order("like_count DESC, created_at DESC")
	case "trending":
		query = query.Order("(like_count + comment_count * 2 + view_count * 0.1) DESC, created_at DESC")
	default:
		query = query.Order("created_at DESC")
	}

	var answers []database.Answer
	offset := (page - 1) * pageSize
	if err := query.Offset(offset).Limit(pageSize).Find(&answers).Error; err != nil {
		utils.InternalErrorResponse(c, "Failed to fetch answers")
		return
	}

	utils.PaginatedSuccessResponse(c, answers, page, pageSize, total)
}

func (h *AnswerHandler) CreateAnswer(c *gin.Context) {
	db := database.GetDB()
	quizID := c.Param("id")

	quizUUID, err := uuid.Parse(quizID)
	if err != nil {
		utils.BadRequestResponse(c, "Invalid quiz ID")
		return
	}

	var quiz database.Quiz
	if err := db.First(&quiz, "id = ?", quizUUID).Error; err != nil {
		utils.NotFoundResponse(c, "Quiz not found")
		return
	}

	userID := c.GetHeader("X-User-ID")
	if userID == "" {
		utils.UnauthorizedResponse(c, "User ID required")
		return
	}

	userUUID, err := uuid.Parse(userID)
	if err != nil {
		utils.BadRequestResponse(c, "Invalid user ID")
		return
	}

	var req CreateAnswerRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid request body: content is required and must be max 150 characters")
		return
	}

	var existingAnswer database.Answer
	if err := db.Where("quiz_id = ? AND user_id = ?", quizUUID, userUUID).First(&existingAnswer).Error; err == nil {
		utils.BadRequestResponse(c, "You have already answered this quiz")
		return
	}

	answer := database.Answer{
		QuizID:  quizUUID,
		UserID:  userUUID,
		Content: req.Content,
		Status:  "active",
	}

	if err := db.Create(&answer).Error; err != nil {
		utils.InternalErrorResponse(c, "Failed to create answer")
		return
	}

	db.Model(&quiz).Update("answer_count", quiz.AnswerCount+1)

	db.Preload("User").First(&answer, "id = ?", answer.ID)

	utils.CreatedResponse(c, answer)
}

func (h *AnswerHandler) GetAnswer(c *gin.Context) {
	db := database.GetDB()
	id := c.Param("id")

	answerID, err := uuid.Parse(id)
	if err != nil {
		utils.BadRequestResponse(c, "Invalid answer ID")
		return
	}

	var answer database.Answer
	if err := db.Preload("User").Preload("Quiz").First(&answer, "id = ?", answerID).Error; err != nil {
		utils.NotFoundResponse(c, "Answer not found")
		return
	}

	db.Model(&answer).Update("view_count", answer.ViewCount+1)

	utils.SuccessResponse(c, answer)
}

func (h *AnswerHandler) UpdateAnswer(c *gin.Context) {
	db := database.GetDB()
	id := c.Param("id")

	answerID, err := uuid.Parse(id)
	if err != nil {
		utils.BadRequestResponse(c, "Invalid answer ID")
		return
	}

	userID := c.GetHeader("X-User-ID")
	if userID == "" {
		utils.UnauthorizedResponse(c, "User ID required")
		return
	}

	userUUID, err := uuid.Parse(userID)
	if err != nil {
		utils.BadRequestResponse(c, "Invalid user ID")
		return
	}

	var answer database.Answer
	if err := db.First(&answer, "id = ?", answerID).Error; err != nil {
		utils.NotFoundResponse(c, "Answer not found")
		return
	}

	if answer.UserID != userUUID {
		utils.ForbiddenResponse(c, "You can only update your own answers")
		return
	}

	var req UpdateAnswerRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid request body")
		return
	}

	if req.Content != "" {
		answer.Content = req.Content
	}

	if err := db.Save(&answer).Error; err != nil {
		utils.InternalErrorResponse(c, "Failed to update answer")
		return
	}

	db.Preload("User").First(&answer, "id = ?", answer.ID)

	utils.SuccessResponse(c, answer)
}

func (h *AnswerHandler) GetTimeline(c *gin.Context) {
	db := database.GetDB()

	userID := c.GetHeader("X-User-ID")
	if userID == "" {
		utils.UnauthorizedResponse(c, "User ID required")
		return
	}
	userUUID, err := uuid.Parse(userID)
	if err != nil {
		utils.BadRequestResponse(c, "Invalid user ID")
		return
	}

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", strconv.Itoa(h.defaultPageSize)))
	if pageSize > h.maxPageSize {
		pageSize = h.maxPageSize
	}
	if page < 1 {
		page = 1
	}

	followingSubquery := db.Model(&database.Follow{}).
		Select("following_id").
		Where("follower_id = ?", userUUID)

	query := db.Model(&database.Answer{}).
		Preload("User").
		Preload("Quiz").
		Where("user_id IN (?) AND status = ?", followingSubquery, "active")

	var total int64
	query.Count(&total)

	var answers []database.Answer
	offset := (page - 1) * pageSize
	if err := query.Order("created_at DESC").Offset(offset).Limit(pageSize).Find(&answers).Error; err != nil {
		utils.InternalErrorResponse(c, "Failed to fetch timeline")
		return
	}

	utils.PaginatedSuccessResponse(c, answers, page, pageSize, total)
}

func (h *AnswerHandler) DeleteAnswer(c *gin.Context) {
	db := database.GetDB()
	id := c.Param("id")

	answerID, err := uuid.Parse(id)
	if err != nil {
		utils.BadRequestResponse(c, "Invalid answer ID")
		return
	}

	userID := c.GetHeader("X-User-ID")
	if userID == "" {
		utils.UnauthorizedResponse(c, "User ID required")
		return
	}

	userUUID, err := uuid.Parse(userID)
	if err != nil {
		utils.BadRequestResponse(c, "Invalid user ID")
		return
	}

	var answer database.Answer
	if err := db.First(&answer, "id = ?", answerID).Error; err != nil {
		utils.NotFoundResponse(c, "Answer not found")
		return
	}

	if answer.UserID != userUUID {
		utils.ForbiddenResponse(c, "You can only delete your own answers")
		return
	}

	if err := db.Delete(&answer).Error; err != nil {
		utils.InternalErrorResponse(c, "Failed to delete answer")
		return
	}

	var quiz database.Quiz
	if err := db.First(&quiz, "id = ?", answer.QuizID).Error; err == nil {
		db.Model(&quiz).Update("answer_count", quiz.AnswerCount-1)
	}

	utils.SuccessResponse(c, gin.H{"message": "Answer deleted successfully"})
}
