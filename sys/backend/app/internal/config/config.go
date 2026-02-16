package config

import (
	"os"
	"strconv"

	"github.com/joho/godotenv"
)

type Config struct {
	Server     ServerConfig
	Database   DatabaseConfig
	Pagination PaginationConfig
	Admin      AdminConfig
	JWT        JWTConfig
	SocialAuth SocialAuthConfig
}

type SocialAuthConfig struct {
	GoogleClientID string
	AppleClientID  string
	LineChannelID  string
}

type JWTConfig struct {
	Secret   string
	TTLHours int
}

type AdminConfig struct {
	SessionSecret string
	SessionTTL    int // hours
}

type ServerConfig struct {
	Port    string
	GinMode string
}

type DatabaseConfig struct {
	Host     string
	Port     string
	User     string
	Password string
	DBName   string
	SSLMode  string
}

type PaginationConfig struct {
	DefaultPageSize int
	MaxPageSize     int
}

func Load() *Config {
	godotenv.Load()

	return &Config{
		Server: ServerConfig{
			Port:    getEnv("SERVER_PORT", "8080"),
			GinMode: getEnv("GIN_MODE", "debug"),
		},
		Database: DatabaseConfig{
			Host:     getEnv("DB_HOST", "localhost"),
			Port:     getEnv("DB_PORT", "5432"),
			User:     getEnv("DB_USER", "serifu"),
			Password: getEnv("DB_PASSWORD", "serifu_password"),
			DBName:   getEnv("DB_NAME", "serifu_db"),
			SSLMode:  getEnv("DB_SSLMODE", "disable"),
		},
		Pagination: PaginationConfig{
			DefaultPageSize: getEnvInt("DEFAULT_PAGE_SIZE", 20),
			MaxPageSize:     getEnvInt("MAX_PAGE_SIZE", 100),
		},
		Admin: AdminConfig{
			SessionSecret: getEnv("ADMIN_SESSION_SECRET", "serifu-admin-secret-change-me"),
			SessionTTL:    getEnvInt("ADMIN_SESSION_TTL_HOURS", 24),
		},
		JWT: JWTConfig{
			Secret:   getEnv("JWT_SECRET", "serifu-jwt-secret-change-me"),
			TTLHours: getEnvInt("JWT_TTL_HOURS", 72),
		},
		SocialAuth: SocialAuthConfig{
			GoogleClientID: getEnv("GOOGLE_CLIENT_ID", ""),
			AppleClientID:  getEnv("APPLE_CLIENT_ID", ""),
			LineChannelID:  getEnv("LINE_CHANNEL_ID", ""),
		},
	}
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func getEnvInt(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		if intValue, err := strconv.Atoi(value); err == nil {
			return intValue
		}
	}
	return defaultValue
}
