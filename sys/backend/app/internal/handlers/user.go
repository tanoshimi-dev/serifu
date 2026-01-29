package handlers

import (
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/serifu/backend/internal/database"
	"github.com/serifu/backend/internal/utils"
)

type UserHandler struct {
	defaultPageSize int
	maxPageSize     int
}

func NewUserHandler(defaultPageSize, maxPageSize int) *UserHandler {
	return &UserHandler{
		defaultPageSize: defaultPageSize,
		maxPageSize:     maxPageSize,
	}
}

type UpdateUserRequest struct {
	Name   string `json:"name"`
	Avatar string `json:"avatar"`
	Bio    string `json:"bio"`
}

type UserProfileResponse struct {
	database.User
	FollowerCount  int64 `json:"follower_count"`
	FollowingCount int64 `json:"following_count"`
	AnswerCount    int64 `json:"answer_count"`
	IsFollowing    bool  `json:"is_following"`
}

func (h *UserHandler) GetUser(c *gin.Context) {
	db := database.GetDB()
	id := c.Param("id")

	userID, err := uuid.Parse(id)
	if err != nil {
		utils.BadRequestResponse(c, "Invalid user ID")
		return
	}

	var user database.User
	if err := db.First(&user, "id = ?", userID).Error; err != nil {
		utils.NotFoundResponse(c, "User not found")
		return
	}

	var followerCount int64
	db.Model(&database.Follow{}).Where("following_id = ?", userID).Count(&followerCount)

	var followingCount int64
	db.Model(&database.Follow{}).Where("follower_id = ?", userID).Count(&followingCount)

	var answerCount int64
	db.Model(&database.Answer{}).Where("user_id = ? AND status = ?", userID, "active").Count(&answerCount)

	isFollowing := false
	currentUserID := c.GetHeader("X-User-ID")
	if currentUserID != "" {
		if currentUUID, err := uuid.Parse(currentUserID); err == nil {
			var follow database.Follow
			if err := db.Where("follower_id = ? AND following_id = ?", currentUUID, userID).First(&follow).Error; err == nil {
				isFollowing = true
			}
		}
	}

	response := UserProfileResponse{
		User:           user,
		FollowerCount:  followerCount,
		FollowingCount: followingCount,
		AnswerCount:    answerCount,
		IsFollowing:    isFollowing,
	}

	utils.SuccessResponse(c, response)
}

func (h *UserHandler) GetUserAnswers(c *gin.Context) {
	db := database.GetDB()
	id := c.Param("id")

	userID, err := uuid.Parse(id)
	if err != nil {
		utils.BadRequestResponse(c, "Invalid user ID")
		return
	}

	var user database.User
	if err := db.First(&user, "id = ?", userID).Error; err != nil {
		utils.NotFoundResponse(c, "User not found")
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

	query := db.Model(&database.Answer{}).
		Preload("Quiz").
		Preload("User").
		Where("user_id = ? AND status = ?", userID, "active")

	var total int64
	query.Count(&total)

	var answers []database.Answer
	offset := (page - 1) * pageSize
	if err := query.Order("created_at DESC").Offset(offset).Limit(pageSize).Find(&answers).Error; err != nil {
		utils.InternalErrorResponse(c, "Failed to fetch answers")
		return
	}

	utils.PaginatedSuccessResponse(c, answers, page, pageSize, total)
}

func (h *UserHandler) UpdateUser(c *gin.Context) {
	db := database.GetDB()
	id := c.Param("id")

	userID, err := uuid.Parse(id)
	if err != nil {
		utils.BadRequestResponse(c, "Invalid user ID")
		return
	}

	currentUserID := c.GetHeader("X-User-ID")
	if currentUserID == "" {
		utils.UnauthorizedResponse(c, "User ID required")
		return
	}

	currentUUID, err := uuid.Parse(currentUserID)
	if err != nil {
		utils.BadRequestResponse(c, "Invalid current user ID")
		return
	}

	if userID != currentUUID {
		utils.ForbiddenResponse(c, "You can only update your own profile")
		return
	}

	var user database.User
	if err := db.First(&user, "id = ?", userID).Error; err != nil {
		utils.NotFoundResponse(c, "User not found")
		return
	}

	var req UpdateUserRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid request body")
		return
	}

	updates := map[string]interface{}{}
	if req.Name != "" {
		updates["name"] = req.Name
	}
	if req.Avatar != "" {
		updates["avatar"] = req.Avatar
	}
	if req.Bio != "" {
		updates["bio"] = req.Bio
	}

	if err := db.Model(&user).Updates(updates).Error; err != nil {
		utils.InternalErrorResponse(c, "Failed to update user")
		return
	}

	db.First(&user, "id = ?", userID)

	utils.SuccessResponse(c, user)
}
