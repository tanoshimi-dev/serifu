package middleware

import (
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/serifu/backend/internal/utils"
)

func JWTAuthMiddleware(secret string) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Try Authorization: Bearer <token> header first
		authHeader := c.GetHeader("Authorization")
		if authHeader != "" && strings.HasPrefix(authHeader, "Bearer ") {
			tokenString := strings.TrimPrefix(authHeader, "Bearer ")

			token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
				if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
					return nil, jwt.ErrSignatureInvalid
				}
				return []byte(secret), nil
			})

			if err == nil && token.Valid {
				if claims, ok := token.Claims.(jwt.MapClaims); ok {
					if sub, ok := claims["sub"].(string); ok {
						c.Set("userID", sub)
						c.Next()
						return
					}
				}
			}
		}

		// Fallback: check X-User-ID header
		if userID := c.GetHeader("X-User-ID"); userID != "" {
			c.Set("userID", userID)
			c.Next()
			return
		}

		utils.UnauthorizedResponse(c, "Authentication required")
		c.Abort()
	}
}

func GetUserIDFromContext(c *gin.Context) string {
	if userID, exists := c.Get("userID"); exists {
		return userID.(string)
	}
	return ""
}
