package main

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"gorm.io/gorm"
)

func startServer(srv *http.Server) {
	if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		fmt.Println("Server failed:", err)
	}
}

func waitForShutdown(srv *http.Server, db *gorm.DB) {
	quit := make(chan os.Signal, 1)

	// SIGINT (Ctrl+C) || SIGTERM signals from docker/kubernetes
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)

	sig := <-quit
	fmt.Println("signal", sig.String(), "- Received signal - shutting down gracefully")

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		fmt.Println("Error shutting down server:", err)
	}

	closeDatabase(db)

	fmt.Println("Server stopped")
}

func closeDatabase(db *gorm.DB) {
	sqlDB, err := db.DB()
	if err != nil {
		fmt.Println("Error getting database instance:", err)
		return
	}

	if err := sqlDB.Close(); err != nil {
		fmt.Println("Error closing database:", err)
		return
	}

	fmt.Println("Database connection closed")
}