package admin

import (
	"bytes"
	"crypto/rand"
	"encoding/base64"
	"fmt"
	"image/png"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/pquerna/otp/totp"
	"github.com/serifu/backend/internal/admin/templates"
	"github.com/serifu/backend/internal/database"
	"golang.org/x/crypto/bcrypt"
)

// TwoFAVerifyPage renders the 2FA verification form
func TwoFAVerifyPage(c *gin.Context) {
	var buf bytes.Buffer
	templates.TwoFAVerify("", "").Render(c.Request.Context(), &buf)
	c.Data(http.StatusOK, "text/html; charset=utf-8", buf.Bytes())
}

// TwoFAVerifyHandler validates a TOTP code or recovery code
func TwoFAVerifyHandler(c *gin.Context) {
	admin := GetAdminFromContext(c)
	if admin == nil {
		c.Redirect(http.StatusFound, "/admin/login")
		return
	}

	code := strings.TrimSpace(c.PostForm("code"))
	if code == "" {
		var buf bytes.Buffer
		templates.TwoFAVerify("認証コードを入力してください", "").Render(c.Request.Context(), &buf)
		c.Data(http.StatusOK, "text/html; charset=utf-8", buf.Bytes())
		return
	}

	// Try TOTP code first
	if totp.Validate(code, admin.TwoFASecret) {
		if err := SetTwoFAVerified(c); err != nil {
			var buf bytes.Buffer
			templates.TwoFAVerify("認証に失敗しました", "").Render(c.Request.Context(), &buf)
			c.Data(http.StatusOK, "text/html; charset=utf-8", buf.Bytes())
			return
		}
		c.Redirect(http.StatusFound, "/admin/")
		return
	}

	// Try recovery code
	if tryRecoveryCode(admin.ID, code) {
		if err := SetTwoFAVerified(c); err != nil {
			var buf bytes.Buffer
			templates.TwoFAVerify("認証に失敗しました", "").Render(c.Request.Context(), &buf)
			c.Data(http.StatusOK, "text/html; charset=utf-8", buf.Bytes())
			return
		}

		database.GetDB().Create(&database.AdminAuditLog{
			AdminUserID: admin.ID,
			Action:      "2fa_recovery_code_used",
			IPAddress:   c.ClientIP(),
		})

		c.Redirect(http.StatusFound, "/admin/")
		return
	}

	var buf bytes.Buffer
	templates.TwoFAVerify("認証コードが正しくありません", "").Render(c.Request.Context(), &buf)
	c.Data(http.StatusOK, "text/html; charset=utf-8", buf.Bytes())
}

// TwoFASettingsPage shows 2FA status and controls
func TwoFASettingsPage(c *gin.Context) {
	admin := GetAdminFromContext(c)
	if admin == nil {
		c.Redirect(http.StatusFound, "/admin/login")
		return
	}

	remainingCodes := 0
	if admin.TwoFAEnabled {
		database.GetDB().Model(&database.AdminRecoveryCode{}).
			Where("admin_user_id = ? AND used_at IS NULL", admin.ID).
			Count(new(int64))
		var count int64
		database.GetDB().Model(&database.AdminRecoveryCode{}).
			Where("admin_user_id = ? AND used_at IS NULL", admin.ID).
			Count(&count)
		remainingCodes = int(count)
	}

	errorMsg := c.Query("error")
	successMsg := c.Query("success")

	var buf bytes.Buffer
	templates.TwoFASettings(admin.Name, admin.TwoFAEnabled, remainingCodes, errorMsg, successMsg).Render(c.Request.Context(), &buf)
	c.Data(http.StatusOK, "text/html; charset=utf-8", buf.Bytes())
}

