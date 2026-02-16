package database

import (
	"fmt"
	"log"

	"github.com/serifu/backend/internal/config"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

var DB *gorm.DB

func InitDB(cfg *config.DatabaseConfig) error {
	dsn := fmt.Sprintf(
		"host=%s port=%s user=%s password=%s dbname=%s sslmode=%s",
		cfg.Host, cfg.Port, cfg.User, cfg.Password, cfg.DBName, cfg.SSLMode,
	)

	var err error
	DB, err = gorm.Open(postgres.Open(dsn), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Info),
	})
	if err != nil {
		return fmt.Errorf("failed to connect to database: %w", err)
	}

	sqlDB, err := DB.DB()
	if err != nil {
		return fmt.Errorf("failed to get database instance: %w", err)
	}

	sqlDB.SetMaxIdleConns(10)
	sqlDB.SetMaxOpenConns(100)

	log.Println("Database connected successfully")
	return nil
}

func RunMigrations() error {
	err := DB.AutoMigrate(
		&User{},
		&Category{},
		&Quiz{},
		&Answer{},
		&Comment{},
		&Like{},
		&Follow{},
		&AdminUser{},
		&AdminAuditLog{},
		&SocialAccount{},
	)
	if err != nil {
		return fmt.Errorf("failed to run migrations: %w", err)
	}

	// Create unique constraints
	DB.Exec("CREATE UNIQUE INDEX IF NOT EXISTS idx_likes_answer_user ON likes(answer_id, user_id)")
	DB.Exec("CREATE UNIQUE INDEX IF NOT EXISTS idx_follows_follower_following ON follows(follower_id, following_id)")
	DB.Exec("CREATE UNIQUE INDEX IF NOT EXISTS idx_social_accounts_provider_provider_id ON social_accounts(provider, provider_id)")

	log.Println("Database migrations completed")
	return nil
}

func GetDB() *gorm.DB {
	return DB
}
