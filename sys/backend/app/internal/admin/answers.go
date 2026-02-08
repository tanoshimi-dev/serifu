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

func AnswerListHandler(c *gin.Context) {
	admin := GetAdminFromContext(c)
	db := database.GetDB()

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	if page < 1 {
		page = 1
	}
	pageSize := parseSizeParam(c, 10)
	search := c.Query("search")
	status := c.Query("status")

	query := db.Model(&database.Answer{}).Preload("User").Preload("Quiz")
	if search != "" {
		query = query.Where("content ILIKE ?", "%"+search+"%")
	}
	if status != "" {
		query = query.Where("status = ?", status)
	}

	var total int64
	query.Count(&total)

	var answers []database.Answer
	query.Order("created_at DESC").
		Offset((page - 1) * pageSize).
		Limit(pageSize).
		Find(&answers)

	totalPages := int(total) / pageSize
	if int(total)%pageSize > 0 {
		totalPages++
	}

	var buf bytes.Buffer
	templates.AnswerList(admin.Name, answers, search, status, page, totalPages, int(total), pageSize).Render(c.Request.Context(), &buf)
	c.Data(http.StatusOK, "text/html; charset=utf-8", buf.Bytes())
}

func AnswerDetailHandler(c *gin.Context) {
	admin := GetAdminFromContext(c)
	db := database.GetDB()

	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.Redirect(http.StatusFound, "/admin/answers")
		return
	}

	var answer database.Answer
	if err := db.Preload("User").Preload("Quiz").First(&answer, "id = ?", id).Error; err != nil {
		c.Redirect(http.StatusFound, "/admin/answers")
		return
	}

	var comments []database.Comment
	db.Preload("User").Where("answer_id = ?", id).Order("created_at DESC").Limit(20).Find(&comments)

	var buf bytes.Buffer
	templates.AnswerDetail(admin.Name, answer, comments).Render(c.Request.Context(), &buf)
	c.Data(http.StatusOK, "text/html; charset=utf-8", buf.Bytes())
}

func AnswerModerateHandler(c *gin.Context) {
	admin := GetAdminFromContext(c)
	db := database.GetDB()

	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.Redirect(http.StatusFound, "/admin/answers")
		return
	}

	var answer database.Answer
	if err := db.First(&answer, "id = ?", id).Error; err != nil {
		c.Redirect(http.StatusFound, "/admin/answers")
		return
	}

	db.Model(&answer).Update("status", "moderated")

	db.Create(&database.AdminAuditLog{
		AdminUserID: admin.ID,
		Action:      "moderate_answer",
		EntityType:  "answer",
		EntityID:    id.String(),
		IPAddress:   c.ClientIP(),
	})

	c.Redirect(http.StatusFound, "/admin/answers/"+id.String())
}

func AnswerUnmoderateHandler(c *gin.Context) {
	admin := GetAdminFromContext(c)
	db := database.GetDB()

	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.Redirect(http.StatusFound, "/admin/answers")
		return
	}

	var answer database.Answer
	if err := db.First(&answer, "id = ?", id).Error; err != nil {
		c.Redirect(http.StatusFound, "/admin/answers")
		return
	}

	db.Model(&answer).Update("status", "active")

	db.Create(&database.AdminAuditLog{
		AdminUserID: admin.ID,
		Action:      "unmoderate_answer",
		EntityType:  "answer",
		EntityID:    id.String(),
		IPAddress:   c.ClientIP(),
	})

	c.Redirect(http.StatusFound, "/admin/answers/"+id.String())
}
