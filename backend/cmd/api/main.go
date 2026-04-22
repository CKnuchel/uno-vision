package main

import (
	"fmt"
	"net/http"

	"github.com/CKnuchel/uno-vision/internal/config"
	"github.com/CKnuchel/uno-vision/internal/database"
	"github.com/CKnuchel/uno-vision/internal/handlers"
	"github.com/CKnuchel/uno-vision/internal/hub"
	"github.com/CKnuchel/uno-vision/internal/repository"
	"github.com/CKnuchel/uno-vision/internal/router"
	"github.com/CKnuchel/uno-vision/internal/services"
)

func main() {
	// Load configuration
	cfg := config.Load()

	// Connect to the database
	db, err := database.Connect(cfg)
	if err != nil {
		panic(err)
	}

	// WebSocket Hub
	wsHub := hub.NewHub()
	go wsHub.Run() // Start the hub in a separate goroutine

	// Repositories
	partyRepository := repository.NewPartyRepository(db)
	playerRepository := repository.NewPlayerRepository(db)
	roundRepository := repository.NewRoundRepository(db)
	partyPlayerRepository := repository.NewPartyPlayerRepository(db)
	roundScoreRepository := repository.NewRoundScoreRepository(db)

	// Services
	partyService := services.NewPartyService(
		partyRepository,
		playerRepository,
		partyPlayerRepository,
		roundRepository,
		roundScoreRepository,
		wsHub,
	)

	// Handlers
	partyHandler := handlers.NewPartyHandler(partyService)
	wsHandler := handlers.NewWSHandler(wsHub, partyService)

	// Router
	r := router.Setup(partyHandler, wsHandler)

	// Server mit Graceful Shutdown
	srv := &http.Server{
		Addr:    ":" + cfg.Port,
		Handler: r,
	}

	fmt.Println("Server starting on port", cfg.Port)
	go startServer(srv)
	waitForShutdown(srv, db)
}
