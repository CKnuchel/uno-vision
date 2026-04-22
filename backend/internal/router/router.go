package router

import (
	"net/http"

	"github.com/CKnuchel/uno-vision/internal/handlers"
	"github.com/gin-gonic/gin"
)

func Setup(partyHandler *handlers.PartyHandler, wsHandler *handlers.WSHandler) *gin.Engine {
	router := gin.Default()

	// Health check
	router.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "healthy"})
	})

	v1 := router.Group("/api/v1")
	{
		// Party routes
		v1.POST("/party", partyHandler.Create)
		v1.POST("/party/join/:code", partyHandler.JoinParty)
		v1.GET("/party/:id", partyHandler.GetStatus)
		v1.POST("/party/:id/start", partyHandler.StartParty)
		v1.POST("/party/:id/restart", partyHandler.RestartParty)

		// Round routes
		v1.POST("/party/:id/round/winner", partyHandler.ReportWinner)
		v1.POST("/party/:id/round/score", partyHandler.SubmitScore)

		// WebSocket
		v1.GET("/party/:id/ws", wsHandler.Connect)
	}

	return router
}
