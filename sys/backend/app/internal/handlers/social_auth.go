package handlers

import (
	"crypto/rsa"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"math/big"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/serifu/backend/internal/config"
	"github.com/serifu/backend/internal/database"
	"github.com/serifu/backend/internal/utils"
)

type SocialAuthHandler struct {
	jwtSecret  string
	jwtTTL     time.Duration
	socialAuth config.SocialAuthConfig
}

func NewSocialAuthHandler(jwtSecret string, jwtTTLHours int, socialAuth config.SocialAuthConfig) *SocialAuthHandler {
	return &SocialAuthHandler{
		jwtSecret:  jwtSecret,
		jwtTTL:     time.Duration(jwtTTLHours) * time.Hour,
		socialAuth: socialAuth,
	}
}

type SocialLoginRequest struct {
	Token string `json:"token" binding:"required"`
	Name  string `json:"name"`
}

// GoogleLogin verifies a Google ID token and finds/creates the user.
func (h *SocialAuthHandler) GoogleLogin(c *gin.Context) {
	var req SocialLoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid request: "+err.Error())
		return
	}

	// Verify the ID token with Google
	resp, err := http.Get("https://oauth2.googleapis.com/tokeninfo?id_token=" + req.Token)
	if err != nil {
		utils.InternalErrorResponse(c, "Failed to verify Google token")
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		utils.UnauthorizedResponse(c, "Invalid Google token")
		return
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		utils.InternalErrorResponse(c, "Failed to read Google response")
		return
	}

	var tokenInfo struct {
		Sub           string `json:"sub"`
		Email         string `json:"email"`
		EmailVerified string `json:"email_verified"`
		Name          string `json:"name"`
		Picture       string `json:"picture"`
		Aud           string `json:"aud"`
	}
	if err := json.Unmarshal(body, &tokenInfo); err != nil {
		utils.InternalErrorResponse(c, "Failed to parse Google token info")
		return
	}

	// Verify audience matches our client ID
	if tokenInfo.Aud != h.socialAuth.GoogleClientID {
		utils.UnauthorizedResponse(c, "Token not intended for this application")
		return
	}

	name := tokenInfo.Name
	if req.Name != "" {
		name = req.Name
	}

	user, err := findOrCreateSocialUser("google", tokenInfo.Sub, tokenInfo.Email, name, tokenInfo.Picture)
	if err != nil {
		utils.InternalErrorResponse(c, "Failed to process social login")
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

// AppleLogin verifies an Apple identity token (JWT) and finds/creates the user.
func (h *SocialAuthHandler) AppleLogin(c *gin.Context) {
	var req SocialLoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid request: "+err.Error())
		return
	}

	// Parse Apple JWT without verification first to get header
	parser := jwt.NewParser(jwt.WithoutClaimsValidation())
	appleToken, _, err := parser.ParseUnverified(req.Token, jwt.MapClaims{})
	if err != nil {
		utils.UnauthorizedResponse(c, "Invalid Apple token format")
		return
	}

	// Fetch Apple's public keys (JWKS)
	jwksResp, err := http.Get("https://appleid.apple.com/auth/keys")
	if err != nil {
		utils.InternalErrorResponse(c, "Failed to fetch Apple keys")
		return
	}
	defer jwksResp.Body.Close()

	jwksBody, err := io.ReadAll(jwksResp.Body)
	if err != nil {
		utils.InternalErrorResponse(c, "Failed to read Apple keys")
		return
	}

	var jwks struct {
		Keys []struct {
			Kty string `json:"kty"`
			Kid string `json:"kid"`
			Use string `json:"use"`
			Alg string `json:"alg"`
			N   string `json:"n"`
			E   string `json:"e"`
		} `json:"keys"`
	}
	if err := json.Unmarshal(jwksBody, &jwks); err != nil {
		utils.InternalErrorResponse(c, "Failed to parse Apple keys")
		return
	}

	// Find the matching key by kid
	kid, _ := appleToken.Header["kid"].(string)
	var publicKey *rsa.PublicKey
	for _, key := range jwks.Keys {
		if key.Kid == kid {
			nBytes, err := base64.RawURLEncoding.DecodeString(key.N)
			if err != nil {
				continue
			}
			eBytes, err := base64.RawURLEncoding.DecodeString(key.E)
			if err != nil {
				continue
			}
			n := new(big.Int).SetBytes(nBytes)
			e := new(big.Int).SetBytes(eBytes)
			publicKey = &rsa.PublicKey{N: n, E: int(e.Int64())}
			break
		}
	}

	if publicKey == nil {
		utils.UnauthorizedResponse(c, "Apple key not found")
		return
	}

	// Now verify the token with the public key
	claims := jwt.MapClaims{}
	_, err = jwt.ParseWithClaims(req.Token, claims, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodRSA); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return publicKey, nil
	})
	if err != nil {
		utils.UnauthorizedResponse(c, "Invalid Apple token")
		return
	}

	// Verify issuer and audience
	iss, _ := claims["iss"].(string)
	aud, _ := claims["aud"].(string)
	if iss != "https://appleid.apple.com" {
		utils.UnauthorizedResponse(c, "Invalid Apple token issuer")
		return
	}
	if aud != h.socialAuth.AppleClientID {
		utils.UnauthorizedResponse(c, "Token not intended for this application")
		return
	}

	sub, _ := claims["sub"].(string)
	email, _ := claims["email"].(string)

	name := req.Name // Apple only sends name on first sign-in

	user, err := findOrCreateSocialUser("apple", sub, email, name, "")
	if err != nil {
		utils.InternalErrorResponse(c, "Failed to process social login")
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

// LineLogin verifies a LINE access token and finds/creates the user.
func (h *SocialAuthHandler) LineLogin(c *gin.Context) {
	var req SocialLoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid request: "+err.Error())
		return
	}

	// Verify the access token by calling LINE's verify endpoint
	verifyResp, err := http.Get("https://api.line.me/oauth2/v2.1/verify?access_token=" + req.Token)
	if err != nil {
		utils.InternalErrorResponse(c, "Failed to verify LINE token")
		return
	}
	defer verifyResp.Body.Close()

	if verifyResp.StatusCode != http.StatusOK {
		utils.UnauthorizedResponse(c, "Invalid LINE token")
		return
	}

	verifyBody, err := io.ReadAll(verifyResp.Body)
	if err != nil {
		utils.InternalErrorResponse(c, "Failed to read LINE verify response")
		return
	}

	var verifyInfo struct {
		ClientID  string `json:"client_id"`
		ExpiresIn int    `json:"expires_in"`
	}
	if err := json.Unmarshal(verifyBody, &verifyInfo); err != nil {
		utils.InternalErrorResponse(c, "Failed to parse LINE verify response")
		return
	}

	// Verify that the token was issued for our channel
	if verifyInfo.ClientID != h.socialAuth.LineChannelID {
		utils.UnauthorizedResponse(c, "Token not intended for this application")
		return
	}

	// Get user profile from LINE
	profileReq, err := http.NewRequest("GET", "https://api.line.me/v2/profile", nil)
	if err != nil {
		utils.InternalErrorResponse(c, "Failed to create LINE profile request")
		return
	}
	profileReq.Header.Set("Authorization", "Bearer "+req.Token)

	client := &http.Client{}
	profileResp, err := client.Do(profileReq)
	if err != nil {
		utils.InternalErrorResponse(c, "Failed to get LINE profile")
		return
	}
	defer profileResp.Body.Close()

	if profileResp.StatusCode != http.StatusOK {
		utils.UnauthorizedResponse(c, "Failed to get LINE profile")
		return
	}

	profileBody, err := io.ReadAll(profileResp.Body)
	if err != nil {
		utils.InternalErrorResponse(c, "Failed to read LINE profile")
		return
	}

	var profile struct {
		UserID        string `json:"userId"`
		DisplayName   string `json:"displayName"`
		PictureURL    string `json:"pictureUrl"`
		StatusMessage string `json:"statusMessage"`
	}
	if err := json.Unmarshal(profileBody, &profile); err != nil {
		utils.InternalErrorResponse(c, "Failed to parse LINE profile")
		return
	}

	name := profile.DisplayName
	if req.Name != "" {
		name = req.Name
	}

	// LINE doesn't provide email in profile API
	user, err := findOrCreateSocialUser("line", profile.UserID, "", name, profile.PictureURL)
	if err != nil {
		utils.InternalErrorResponse(c, "Failed to process social login")
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

// findOrCreateSocialUser looks up an existing social account or creates a new user.
// Account linking: if the provider email matches an existing user, link to that user.
func findOrCreateSocialUser(provider, providerID, email, name, avatar string) (*database.User, error) {
	db := database.GetDB()

	// 1. Check if social account already exists
	var socialAccount database.SocialAccount
	if err := db.Where("provider = ? AND provider_id = ?", provider, providerID).First(&socialAccount).Error; err == nil {
		// Found existing social account — return linked user
		var user database.User
		if err := db.First(&user, "id = ?", socialAccount.UserID).Error; err != nil {
			return nil, fmt.Errorf("failed to find linked user: %w", err)
		}
		return &user, nil
	}

	// 2. If email provided, check if an existing user has this email (account linking)
	email = strings.TrimSpace(strings.ToLower(email))
	var user database.User
	if email != "" {
		if err := db.Where("email = ? AND status = ?", email, "active").First(&user).Error; err == nil {
			// Link this social account to the existing user
			socialAccount = database.SocialAccount{
				UserID:     user.ID,
				Provider:   provider,
				ProviderID: providerID,
				Email:      email,
				Name:       name,
				Avatar:     avatar,
			}
			if err := db.Create(&socialAccount).Error; err != nil {
				return nil, fmt.Errorf("failed to link social account: %w", err)
			}
			return &user, nil
		}
	}

	// 3. Create a new user (no password needed for social login)
	if name == "" {
		name = "User"
	}
	user = database.User{
		Email:  email,
		Name:   name,
		Avatar: avatar,
		Status: "active",
	}
	if err := db.Create(&user).Error; err != nil {
		return nil, fmt.Errorf("failed to create user: %w", err)
	}

	// Create the social account linked to the new user
	socialAccount = database.SocialAccount{
		UserID:     user.ID,
		Provider:   provider,
		ProviderID: providerID,
		Email:      email,
		Name:       name,
		Avatar:     avatar,
	}
	if err := db.Create(&socialAccount).Error; err != nil {
		return nil, fmt.Errorf("failed to create social account: %w", err)
	}

	return &user, nil
}