// TwoFASetupPage generates a TOTP secret and shows QR code
func TwoFASetupPage(c *gin.Context) {
	admin := GetAdminFromContext(c)
	if admin == nil {
		c.Redirect(http.StatusFound, "/admin/login")
		return
	}

	if admin.TwoFAEnabled {
		c.Redirect(http.StatusFound, "/admin/settings/2fa")
		return
	}

	key, err := totp.Generate(totp.GenerateOpts{
		Issuer:      "Serifu Admin",
		AccountName: admin.Email,
	})
	if err != nil {
		var buf bytes.Buffer
		templates.TwoFASetup(admin.Name, "", "", "二段階認証の設定に失敗しました").Render(c.Request.Context(), &buf)
		c.Data(http.StatusOK, "text/html; charset=utf-8", buf.Bytes())
		return
	}

	// Generate QR code image
	img, err := key.Image(200, 200)
	if err != nil {
		var buf bytes.Buffer
		templates.TwoFASetup(admin.Name, "", "", "QRコードの生成に失敗しました").Render(c.Request.Context(), &buf)
		c.Data(http.StatusOK, "text/html; charset=utf-8", buf.Bytes())
		return
	}

	var imgBuf bytes.Buffer
	if err := png.Encode(&imgBuf, img); err != nil {
		var buf bytes.Buffer
		templates.TwoFASetup(admin.Name, "", "", "QRコードの生成に失敗しました").Render(c.Request.Context(), &buf)
		c.Data(http.StatusOK, "text/html; charset=utf-8", buf.Bytes())
		return
	}

	qrBase64 := base64.StdEncoding.EncodeToString(imgBuf.Bytes())

	var buf bytes.Buffer
	templates.TwoFASetup(admin.Name, key.Secret(), qrBase64, "").Render(c.Request.Context(), &buf)
	c.Data(http.StatusOK, "text/html; charset=utf-8", buf.Bytes())
}

// TwoFAConfirmHandler verifies the TOTP code, enables 2FA, and generates recovery codes
func TwoFAConfirmHandler(c *gin.Context) {
	admin := GetAdminFromContext(c)
	if admin == nil {
		c.Redirect(http.StatusFound, "/admin/login")
		return
	}

	secret := c.PostForm("secret")
	code := strings.TrimSpace(c.PostForm("code"))

	if secret == "" || code == "" {
		c.Redirect(http.StatusFound, "/admin/settings/2fa/setup")
		return
	}

	// Validate TOTP code against the provided secret
	if !totp.Validate(code, secret) {
		// Re-generate QR code for the same secret
		key, err := totp.Generate(totp.GenerateOpts{
			Issuer:      "Serifu Admin",
			AccountName: admin.Email,
			Secret:      []byte(secret),
		})
		qrBase64 := ""
		if err == nil {
			if img, err := key.Image(200, 200); err == nil {
				var imgBuf bytes.Buffer
				if err := png.Encode(&imgBuf, img); err == nil {
					qrBase64 = base64.StdEncoding.EncodeToString(imgBuf.Bytes())
				}
			}
		}

		var buf bytes.Buffer
		templates.TwoFASetup(admin.Name, secret, qrBase64, "認証コードが正しくありません。もう一度お試しください。").Render(c.Request.Context(), &buf)
		c.Data(http.StatusOK, "text/html; charset=utf-8", buf.Bytes())
		return
	}

	db := database.GetDB()

	// Enable 2FA
	db.Model(admin).Updates(map[string]interface{}{
		"two_fa_secret":  secret,
		"two_fa_enabled": true,
	})

	// Generate recovery codes
	codes := generateRecoveryCodes(8)
	for _, code := range codes {
		hash, _ := bcrypt.GenerateFromPassword([]byte(code), bcrypt.DefaultCost)
		db.Create(&database.AdminRecoveryCode{
			AdminUserID: admin.ID,
			CodeHash:    string(hash),
		})
	}

	db.Create(&database.AdminAuditLog{
		AdminUserID: admin.ID,
		Action:      "2fa_enabled",
		IPAddress:   c.ClientIP(),
	})

	var buf bytes.Buffer
	templates.TwoFARecoveryCodes(admin.Name, codes).Render(c.Request.Context(), &buf)
	c.Data(http.StatusOK, "text/html; charset=utf-8", buf.Bytes())
}

