package admin

import (
	"bytes"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/serifu/backend/internal/admin/templates"
	"github.com/serifu/backend/internal/database"
)

func DashboardHandler(c *gin.Context) {
	adminUser := GetAdminFromContext(c)
	db := database.GetDB()
	today := time.Now().Truncate(24 * time.Hour)

	var stats templates.DashboardStats

	db.Model(&database.User{}).Count(&stats.TotalUsers)
	db.Model(&database.Quiz{}).Count(&stats.TotalQuizzes)
	db.Model(&database.Answer{}).Count(&stats.TotalAnswers)
	db.Model(&database.Comment{}).Count(&stats.TotalComments)

	db.Model(&database.User{}).Where("created_at >= ?", today).Count(&stats.TodayUsers)
	db.Model(&database.Quiz{}).Where("created_at >= ?", today).Count(&stats.TodayQuizzes)
	db.Model(&database.Answer{}).Where("created_at >= ?", today).Count(&stats.TodayAnswers)
	db.Model(&database.Comment{}).Where("created_at >= ?", today).Count(&stats.TodayComments)

	db.Order("created_at DESC").Limit(5).Find(&stats.RecentUsers)
	db.Preload("Category").Order("created_at DESC").Limit(5).Find(&stats.RecentQuizzes)
	db.Preload("User").Preload("Quiz").Order("created_at DESC").Limit(5).Find(&stats.RecentAnswers)
	db.Preload("User").Order("created_at DESC").Limit(5).Find(&stats.RecentComments)

	var buf bytes.Buffer
	templates.Dashboard(adminUser.Name, stats).Render(c.Request.Context(), &buf)
	c.Data(http.StatusOK, "text/html; charset=utf-8", buf.Bytes())
}
