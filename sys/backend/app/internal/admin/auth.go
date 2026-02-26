package admin

import (
	"bytes"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/serifu/backend/internal/admin/templates"
	"github.com/serifu/backend/internal/database"
	"golang.org/x/crypto/bcrypt"
)

func LoginPage(c *gin.Context) {
	var buf bytes.Buffer
	templates.Login("", "").Render(c.Request.Context(), &buf)
	c.Data(http.StatusOK, "text/html; charset=utf-8", buf.Bytes())
}

func LoginHandler(c *gin.Context) {
	email := c.PostForm("email")
	password := c.PostForm("password")

	if email == "" || password == "" {
		var buf bytes.Buffer
		templates.Login("メールアドレスとパスワードを入力してください", email).Render(c.Request.Context(), &buf)
		c.Data(http.StatusOK, "text/html; charset=utf-8", buf.Bytes())
		return
	}

	db := database.GetDB()
	var admin database.AdminUser
	if err := db.Where("email = ? AND status = ?", email, "active").First(&admin).Error; err != nil {
		var buf bytes.Buffer
		templates.Login("メールアドレスまたはパスワードが正しくありません", email).Render(c.Request.Context(), &buf)
		c.Data(http.StatusOK, "text/html; charset=utf-8", buf.Bytes())
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(admin.PasswordHash), []byte(password)); err != nil {
		var buf bytes.Buffer
		templates.Login("メールアドレスまたはパスワードが正しくありません", email).Render(c.Request.Context(), &buf)
		c.Data(http.StatusOK, "text/html; charset=utf-8", buf.Bytes())
		return
	}

	if err := SetAdminSession(c, admin.ID); err != nil {
		var buf bytes.Buffer
		templates.Login("ログインに失敗しました", email).Render(c.Request.Context(), &buf)
		c.Data(http.StatusOK, "text/html; charset=utf-8", buf.Bytes())
		return
	}

	now := time.Now()
	db.Model(&admin).Update("last_login_at", &now)

	// Audit log
	db.Create(&database.AdminAuditLog{
		AdminUserID: admin.ID,
		Action:      "login",
		IPAddress:   c.ClientIP(),
	})

	// If 2FA enabled, redirect to verify page
	if admin.TwoFAEnabled {
		c.Redirect(http.StatusFound, "/admin/2fa/verify")
		return
	}

	c.Redirect(http.StatusFound, "/admin/")
}

func LogoutHandler(c *gin.Context) {
	admin := GetAdminFromContext(c)
	if admin != nil {
		database.GetDB().Create(&database.AdminAuditLog{
			AdminUserID: admin.ID,
			Action:      "logout",
			IPAddress:   c.ClientIP(),
		})
	}

	ClearAdminSession(c)
	c.Redirect(http.StatusFound, "/admin/login")
}