// TwoFADisableHandler disables 2FA after password verification
func TwoFADisableHandler(c *gin.Context) {
	admin := GetAdminFromContext(c)
	if admin == nil {
		c.Redirect(http.StatusFound, "/admin/login")
		return
	}

	password := c.PostForm("password")
	if err := bcrypt.CompareHashAndPassword([]byte(admin.PasswordHash), []byte(password)); err != nil {
		c.Redirect(http.StatusFound, "/admin/settings/2fa?error=パスワードが正しくありません")
		return
	}

	db := database.GetDB()

	// Disable 2FA
	db.Model(admin).Updates(map[string]interface{}{
		"two_fa_secret":  "",
		"two_fa_enabled": false,
	})

	// Invalidate all recovery codes
	db.Where("admin_user_id = ?", admin.ID).Delete(&database.AdminRecoveryCode{})

	db.Create(&database.AdminAuditLog{
		AdminUserID: admin.ID,
		Action:      "2fa_disabled",
		IPAddress:   c.ClientIP(),
	})

	c.Redirect(http.StatusFound, "/admin/settings/2fa?success=二段階認証を無効にしました")
}

// TwoFARegenerateCodesHandler regenerates recovery codes after password verification
func TwoFARegenerateCodesHandler(c *gin.Context) {
	admin := GetAdminFromContext(c)
	if admin == nil {
		c.Redirect(http.StatusFound, "/admin/login")
		return
	}

	password := c.PostForm("password")
	if err := bcrypt.CompareHashAndPassword([]byte(admin.PasswordHash), []byte(password)); err != nil {
		c.Redirect(http.StatusFound, "/admin/settings/2fa?error=パスワードが正しくありません")
		return
	}

	db := database.GetDB()

	// Invalidate old codes
	db.Where("admin_user_id = ?", admin.ID).Delete(&database.AdminRecoveryCode{})

	// Generate new codes
	codes := generateRecoveryCodes(8)
	for _, code := range codes {
		hash, _ := bcrypt.GenerateFromPassword([]byte(code), bcrypt.DefaultCost)
		db.Create(&database.AdminRecoveryCode{
			AdminUserID: admin.ID,
			CodeHash:    string(hash),
		})
	}

	db.Create(&database.AdminAuditLog{
		AdminUserID: admin.ID,
		Action:      "2fa_recovery_codes_regenerated",
		IPAddress:   c.ClientIP(),
	})

	var buf bytes.Buffer
	templates.TwoFARecoveryCodes(admin.Name, codes).Render(c.Request.Context(), &buf)
	c.Data(http.StatusOK, "text/html; charset=utf-8", buf.Bytes())
}

// generateRecoveryCodes generates formatted recovery codes like "A3K9-M2P7"
func generateRecoveryCodes(count int) []string {
	const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // no I, O, 0, 1 to avoid confusion
	codes := make([]string, count)

	for i := 0; i < count; i++ {
		b := make([]byte, 8)
		if _, err := rand.Read(b); err != nil {
			panic(fmt.Sprintf("failed to generate random bytes: %v", err))
		}
		code := make([]byte, 8)
		for j := 0; j < 8; j++ {
			code[j] = chars[int(b[j])%len(chars)]
		}
		codes[i] = string(code[:4]) + "-" + string(code[4:])
	}

	return codes
}

// tryRecoveryCode checks a recovery code against unused codes and marks it used
func tryRecoveryCode(adminID interface{}, code string) bool {
	code = strings.ToUpper(strings.TrimSpace(code))

	db := database.GetDB()
	var recoveryCodes []database.AdminRecoveryCode
	db.Where("admin_user_id = ? AND used_at IS NULL", adminID).Find(&recoveryCodes)

	for _, rc := range recoveryCodes {
		if err := bcrypt.CompareHashAndPassword([]byte(rc.CodeHash), []byte(code)); err == nil {
			now := time.Now()
			db.Model(&rc).Update("used_at", &now)
			return true
		}
	}

	return false
}
