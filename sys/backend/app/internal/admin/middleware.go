package admin

import (
	"net/http"

	"github.com/gin-contrib/sessions"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/serifu/backend/internal/database"
)

func AuthRequired() gin.HandlerFunc {
	return func(c *gin.Context) {
		session := sessions.Default(c)
		adminUserID := session.Get("admin_user_id")
		if adminUserID == nil {
			c.Redirect(http.StatusFound, "/admin/login")
			c.Abort()
			return
		}

		idStr, ok := adminUserID.(string)
		if !ok {
			c.Redirect(http.StatusFound, "/admin/login")
			c.Abort()
			return
		}

		adminID, err := uuid.Parse(idStr)
		if err != nil {
			c.Redirect(http.StatusFound, "/admin/login")
			c.Abort()
			return
		}

		var admin database.AdminUser
		if err := database.GetDB().First(&admin, "id = ? AND status = ?", adminID, "active").Error; err != nil {
			session.Delete("admin_user_id")
			session.Save()
			c.Redirect(http.StatusFound, "/admin/login")
			c.Abort()
			return
		}

		c.Set("admin_user", &admin)
		c.Next()
	}
}

func GetAdminFromContext(c *gin.Context) *database.AdminUser {
	val, exists := c.Get("admin_user")
	if !exists {
		return nil
	}
	admin, ok := val.(*database.AdminUser)
	if !ok {
		return nil
	}
	return admin
}

func SetAdminSession(c *gin.Context, adminID uuid.UUID) error {
	session := sessions.Default(c)
	session.Set("admin_user_id", adminID.String())
	session.Options(sessions.Options{
		Path:     "/admin",
		MaxAge:   86400, // 24 hours
		HttpOnly: true,
		SameSite: http.SameSiteLaxMode,
	})
	return session.Save()
}

func ClearAdminSession(c *gin.Context) error {
	session := sessions.Default(c)
	session.Clear()
	session.Options(sessions.Options{
		Path:   "/admin",
		MaxAge: -1,
	})
	return session.Save()
}
