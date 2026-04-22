package dto

import "github.com/CKnuchel/uno-vision/internal/models"

// Requests
type CreatePartyRequest struct {
	PlayerUUID  string           `json:"player_uuid" binding:"required"`
	PlayerName  string           `json:"player_name" binding:"required"`
	Mode        models.PartyMode `json:"mode" binding:"required"`
	TargetScore int              `json:"target_score" binding:"min=1"`
}

type JoinPartyRequest struct {
	PlayerUUID string `json:"player_uuid" binding:"required"`
	PlayerName string `json:"player_name" binding:"required"`
}

type StartPartyRequest struct {
	PlayerUUID string `json:"player_uuid" binding:"required"`
}

type RoundWinnerRequest struct {
	PlayerUUID string `json:"player_uuid" binding:"required"`
}

type RoundScoreRequest struct {
	PlayerUUID  string `json:"player_uuid" binding:"required"`
	RoundID     uint   `json:"round_id" binding:"required"`
	Points      int    `json:"points" binding:"min=0"`
	ImageBase64 string `json:"image_base64,omitempty"`
}

type PartyRestartRequest struct {
	PlayerUUID string `json:"player_uuid" binding:"required"`
}

// Responses
type CreatePartyResponse struct {
	PartyID   uint   `json:"party_id"`
	PartyCode string `json:"party_code"`
}

type JoinPartyResponse struct {
	PartyID     uint             `json:"party_id"`
	PartyCode   string           `json:"party_code"`
	Mode        models.PartyMode `json:"mode"`
	TargetScore int              `json:"target_score"`
	Players     []PlayerDTO      `json:"players"`
}

type RoundWinnerResponse struct {
	RoundID uint `json:"round_id"`
}

type RoundScoreResponse struct {
	TotalScore int  `json:"total_score"`
	GameOver   bool `json:"game_over"`
}

type PartyStatusResponse struct {
	PartyID     uint               `json:"party_id"`
	PartyCode   string             `json:"party_code"`
	Mode        models.PartyMode   `json:"mode"`
	Status      models.PartyStatus `json:"status"`
	TargetScore int                `json:"target_score"`
	Players     []PlayerDTO        `json:"players"`
}

type PartyRestartResponse struct {
	PartyID   uint   `json:"party_id"`
	PartyCode string `json:"party_code"`
}

// Shared
type PlayerDTO struct {
	Name       string `json:"name"`
	TotalScore int    `json:"total_score"`
}

// Functions
func NewPlayerDTO(pp models.PartyPlayer) PlayerDTO {
	return PlayerDTO{
		Name:       pp.Player.Name,
		TotalScore: pp.TotalScore,
	}
}

func NewPlayerDTOs(pps []models.PartyPlayer) []PlayerDTO {
	dtos := make([]PlayerDTO, len(pps))
	for i, pp := range pps {
		dtos[i] = NewPlayerDTO(pp)
	}
	return dtos
}
