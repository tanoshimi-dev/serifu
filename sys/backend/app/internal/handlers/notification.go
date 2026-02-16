package handlers

import (
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/serifu/backend/internal/database"
	"github.com/serifu/backend/internal/utils"
	"gorm.io/gorm"
)

type NotificationHandler struct {
	defaultPageSize int
	maxPageSize     int
}

func NewNotificationHandler(defaultPageSize, maxPageSize int) *NotificationHandler {
	return &NotificationHandler{
		defaultPageSize: defaultPageSize,
		maxPageSize:     maxPageSize,
	}
}

func (h *NotificationHandler) GetNotifications(c *gin.Context) {
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

	query := db.Model(&database.Notification{}).
		Preload("Actor").
		Where("user_id = ?", userUUID)

	var total int64
	query.Count(&total)

	var notifications []database.Notification
	offset := (page - 1) * pageSize
	if err := query.Order("created_at DESC").Offset(offset).Limit(pageSize).Find(&notifications).Error; err != nil {
		utils.InternalErrorResponse(c, "Failed to fetch notifications")
		return
	}

	utils.PaginatedSuccessResponse(c, notifications, page, pageSize, total)
}

func (h *NotificationHandler) MarkAllAsRead(c *gin.Context) {
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

	if err := db.Model(&database.Notification{}).
		Where("user_id = ? AND is_read = ?", userUUID, false).
		Update("is_read", true).Error; err != nil {
		utils.InternalErrorResponse(c, "Failed to mark notifications as read")
		return
	}

	utils.SuccessResponse(c, gin.H{"message": "All notifications marked as read"})
}

func (h *NotificationHandler) GetUnreadCount(c *gin.Context) {
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

	var count int64
	if err := db.Model(&database.Notification{}).
		Where("user_id = ? AND is_read = ?", userUUID, false).
		Count(&count).Error; err != nil {
		utils.InternalErrorResponse(c, "Failed to get unread count")
		return
	}

	utils.SuccessResponse(c, gin.H{"unread_count": count})
}

// CreateNotification creates a notification record. Skips if actor == user (don't notify yourself).
func CreateNotification(db *gorm.DB, userID, actorID uuid.UUID, notifType, targetType string, targetID uuid.UUID) {
	if userID == actorID {
		return
	}

	notification := database.Notification{
		UserID:     userID,
		ActorID:    actorID,
		Type:       notifType,
		TargetType: targetType,
		TargetID:   targetID,
	}

	db.Create(&notification)
}
