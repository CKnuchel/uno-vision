package handlers

import (
	"net/http"
	"strconv"

	"github.com/CKnuchel/uno-vision/internal/dto"
	"github.com/CKnuchel/uno-vision/internal/errors"
	"github.com/CKnuchel/uno-vision/internal/services"
	"github.com/gin-gonic/gin"
)

type PartyHandler struct {
	service services.PartyService
}

func NewPartyHandler(service services.PartyService) *PartyHandler {
	return &PartyHandler{service: service}
}

// Create handles POST /api/v1/party
func (h *PartyHandler) Create(c *gin.Context) {
	// Bind request body
	var req dto.CreatePartyRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
		return
	}

	// Call service
	resp, err := h.service.CreateParty(c.Request.Context(), &req)
	if err != nil {
		handleError(c, err)
		return
	}

	c.JSON(http.StatusOK, resp)
}

// JoinParty handles POST /api/v1/party/join/:code
func (h *PartyHandler) JoinParty(c *gin.Context) {
	// Parse party code from URL
	partyCode := c.Param("code")

	// Bind request body
	var req dto.JoinPartyRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
		return
	}

	// Call service
	resp, err := h.service.JoinParty(c.Request.Context(), partyCode, &req)
	if err != nil {
		handleError(c, err)
		return
	}

	c.JSON(http.StatusOK, resp)
}

// StartParty handles POST /api/v1/party/:id/start
func (h *PartyHandler) StartParty(c *gin.Context) {
	// Parse party ID from URL
	partyID, err := parsePartyID(c)
	if err != nil {
		return
	}

	// Bind request body
	var req dto.StartPartyRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
		return
	}

	// Call service
	if err := h.service.StartParty(c.Request.Context(), partyID, &req); err != nil {
		handleError(c, err)
		return
	}

	c.JSON(http.StatusOK, gin.H{"success": true})
}

// LeaveParty handles POST /api/v1/party/:id/leave
func (h *PartyHandler) LeaveParty(c *gin.Context) {
	// Parse party ID from URL
	partyID, err := parsePartyID(c)
	if err != nil {
		return
	}

	// Bind request body
	var req dto.LeavePartyRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
		return
	}

	// Call service
	if err := h.service.LeaveParty(c.Request.Context(), partyID, &req); err != nil {
		handleError(c, err)
		return
	}

	c.JSON(http.StatusOK, gin.H{"success": true})
}

// GetStatus handles GET /api/v1/party/:id
func (h *PartyHandler) GetStatus(c *gin.Context) {
	// Parse party ID from URL
	partyID, err := parsePartyID(c)
	if err != nil {
		return
	}

	// Call service
	resp, err := h.service.GetPartyStatus(c.Request.Context(), partyID)
	if err != nil {
		handleError(c, err)
		return
	}

	c.JSON(http.StatusOK, resp)
}

// ReportWinner handles POST /api/v1/party/:id/round/winner
func (h *PartyHandler) ReportWinner(c *gin.Context) {
	// Parse party ID from URL
	partyID, err := parsePartyID(c)
	if err != nil {
		return
	}

	// Bind request body
	var req dto.RoundWinnerRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
		return
	}

	// Call service
	resp, err := h.service.ReportWinner(c.Request.Context(), partyID, &req)
	if err != nil {
		handleError(c, err)
		return
	}

	c.JSON(http.StatusOK, resp)
}

// SubmitScore handles POST /api/v1/party/:id/round/score
func (h *PartyHandler) SubmitScore(c *gin.Context) {
	// Parse party ID from URL
	partyID, err := parsePartyID(c)
	if err != nil {
		return
	}

	// Bind request body
	var req dto.RoundScoreRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
		return
	}

	// Call service
	resp, err := h.service.SubmitScore(c.Request.Context(), partyID, &req)
	if err != nil {
		handleError(c, err)
		return
	}

	c.JSON(http.StatusOK, resp)
}

func (h *PartyHandler) RestartParty(c *gin.Context) {
	// Parse party ID from URL
	partyID, err := parsePartyID(c)
	if err != nil {
		return
	}

	// Bind request body
	var req dto.PartyRestartRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
		return
	}

	// Call service
	resp, err := h.service.RestartParty(c.Request.Context(), partyID, &req)
	if err != nil {
		handleError(c, err)
		return
	}

	c.JSON(http.StatusOK, resp)
}

// GetRoundHistory handles GET /api/v1/party/:id/rounds
func (h *PartyHandler) GetRoundHistory(c *gin.Context) {
	// Parse party ID from URL
	partyID, err := parsePartyID(c)
	if err != nil {
		return
	}

	// Call service
	resp, err := h.service.GetRoundHistory(c.Request.Context(), partyID)
	if err != nil {
		handleError(c, err)
		return
	}

	c.JSON(http.StatusOK, resp)
}

// parsePartyID parses and validates the party ID from the URL parameter
func parsePartyID(c *gin.Context) (uint, error) {
	partyID, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid party id"})
		return 0, err
	}
	return uint(partyID), nil
}

// handleError maps service errors to HTTP status codes
func handleError(c *gin.Context, err error) {
	switch err {
	case errors.ErrPartyNotFound, errors.ErrRoundNotFound, errors.ErrPlayerNotFound:
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
	case errors.ErrPlayerNotInParty, errors.ErrNotHost:
		c.JSON(http.StatusForbidden, gin.H{"error": err.Error()})
	case errors.ErrPartyNotJoinable, errors.ErrPartyAlreadyStarted,
		errors.ErrPartyNotFinished,
		errors.ErrPlayerAlreadyInParty, errors.ErrNotEnoughPlayers,
		errors.ErrGameNotStarted, errors.ErrAlreadySubmitted,
		errors.ErrWinnerCannotSubmit, errors.ErrInvalidScore,
		errors.ErrCannotLeaveDuringGame:
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
	default:
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
	}
}
