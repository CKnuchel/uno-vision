package hub

const (
	EventPlayerJoined    = "player_joined"
	EventPlayerLeft      = "player_left"
	EventPartyCancelled  = "party_cancelled"
	EventGameStarted     = "game_started"
	EventRoundWinner     = "round_winner"
	EventScoreUpdate     = "score_update"
	EventGameOver        = "game_over"
	EventPartyRestarted  = "party_restarted"
)

// Payloads
type PlayerJoinedPayload struct {
	PlayerName string `json:"player_name"`
}

type RoundWinnerPayload struct {
	PlayerName string `json:"player_name"`
	RoundID    uint   `json:"round_id"`
}

type ScoreUpdatePayload struct {
	PlayerName string       `json:"player_name"`
	Points     int          `json:"points"`
	TotalScore int          `json:"total_score"`
	Scores     []ScoreEntry `json:"scores"`
}

type ScoreEntry struct {
	PlayerName string `json:"player_name"`
	TotalScore int    `json:"total_score"`
}

type GameOverPayload struct {
	WinnerName string       `json:"winner_name"`
	Scores     []ScoreEntry `json:"scores"`
}

type PartyRestartedPayload struct {
	NewPartyID   uint   `json:"new_party_id"`
	NewPartyCode string `json:"new_party_code"`
}

type PlayerLeftPayload struct {
	PlayerName string `json:"player_name"`
}

type PartyCancelledPayload struct {
	Reason string `json:"reason"`
}
