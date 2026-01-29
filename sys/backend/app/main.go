package main

import (
	"fmt"
	"log"

	"github.com/serifu/backend/internal/config"
	"github.com/serifu/backend/internal/database"
	"github.com/serifu/backend/internal/router"
)

func main() {
	cfg := config.Load()

	if err := database.InitDB(&cfg.Database); err != nil {
		log.Fatalf("Failed to initialize database: %v", err)
	}

	if err := database.RunMigrations(); err != nil {
		log.Fatalf("Failed to run migrations: %v", err)
	}

	r := router.SetupRouter(cfg)

	addr := fmt.Sprintf(":%s", cfg.Server.Port)
	log.Printf("Starting Serifu backend server on %s", addr)

	if err := r.Run(addr); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
