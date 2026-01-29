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
