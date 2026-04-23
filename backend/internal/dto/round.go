package dto

import "time"

type RoundScoreDTO struct {
	PlayerName string  `json:"player_name"`
	Points     int     `json:"points"`
	ImageURL   *string `json:"image_url"`
}

type RoundHistoryDTO struct {
	RoundID    uint            `json:"round_id"`
	WinnerName string          `json:"winner_name"`
	CreatedAt  time.Time       `json:"created_at"`
	Scores     []RoundScoreDTO `json:"scores"`
}
