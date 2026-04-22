package handlers

import (
	"net/http"
	"strconv"

	"github.com/CKnuchel/uno-vision/internal/hub"
	"github.com/CKnuchel/uno-vision/internal/services"
	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		// Allow all origins for Flutter app
		return true
	},
}

type WSHandler struct {
	hub          hub.Hub
	partyService services.PartyService
}

func NewWSHandler(hub hub.Hub, partyService services.PartyService) *WSHandler {
	return &WSHandler{hub: hub, partyService: partyService}
}

func (h *WSHandler) Connect(c *gin.Context) {
	// 1. Parse party ID from URL
	partyID, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid party id"})
		return
	}

	// 2. Get player UUID from query parameter
	playerUUID := c.Query("player_uuid")
	if playerUUID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "player_uuid is required"})
		return
	}

	// 3. Validate party exists and get current status
	partyStatus, err := h.partyService.GetPartyStatus(c.Request.Context(), uint(partyID))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "party not found"})
		return
	}

	// 4. Check if player is in the party
	playerID, err := h.partyService.GetPlayerIDByUUID(c.Request.Context(), uint(partyID), playerUUID)
	if err != nil {
		c.JSON(http.StatusForbidden, gin.H{"error": "player not in party"})
		return
	}

	// Suppress unused variable warning
	_ = partyStatus

	// 5. Upgrade HTTP connection to WebSocket
	conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to upgrade connection"})
		return
	}

	// 6. Create client and register with hub
	client := hub.NewClient(h.hub, conn, uint(partyID), playerID)
	h.hub.Register(client)

	// 7. Start read and write pumps as goroutines
	go client.ReadPump()
	go client.WritePump()
}
