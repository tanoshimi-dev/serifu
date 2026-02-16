package handlers

import (
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/serifu/backend/internal/database"
	"github.com/serifu/backend/internal/utils"
)

type CommentHandler struct {
	defaultPageSize int
	maxPageSize     int
}

func NewCommentHandler(defaultPageSize, maxPageSize int) *CommentHandler {
	return &CommentHandler{
		defaultPageSize: defaultPageSize,
		maxPageSize:     maxPageSize,
	}
}

type CreateCommentRequest struct {
	Content string `json:"content" binding:"required"`
}

func (h *CommentHandler) GetCommentsForAnswer(c *gin.Context) {
	db := database.GetDB()
	answerID := c.Param("id")

	answerUUID, err := uuid.Parse(answerID)
	if err != nil {
		utils.BadRequestResponse(c, "Invalid answer ID")
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

	query := db.Model(&database.Comment{}).
		Preload("User").
		Where("answer_id = ? AND status = ?", answerUUID, "active")

	var total int64
	query.Count(&total)

	var comments []database.Comment
	offset := (page - 1) * pageSize
	if err := query.Order("created_at ASC").Offset(offset).Limit(pageSize).Find(&comments).Error; err != nil {
		utils.InternalErrorResponse(c, "Failed to fetch comments")
		return
	}

	utils.PaginatedSuccessResponse(c, comments, page, pageSize, total)
}

func (h *CommentHandler) CreateComment(c *gin.Context) {
	db := database.GetDB()
	answerID := c.Param("id")

	answerUUID, err := uuid.Parse(answerID)
	if err != nil {
		utils.BadRequestResponse(c, "Invalid answer ID")
		return
	}

	var answer database.Answer
	if err := db.First(&answer, "id = ?", answerUUID).Error; err != nil {
		utils.NotFoundResponse(c, "Answer not found")
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

	var req CreateCommentRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid request body: content is required")
		return
	}

	comment := database.Comment{
		AnswerID: answerUUID,
		UserID:   userUUID,
		Content:  req.Content,
		Status:   "active",
	}

	if err := db.Create(&comment).Error; err != nil {
		utils.InternalErrorResponse(c, "Failed to create comment")
		return
	}

	db.Model(&answer).Update("comment_count", answer.CommentCount+1)

	db.Preload("User").First(&comment, "id = ?", comment.ID)

	CreateNotification(db, answer.UserID, userUUID, "comment", "answer", answerUUID)

	utils.CreatedResponse(c, comment)
}

func (h *CommentHandler) DeleteComment(c *gin.Context) {
	db := database.GetDB()
	id := c.Param("id")

	commentID, err := uuid.Parse(id)
	if err != nil {
		utils.BadRequestResponse(c, "Invalid comment ID")
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

	var comment database.Comment
	if err := db.First(&comment, "id = ?", commentID).Error; err != nil {
		utils.NotFoundResponse(c, "Comment not found")
		return
	}

	if comment.UserID != userUUID {
		utils.ForbiddenResponse(c, "You can only delete your own comments")
		return
	}

	if err := db.Delete(&comment).Error; err != nil {
		utils.InternalErrorResponse(c, "Failed to delete comment")
		return
	}

	var answer database.Answer
	if err := db.First(&answer, "id = ?", comment.AnswerID).Error; err == nil && answer.CommentCount > 0 {
		db.Model(&answer).Update("comment_count", answer.CommentCount-1)
	}

	utils.SuccessResponse(c, gin.H{"message": "Comment deleted successfully"})
}
