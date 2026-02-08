package main

import (
	"bufio"
	"fmt"
	"log"
	"os"
	"strings"

	"github.com/serifu/backend/internal/admin"
	"github.com/serifu/backend/internal/config"
	"github.com/serifu/backend/internal/database"
	"github.com/serifu/backend/internal/router"
	"golang.org/x/crypto/bcrypt"
)

func main() {
	cfg := config.Load()

	if err := database.InitDB(&cfg.Database); err != nil {
		log.Fatalf("Failed to initialize database: %v", err)
	}

	if err := database.RunMigrations(); err != nil {
		log.Fatalf("Failed to run migrations: %v", err)
	}

	// Handle CLI commands
	if len(os.Args) > 1 {
		switch os.Args[1] {
		case "create-admin":
			createAdmin()
			return
		case "seed":
			seedData()
			return
		}
	}

	r := router.SetupRouter(cfg)

	// Serve static files
	r.Static("/static", "./static")

	// Setup admin routes
	admin.SetupRoutes(r, cfg)

	addr := fmt.Sprintf(":%s", cfg.Server.Port)
	log.Printf("Starting Serifu backend server on %s", addr)

	if err := r.Run(addr); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}

func createAdmin() {
	reader := bufio.NewReader(os.Stdin)

	fmt.Print("Email: ")
	email, _ := reader.ReadString('\n')
	email = strings.TrimSpace(email)

	fmt.Print("Name: ")
	name, _ := reader.ReadString('\n')
	name = strings.TrimSpace(name)

	fmt.Print("Password: ")
	password, _ := reader.ReadString('\n')
	password = strings.TrimSpace(password)

	if email == "" || name == "" || password == "" {
		log.Fatal("Email, name, and password are required")
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		log.Fatalf("Failed to hash password: %v", err)
	}

	adminUser := database.AdminUser{
		Email:        email,
		Name:         name,
		PasswordHash: string(hash),
		Role:         "admin",
		Status:       "active",
	}

	if err := database.GetDB().Create(&adminUser).Error; err != nil {
		log.Fatalf("Failed to create admin user: %v", err)
	}

	fmt.Printf("Admin user created successfully: %s (%s)\n", name, email)
}

func seedData() {
	db := database.GetDB()

	// Clear existing data (order matters due to foreign keys)
	fmt.Println("Clearing existing data...")
	db.Exec("DELETE FROM likes")
	db.Exec("DELETE FROM comments")
	db.Exec("DELETE FROM follows")
	db.Exec("DELETE FROM answers")
	db.Exec("DELETE FROM quizzes")
	db.Exec("DELETE FROM categories")
	db.Exec("DELETE FROM users")

	sqlBytes, err := os.ReadFile("seeds/seed_data.sql")
	if err != nil {
		log.Fatalf("Failed to read seed file: %v", err)
	}

	if err := db.Exec(string(sqlBytes)).Error; err != nil {
		log.Fatalf("Failed to execute seed data: %v", err)
	}

	fmt.Println("Seed data inserted successfully")

	// Create default admin user (admin@serifu.com / admin123)
	hash, err := bcrypt.GenerateFromPassword([]byte("admin123"), bcrypt.DefaultCost)
	if err != nil {
		log.Fatalf("Failed to hash password: %v", err)
	}

	adminUser := database.AdminUser{
		Email:        "admin@serifu.com",
		Name:         "Admin",
		PasswordHash: string(hash),
		Role:         "admin",
		Status:       "active",
	}

	var existing database.AdminUser
	if err := db.Where("email = ?", adminUser.Email).First(&existing).Error; err != nil {
		// Not found — create
		if err := db.Create(&adminUser).Error; err != nil {
			log.Fatalf("Failed to create admin user: %v", err)
		}
	} else {
		// Found — update password
		db.Model(&existing).Update("password_hash", adminUser.PasswordHash)
	}

	fmt.Println("Default admin user ready: admin@serifu.com / admin123")
}
