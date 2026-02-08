package admin

import (
	"bytes"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/serifu/backend/internal/admin/templates"
	"github.com/serifu/backend/internal/database"
)

func UserListHandler(c *gin.Context) {
	admin := GetAdminFromContext(c)
	db := database.GetDB()

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	if page < 1 {
		page = 1
	}
	pageSize := parseSizeParam(c, 10)
	search := c.Query("search")
	status := c.Query("status")

	query := db.Model(&database.User{})
	if search != "" {
		query = query.Where("name ILIKE ? OR email ILIKE ?", "%"+search+"%", "%"+search+"%")
	}
	if status != "" {
		query = query.Where("status = ?", status)
	}

	var total int64
	query.Count(&total)

	var users []database.User
	query.Order("created_at DESC").
		Offset((page - 1) * pageSize).
		Limit(pageSize).
		Find(&users)

	totalPages := int(total) / pageSize
	if int(total)%pageSize > 0 {
		totalPages++
	}

	var buf bytes.Buffer
	templates.UserList(admin.Name, users, search, status, page, totalPages, int(total), pageSize).Render(c.Request.Context(), &buf)
	c.Data(http.StatusOK, "text/html; charset=utf-8", buf.Bytes())
}

func UserDetailHandler(c *gin.Context) {
	admin := GetAdminFromContext(c)
	db := database.GetDB()

	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.Redirect(http.StatusFound, "/admin/users")
		return
	}

	var user database.User
	if err := db.First(&user, "id = ?", id).Error; err != nil {
		c.Redirect(http.StatusFound, "/admin/users")
		return
	}

	var answerCount int64
	db.Model(&database.Answer{}).Where("user_id = ?", id).Count(&answerCount)

	var commentCount int64
	db.Model(&database.Comment{}).Where("user_id = ?", id).Count(&commentCount)

	var followerCount int64
	db.Model(&database.Follow{}).Where("following_id = ?", id).Count(&followerCount)

	var followingCount int64
	db.Model(&database.Follow{}).Where("follower_id = ?", id).Count(&followingCount)

	var recentAnswers []database.Answer
	db.Preload("Quiz").Where("user_id = ?", id).Order("created_at DESC").Limit(10).Find(&recentAnswers)

	var buf bytes.Buffer
	templates.UserDetail(admin.Name, user, answerCount, commentCount, followerCount, followingCount, recentAnswers).Render(c.Request.Context(), &buf)
	c.Data(http.StatusOK, "text/html; charset=utf-8", buf.Bytes())
}

func UserSuspendHandler(c *gin.Context) {
	admin := GetAdminFromContext(c)
	db := database.GetDB()

	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.Redirect(http.StatusFound, "/admin/users")
		return
	}

	var user database.User
	if err := db.First(&user, "id = ?", id).Error; err != nil {
		c.Redirect(http.StatusFound, "/admin/users")
		return
	}

	db.Model(&user).Update("status", "suspended")

	db.Create(&database.AdminAuditLog{
		AdminUserID: admin.ID,
		Action:      "suspend_user",
		EntityType:  "user",
		EntityID:    id.String(),
		IPAddress:   c.ClientIP(),
	})

	c.Redirect(http.StatusFound, "/admin/users/"+id.String())
}

func UserUnsuspendHandler(c *gin.Context) {
	admin := GetAdminFromContext(c)
	db := database.GetDB()

	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.Redirect(http.StatusFound, "/admin/users")
		return
	}

	var user database.User
	if err := db.First(&user, "id = ?", id).Error; err != nil {
		c.Redirect(http.StatusFound, "/admin/users")
		return
	}

	db.Model(&user).Update("status", "active")

	db.Create(&database.AdminAuditLog{
		AdminUserID: admin.ID,
		Action:      "unsuspend_user",
		EntityType:  "user",
		EntityID:    id.String(),
		IPAddress:   c.ClientIP(),
	})

	c.Redirect(http.StatusFound, "/admin/users/"+id.String())
}
