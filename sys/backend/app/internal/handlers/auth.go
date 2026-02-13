package handlers

import (
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/serifu/backend/internal/database"
	"github.com/serifu/backend/internal/utils"
	"golang.org/x/crypto/bcrypt"
)

type AuthHandler struct {
	jwtSecret string
	jwtTTL    time.Duration
}

func NewAuthHandler(jwtSecret string, jwtTTLHours int) *AuthHandler {
	return &AuthHandler{
		jwtSecret: jwtSecret,
		jwtTTL:    time.Duration(jwtTTLHours) * time.Hour,
	}
}

type RegisterRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Name     string `json:"name" binding:"required"`
	Password string `json:"password" binding:"required,min=6"`
}

type LoginRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required"`
}

func (h *AuthHandler) Register(c *gin.Context) {
	var req RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid request: "+err.Error())
		return
	}

	req.Email = strings.TrimSpace(strings.ToLower(req.Email))
	req.Name = strings.TrimSpace(req.Name)

	db := database.GetDB()

	var existing database.User
	if err := db.Where("email = ?", req.Email).First(&existing).Error; err == nil {
		utils.ErrorResponse(c, http.StatusConflict, "Email already registered")
		return
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		utils.InternalErrorResponse(c, "Failed to process password")
		return
	}

	user := database.User{
		Email:        req.Email,
		Name:         req.Name,
		PasswordHash: string(hash),
	}

	if err := db.Create(&user).Error; err != nil {
		utils.InternalErrorResponse(c, "Failed to create user")
		return
	}

	token, err := generateToken(user.ID.String(), h.jwtSecret, h.jwtTTL)
	if err != nil {
		utils.InternalErrorResponse(c, "Failed to generate token")
		return
	}

	utils.CreatedResponse(c, gin.H{
		"token": token,
		"user":  user,
	})
}

func (h *AuthHandler) Login(c *gin.Context) {
	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid request: "+err.Error())
		return
	}

	req.Email = strings.TrimSpace(strings.ToLower(req.Email))

	db := database.GetDB()
	var user database.User
	if err := db.Where("email = ? AND status = ?", req.Email, "active").First(&user).Error; err != nil {
		utils.UnauthorizedResponse(c, "Invalid email or password")
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)); err != nil {
		utils.UnauthorizedResponse(c, "Invalid email or password")
		return
	}

	token, err := generateToken(user.ID.String(), h.jwtSecret, h.jwtTTL)
	if err != nil {
		utils.InternalErrorResponse(c, "Failed to generate token")
		return
	}

	utils.SuccessResponse(c, gin.H{
		"token": token,
		"user":  user,
	})
}

func (h *AuthHandler) GetMe(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		utils.UnauthorizedResponse(c, "Not authenticated")
		return
	}

	db := database.GetDB()
	var user database.User
	if err := db.First(&user, "id = ?", userID).Error; err != nil {
		utils.NotFoundResponse(c, "User not found")
		return
	}

	var followerCount, followingCount, answerCount int64
	db.Model(&database.Follow{}).Where("following_id = ?", user.ID).Count(&followerCount)
	db.Model(&database.Follow{}).Where("follower_id = ?", user.ID).Count(&followingCount)
	db.Model(&database.Answer{}).Where("user_id = ? AND status = ?", user.ID, "active").Count(&answerCount)

	utils.SuccessResponse(c, gin.H{
		"id":              user.ID,
		"email":           user.Email,
		"name":            user.Name,
		"avatar":          user.Avatar,
		"bio":             user.Bio,
		"total_likes":     user.TotalLikes,
		"status":          user.Status,
		"created_at":      user.CreatedAt,
		"updated_at":      user.UpdatedAt,
		"follower_count":  followerCount,
		"following_count": followingCount,
		"answer_count":    answerCount,
	})
}

func generateToken(userID string, secret string, ttl time.Duration) (string, error) {
	claims := jwt.MapClaims{
		"sub": userID,
		"iat": time.Now().Unix(),
		"exp": time.Now().Add(ttl).Unix(),
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(secret))
}
