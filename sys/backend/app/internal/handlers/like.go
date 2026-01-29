package handlers

import (
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/serifu/backend/internal/database"
	"github.com/serifu/backend/internal/utils"
)

type LikeHandler struct{}

func NewLikeHandler() *LikeHandler {
	return &LikeHandler{}
}

func (h *LikeHandler) LikeAnswer(c *gin.Context) {
	db := database.GetDB()
	answerID := c.Param("id")

	answerUUID, err := uuid.Parse(answerID)
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
	if err := db.First(&answer, "id = ?", answerUUID).Error; err != nil {
		utils.NotFoundResponse(c, "Answer not found")
		return
	}

	var existingLike database.Like
	if err := db.Where("answer_id = ? AND user_id = ?", answerUUID, userUUID).First(&existingLike).Error; err == nil {
		utils.BadRequestResponse(c, "You have already liked this answer")
		return
	}

	like := database.Like{
		AnswerID: answerUUID,
		UserID:   userUUID,
	}

	if err := db.Create(&like).Error; err != nil {
		utils.InternalErrorResponse(c, "Failed to like answer")
		return
	}

	db.Model(&answer).Update("like_count", answer.LikeCount+1)

	var answerUser database.User
	if err := db.First(&answerUser, "id = ?", answer.UserID).Error; err == nil {
		db.Model(&answerUser).Update("total_likes", answerUser.TotalLikes+1)
	}

	utils.CreatedResponse(c, gin.H{"message": "Answer liked successfully"})
}

func (h *LikeHandler) UnlikeAnswer(c *gin.Context) {
	db := database.GetDB()
	answerID := c.Param("id")

	answerUUID, err := uuid.Parse(answerID)
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
	if err := db.First(&answer, "id = ?", answerUUID).Error; err != nil {
		utils.NotFoundResponse(c, "Answer not found")
		return
	}

	var like database.Like
	if err := db.Where("answer_id = ? AND user_id = ?", answerUUID, userUUID).First(&like).Error; err != nil {
		utils.NotFoundResponse(c, "Like not found")
		return
	}

	if err := db.Delete(&like).Error; err != nil {
		utils.InternalErrorResponse(c, "Failed to unlike answer")
		return
	}

	if answer.LikeCount > 0 {
		db.Model(&answer).Update("like_count", answer.LikeCount-1)
	}

	var answerUser database.User
	if err := db.First(&answerUser, "id = ?", answer.UserID).Error; err == nil && answerUser.TotalLikes > 0 {
		db.Model(&answerUser).Update("total_likes", answerUser.TotalLikes-1)
	}

	utils.SuccessResponse(c, gin.H{"message": "Answer unliked successfully"})
}
