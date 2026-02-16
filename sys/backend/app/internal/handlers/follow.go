package handlers

import (
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/serifu/backend/internal/database"
	"github.com/serifu/backend/internal/utils"
)

type FollowHandler struct {
	defaultPageSize int
	maxPageSize     int
}

func NewFollowHandler(defaultPageSize, maxPageSize int) *FollowHandler {
	return &FollowHandler{
		defaultPageSize: defaultPageSize,
		maxPageSize:     maxPageSize,
	}
}

func (h *FollowHandler) FollowUser(c *gin.Context) {
	db := database.GetDB()
	targetID := c.Param("id")

	targetUUID, err := uuid.Parse(targetID)
	if err != nil {
		utils.BadRequestResponse(c, "Invalid user ID")
		return
	}

	followerID := c.GetHeader("X-User-ID")
	if followerID == "" {
		utils.UnauthorizedResponse(c, "User ID required")
		return
	}

	followerUUID, err := uuid.Parse(followerID)
	if err != nil {
		utils.BadRequestResponse(c, "Invalid follower ID")
		return
	}

	if targetUUID == followerUUID {
		utils.BadRequestResponse(c, "You cannot follow yourself")
		return
	}

	var targetUser database.User
	if err := db.First(&targetUser, "id = ?", targetUUID).Error; err != nil {
		utils.NotFoundResponse(c, "User not found")
		return
	}

	var existingFollow database.Follow
	if err := db.Where("follower_id = ? AND following_id = ?", followerUUID, targetUUID).First(&existingFollow).Error; err == nil {
		utils.BadRequestResponse(c, "You are already following this user")
		return
	}

	follow := database.Follow{
		FollowerID:  followerUUID,
		FollowingID: targetUUID,
	}

	if err := db.Create(&follow).Error; err != nil {
		utils.InternalErrorResponse(c, "Failed to follow user")
		return
	}

	CreateNotification(db, targetUUID, followerUUID, "follow", "user", targetUUID)

	utils.CreatedResponse(c, gin.H{"message": "User followed successfully"})
}

func (h *FollowHandler) UnfollowUser(c *gin.Context) {
	db := database.GetDB()
	targetID := c.Param("id")

	targetUUID, err := uuid.Parse(targetID)
	if err != nil {
		utils.BadRequestResponse(c, "Invalid user ID")
		return
	}

	followerID := c.GetHeader("X-User-ID")
	if followerID == "" {
		utils.UnauthorizedResponse(c, "User ID required")
		return
	}

	followerUUID, err := uuid.Parse(followerID)
	if err != nil {
		utils.BadRequestResponse(c, "Invalid follower ID")
		return
	}

	var follow database.Follow
	if err := db.Where("follower_id = ? AND following_id = ?", followerUUID, targetUUID).First(&follow).Error; err != nil {
		utils.NotFoundResponse(c, "Follow relationship not found")
		return
	}

	if err := db.Delete(&follow).Error; err != nil {
		utils.InternalErrorResponse(c, "Failed to unfollow user")
		return
	}

	utils.SuccessResponse(c, gin.H{"message": "User unfollowed successfully"})
}

func (h *FollowHandler) GetFollowers(c *gin.Context) {
	db := database.GetDB()
	userID := c.Param("id")

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

	query := db.Model(&database.Follow{}).
		Preload("Follower").
		Where("following_id = ?", userUUID)

	var total int64
	query.Count(&total)

	var follows []database.Follow
	offset := (page - 1) * pageSize
	if err := query.Order("created_at DESC").Offset(offset).Limit(pageSize).Find(&follows).Error; err != nil {
		utils.InternalErrorResponse(c, "Failed to fetch followers")
		return
	}

	followers := make([]database.User, 0, len(follows))
	for _, f := range follows {
		if f.Follower != nil {
			followers = append(followers, *f.Follower)
		}
	}

	utils.PaginatedSuccessResponse(c, followers, page, pageSize, total)
}

func (h *FollowHandler) GetFollowing(c *gin.Context) {
	db := database.GetDB()
	userID := c.Param("id")

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

	query := db.Model(&database.Follow{}).
		Preload("Following").
		Where("follower_id = ?", userUUID)

	var total int64
	query.Count(&total)

	var follows []database.Follow
	offset := (page - 1) * pageSize
	if err := query.Order("created_at DESC").Offset(offset).Limit(pageSize).Find(&follows).Error; err != nil {
		utils.InternalErrorResponse(c, "Failed to fetch following")
		return
	}

	following := make([]database.User, 0, len(follows))
	for _, f := range follows {
		if f.Following != nil {
			following = append(following, *f.Following)
		}
	}

	utils.PaginatedSuccessResponse(c, following, page, pageSize, total)
}
