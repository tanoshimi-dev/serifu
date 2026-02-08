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

func CommentListHandler(c *gin.Context) {
	admin := GetAdminFromContext(c)
	db := database.GetDB()

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	if page < 1 {
		page = 1
	}
	pageSize := parseSizeParam(c, 10)
	search := c.Query("search")
	status := c.Query("status")

	query := db.Model(&database.Comment{}).Preload("User")
	if search != "" {
		query = query.Where("content ILIKE ?", "%"+search+"%")
	}
	if status != "" {
		query = query.Where("status = ?", status)
	}

	var total int64
	query.Count(&total)

	var comments []database.Comment
	query.Order("created_at DESC").
		Offset((page - 1) * pageSize).
		Limit(pageSize).
		Find(&comments)

	totalPages := int(total) / pageSize
	if int(total)%pageSize > 0 {
		totalPages++
	}

	var buf bytes.Buffer
	templates.CommentList(admin.Name, comments, search, status, page, totalPages, int(total), pageSize).Render(c.Request.Context(), &buf)
	c.Data(http.StatusOK, "text/html; charset=utf-8", buf.Bytes())
}

func CommentDetailHandler(c *gin.Context) {
	admin := GetAdminFromContext(c)
	db := database.GetDB()

	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.Redirect(http.StatusFound, "/admin/comments")
		return
	}

	var comment database.Comment
	if err := db.Preload("User").Preload("Answer").First(&comment, "id = ?", id).Error; err != nil {
		c.Redirect(http.StatusFound, "/admin/comments")
		return
	}

	var buf bytes.Buffer
	templates.CommentDetail(admin.Name, comment).Render(c.Request.Context(), &buf)
	c.Data(http.StatusOK, "text/html; charset=utf-8", buf.Bytes())
}

func CommentModerateHandler(c *gin.Context) {
	admin := GetAdminFromContext(c)
	db := database.GetDB()

	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.Redirect(http.StatusFound, "/admin/comments")
		return
	}

	var comment database.Comment
	if err := db.First(&comment, "id = ?", id).Error; err != nil {
		c.Redirect(http.StatusFound, "/admin/comments")
		return
	}

	db.Model(&comment).Update("status", "moderated")

	db.Create(&database.AdminAuditLog{
		AdminUserID: admin.ID,
		Action:      "moderate_comment",
		EntityType:  "comment",
		EntityID:    id.String(),
		IPAddress:   c.ClientIP(),
	})

	c.Redirect(http.StatusFound, "/admin/comments/"+id.String())
}

func CommentUnmoderateHandler(c *gin.Context) {
	admin := GetAdminFromContext(c)
	db := database.GetDB()

	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.Redirect(http.StatusFound, "/admin/comments")
		return
	}

	var comment database.Comment
	if err := db.First(&comment, "id = ?", id).Error; err != nil {
		c.Redirect(http.StatusFound, "/admin/comments")
		return
	}

	db.Model(&comment).Update("status", "active")

	db.Create(&database.AdminAuditLog{
		AdminUserID: admin.ID,
		Action:      "unmoderate_comment",
		EntityType:  "comment",
		EntityID:    id.String(),
		IPAddress:   c.ClientIP(),
	})

	c.Redirect(http.StatusFound, "/admin/comments/"+id.String())
}
