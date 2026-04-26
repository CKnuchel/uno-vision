package services

import (
	"context"
	"encoding/base64"
	"fmt"
	"math/rand"
	"os"
	"path/filepath"

	"github.com/CKnuchel/uno-vision/internal/dto"
	"github.com/CKnuchel/uno-vision/internal/errors"
	"github.com/CKnuchel/uno-vision/internal/hub"
	"github.com/CKnuchel/uno-vision/internal/models"
	"github.com/CKnuchel/uno-vision/internal/repository"
)

type PartyService interface {
	CreateParty(ctx context.Context, req *dto.CreatePartyRequest) (*dto.CreatePartyResponse, error)
	JoinParty(ctx context.Context, code string, req *dto.JoinPartyRequest) (*dto.JoinPartyResponse, error)
	StartParty(ctx context.Context, partyID uint, req *dto.StartPartyRequest) error
	LeaveParty(ctx context.Context, partyID uint, req *dto.LeavePartyRequest) error
	ReportWinner(ctx context.Context, partyID uint, req *dto.RoundWinnerRequest) (*dto.RoundWinnerResponse, error)
	SubmitScore(ctx context.Context, partyID uint, req *dto.RoundScoreRequest) (*dto.RoundScoreResponse, error)
	GetPartyStatus(ctx context.Context, partyID uint) (*dto.PartyStatusResponse, error)
	GetPlayerIDByUUID(ctx context.Context, partyID uint, uuid string) (uint, error)
	RestartParty(ctx context.Context, partyID uint, req *dto.PartyRestartRequest) (*dto.PartyRestartResponse, error)
	GetRoundHistory(ctx context.Context, partyID uint) ([]dto.RoundHistoryDTO, error)
}

type partyService struct {
	partyRepo       repository.PartyRepository
	playerRepo      repository.PlayerRepository
	partyPlayerRepo repository.PartyPlayerRepository
	roundRepo       repository.RoundRepository
	roundScoreRepo  repository.RoundScoreRepository
	hub             hub.Hub
}

func NewPartyService(
	partyRepo repository.PartyRepository,
	playerRepo repository.PlayerRepository,
	partyPlayerRepo repository.PartyPlayerRepository,
	roundRepo repository.RoundRepository,
	roundScoreRepo repository.RoundScoreRepository,
	hub hub.Hub,
) PartyService {
	return &partyService{
		partyRepo:       partyRepo,
		playerRepo:      playerRepo,
		partyPlayerRepo: partyPlayerRepo,
		roundRepo:       roundRepo,
		roundScoreRepo:  roundScoreRepo,
		hub:             hub,
	}
}

// CreateParty implements [PartyService].
func (s *partyService) CreateParty(ctx context.Context, req *dto.CreatePartyRequest) (*dto.CreatePartyResponse, error) {
	// Find or create player
	player, err := s.playerRepo.FindOrCreate(ctx, req.PlayerUUID, req.PlayerName)
	if err != nil {
		return nil, err
	}

	// Create party with unique code
	party, err := s.createPartyWithPlayers(ctx, req.Mode, req.TargetScore, []uint{player.ID})
	if err != nil {
		return nil, err
	}

	return &dto.CreatePartyResponse{
		PartyID:   party.ID,
		PartyCode: party.Code,
	}, nil
}

// JoinParty implements [PartyService].
func (s *partyService) JoinParty(ctx context.Context, code string, req *dto.JoinPartyRequest) (*dto.JoinPartyResponse, error) {
	// Find party
	party, err := s.partyRepo.FindByCode(ctx, code)
	if err != nil {
		return nil, err
	}

	if party.Status != models.PartyStatusWaiting {
		return nil, errors.ErrPartyNotJoinable
	}

	// Find or create player
	player, err := s.playerRepo.FindOrCreate(ctx, req.PlayerUUID, req.PlayerName)
	if err != nil {
		return nil, err
	}

	// Load existing players before adding new one
	existingPlayers, err := s.partyPlayerRepo.FindByPartyID(ctx, party.ID)
	if err != nil {
		return nil, err
	}

	// Check if player is already in party
	existingPP, err := s.partyPlayerRepo.FindByPartyAndPlayer(ctx, party.ID, player.ID)
	if err != nil {
		return nil, err
	}
	if existingPP != nil {
		return nil, errors.ErrPlayerAlreadyInParty
	}

	// Add player to party
	if err := s.partyPlayerRepo.Create(ctx, &models.PartyPlayer{
		PartyID:  party.ID,
		PlayerID: player.ID,
	}); err != nil {
		return nil, err
	}

	// Broadcast new player to party
	s.hub.Broadcast(party.ID, hub.EventPlayerJoined, hub.PlayerJoinedPayload{
		PlayerName: player.Name,
	})

	// Build player list including new player
	playerDTOs := dto.NewPlayerDTOs(existingPlayers)
	playerDTOs = append(playerDTOs, dto.NewPlayerDTO(models.PartyPlayer{
		Player:     *player,
		TotalScore: 0,
	}))

	return &dto.JoinPartyResponse{
		PartyID:     party.ID,
		PartyCode:   party.Code,
		Mode:        party.Mode,
		TargetScore: party.TargetScore,
		Players:     playerDTOs,
	}, nil
}

// StartParty implements [PartyService].
func (s *partyService) StartParty(ctx context.Context, partyID uint, req *dto.StartPartyRequest) error {
	// Find party
	party, err := s.partyRepo.FindByID(ctx, partyID)
	if err != nil {
		return errors.ErrPartyNotFound
	}

	if party.Status != models.PartyStatusWaiting {
		return errors.ErrPartyAlreadyStarted
	}

	// Validate player is host
	if err := s.validateHost(ctx, partyID, req.PlayerUUID); err != nil {
		return err
	}

	// Check minimum players
	players, err := s.partyPlayerRepo.FindByPartyID(ctx, partyID)
	if err != nil {
		return err
	}
	if len(players) < 2 {
		return errors.ErrNotEnoughPlayers
	}

	// Update status and broadcast
	if err := s.partyRepo.UpdateStatus(ctx, partyID, models.PartyStatusPlaying); err != nil {
		return err
	}

	s.hub.Broadcast(partyID, hub.EventGameStarted, struct{}{})

	return nil
}

// LeaveParty implements [PartyService].
func (s *partyService) LeaveParty(ctx context.Context, partyID uint, req *dto.LeavePartyRequest) error {
	// Find party
	party, err := s.partyRepo.FindByID(ctx, partyID)
	if err != nil {
		return errors.ErrPartyNotFound
	}

	// Only allow leaving during waiting status (lobby)
	if party.Status != models.PartyStatusWaiting {
		return errors.ErrCannotLeaveDuringGame
	}

	// Validate player is in party
	player, err := s.validatePlayerInParty(ctx, partyID, req.PlayerUUID)
	if err != nil {
		return err
	}

	// Check if player is host
	host, err := s.partyPlayerRepo.GetHostByPartyID(ctx, partyID)
	if err != nil {
		return err
	}

	if player.ID == host.ID {
		// Host is leaving → cancel the party for everyone
		if err := s.partyRepo.UpdateStatus(ctx, partyID, models.PartyStatusFinished); err != nil {
			return err
		}
		s.hub.Broadcast(partyID, hub.EventPartyCancelled, hub.PartyCancelledPayload{
			Reason: "Host hat die Party verlassen",
		})
	} else {
		// Non-host leaving → just remove them
		if err := s.partyPlayerRepo.Delete(ctx, partyID, player.ID); err != nil {
			return err
		}
		s.hub.Broadcast(partyID, hub.EventPlayerLeft, hub.PlayerLeftPayload{
			PlayerName: player.Name,
		})
	}

	return nil
}

// ReportWinner implements [PartyService].
func (s *partyService) ReportWinner(ctx context.Context, partyID uint, req *dto.RoundWinnerRequest) (*dto.RoundWinnerResponse, error) {
	// Find party
	party, err := s.partyRepo.FindByID(ctx, partyID)
	if err != nil {
		return nil, errors.ErrPartyNotFound
	}

	if party.Status != models.PartyStatusPlaying {
		return nil, errors.ErrGameNotStarted
	}

	// Validate player is in party
	player, err := s.validatePlayerInParty(ctx, partyID, req.PlayerUUID)
	if err != nil {
		return nil, err
	}

	// Create new round
	round := &models.Round{
		PartyID:  partyID,
		WinnerID: &player.ID,
	}
	if err := s.roundRepo.Create(ctx, round); err != nil {
		return nil, err
	}

	s.hub.Broadcast(partyID, hub.EventRoundWinner, hub.RoundWinnerPayload{
		PlayerName: player.Name,
		PlayerUUID: player.UUID,
		RoundID:    round.ID,
	})

	return &dto.RoundWinnerResponse{RoundID: round.ID}, nil
}

// SubmitScore implements [PartyService].
func (s *partyService) SubmitScore(ctx context.Context, partyID uint, req *dto.RoundScoreRequest) (*dto.RoundScoreResponse, error) {
	// Find party and round
	party, err := s.partyRepo.FindByID(ctx, partyID)
	if err != nil {
		return nil, errors.ErrPartyNotFound
	}

	round, err := s.roundRepo.FindByID(ctx, req.RoundID)
	if err != nil {
		return nil, errors.ErrRoundNotFound
	}

	// Validate player
	player, err := s.validatePlayerInParty(ctx, partyID, req.PlayerUUID)
	if err != nil {
		return nil, err
	}

	// Validations
	if party.Status != models.PartyStatusPlaying {
		return nil, errors.ErrGameNotStarted
	}
	if req.Points < 0 {
		return nil, errors.ErrInvalidScore
	}
	if s.roundScoreRepo.HasPlayerSubmitted(ctx, round.ID, player.ID) {
		return nil, errors.ErrAlreadySubmitted
	}
	if round.WinnerID != nil && *round.WinnerID == player.ID {
		return nil, errors.ErrWinnerCannotSubmit
	}

	// Save image if provided
	imagePath, err := s.saveImage(req.ImageBase64, partyID, round.ID, req.PlayerUUID)
	if err != nil {
		return nil, err
	}

	// Create round score entry
	if err := s.roundScoreRepo.Create(ctx, &models.RoundScore{
		RoundID:   round.ID,
		PlayerID:  player.ID,
		Points:    req.Points,
		ImagePath: imagePath,
	}); err != nil {
		return nil, err
	}

	// Determine target player based on game mode
	targetPlayerID := player.ID
	if party.Mode == models.PartyModeClassic {
		targetPlayerID = *round.WinnerID
	}

	// Update score in DB
	if err := s.partyPlayerRepo.UpdateScore(ctx, partyID, targetPlayerID, req.Points); err != nil {
		return nil, err
	}

	// Load all players after update
	allPlayers, err := s.partyPlayerRepo.FindByPartyID(ctx, partyID)
	if err != nil {
		return nil, err
	}

	// Check if all players (except winner) submitted
	submissionCount, err := s.roundScoreRepo.CountByRoundID(ctx, round.ID)
	if err != nil {
		return nil, err
	}
	allSubmitted := submissionCount >= int64(len(allPlayers)-1)

	// Build scores list
	var updatedScore int
	scores := make([]hub.ScoreEntry, len(allPlayers))
	for i, pp := range allPlayers {
		scores[i] = hub.ScoreEntry{
			PlayerName: pp.Player.Name,
			TotalScore: pp.TotalScore,
		}
		if pp.PlayerID == targetPlayerID {
			updatedScore = pp.TotalScore
		}
	}

	// Check game over - only when all submitted
	gameOver := false
	if allSubmitted {
		for _, pp := range allPlayers {
			if pp.TotalScore >= party.TargetScore {
				gameOver = true
				break
			}
		}
	}

	if gameOver {
		if err := s.partyRepo.UpdateStatus(ctx, partyID, models.PartyStatusFinished); err != nil {
			return nil, err
		}

		// Find winner based on game mode
		winner := allPlayers[0]
		for _, pp := range allPlayers[1:] {
			if party.Mode == models.PartyModeGolf && pp.TotalScore < winner.TotalScore {
				winner = pp
			} else if party.Mode == models.PartyModeClassic && pp.TotalScore > winner.TotalScore {
				winner = pp
			}
		}

		s.hub.Broadcast(partyID, hub.EventGameOver, hub.GameOverPayload{
			WinnerName: winner.Player.Name,
			Scores:     scores,
		})
	} else {
		s.hub.Broadcast(partyID, hub.EventScoreUpdate, hub.ScoreUpdatePayload{
			PlayerName:   player.Name,
			Points:       req.Points,
			TotalScore:   updatedScore,
			Scores:       scores,
			AllSubmitted: allSubmitted,
		})
	}

	return &dto.RoundScoreResponse{
		TotalScore: updatedScore,
		GameOver:   gameOver,
	}, nil
}

// GetPartyStatus implements [PartyService].
func (s *partyService) GetPartyStatus(ctx context.Context, partyID uint) (*dto.PartyStatusResponse, error) {
	party, err := s.partyRepo.FindByID(ctx, partyID)
	if err != nil {
		return nil, errors.ErrPartyNotFound
	}

	allPlayers, err := s.partyPlayerRepo.FindByPartyID(ctx, partyID)
	if err != nil {
		return nil, err
	}

	return &dto.PartyStatusResponse{
		PartyID:     party.ID,
		PartyCode:   party.Code,
		Mode:        party.Mode,
		Status:      party.Status,
		TargetScore: party.TargetScore,
		Players:     dto.NewPlayerDTOs(allPlayers),
	}, nil
}

// GetPlayerIDByUUID implements [PartyService].
func (s *partyService) GetPlayerIDByUUID(ctx context.Context, partyID uint, uuid string) (uint, error) {
	player, err := s.validatePlayerInParty(ctx, partyID, uuid)
	if err != nil {
		return 0, err
	}
	return player.ID, nil
}

// RestartParty implements [PartyService].
func (s *partyService) RestartParty(ctx context.Context, partyID uint, req *dto.PartyRestartRequest) (*dto.PartyRestartResponse, error) {
	// Find party
	party, err := s.partyRepo.FindByID(ctx, partyID)
	if err != nil {
		return nil, errors.ErrPartyNotFound
	}

	if party.Status != models.PartyStatusFinished {
		return nil, errors.ErrPartyNotFinished
	}

	// Validate player is host
	if err := s.validateHost(ctx, partyID, req.PlayerUUID); err != nil {
		return nil, err
	}

	// Get current player IDs
	existingPlayers, err := s.partyPlayerRepo.FindByPartyID(ctx, partyID)
	if err != nil {
		return nil, err
	}

	playerIDs := make([]uint, len(existingPlayers))
	for i, pp := range existingPlayers {
		playerIDs[i] = pp.PlayerID
	}

	// Create new party with same settings and players
	newParty, err := s.createPartyWithPlayers(ctx, party.Mode, party.TargetScore, playerIDs)
	if err != nil {
		return nil, err
	}

	// Broadcast to old party so all clients navigate to new party
	s.hub.Broadcast(partyID, hub.EventPartyRestarted, hub.PartyRestartedPayload{
		NewPartyID:   newParty.ID,
		NewPartyCode: newParty.Code,
	})

	return &dto.PartyRestartResponse{
		PartyID:   newParty.ID,
		PartyCode: newParty.Code,
	}, nil
}

// ─────────────────────────────────────────────
// Private Helpers
// ─────────────────────────────────────────────

// validatePlayerInParty finds a player by UUID and checks if they are in the party
func (s *partyService) validatePlayerInParty(ctx context.Context, partyID uint, uuid string) (*models.Player, error) {
	player, err := s.playerRepo.FindByUUID(ctx, uuid)
	if err != nil {
		return nil, errors.ErrPlayerNotFound
	}
	if !s.partyPlayerRepo.IsPlayerInParty(ctx, partyID, player.ID) {
		return nil, errors.ErrPlayerNotInParty
	}
	return player, nil
}

// validateHost checks if the player with the given UUID is the host of the party
func (s *partyService) validateHost(ctx context.Context, partyID uint, uuid string) error {
	player, err := s.validatePlayerInParty(ctx, partyID, uuid)
	if err != nil {
		return err
	}
	host, err := s.partyPlayerRepo.GetHostByPartyID(ctx, partyID)
	if err != nil {
		return err
	}
	if player.ID != host.ID {
		return errors.ErrNotHost
	}
	return nil
}

// createPartyWithPlayers creates a new party with a unique code and adds the given player IDs
func (s *partyService) createPartyWithPlayers(ctx context.Context, mode models.PartyMode, targetScore int, playerIDs []uint) (*models.Party, error) {
	// Generate unique code
	var code string
	for {
		code = generateCode()
		exists, err := s.partyRepo.ExistsByCode(ctx, code)
		if err != nil {
			return nil, err
		}
		if !exists {
			break
		}
	}

	// Create party
	party := &models.Party{
		Code:        code,
		Mode:        mode,
		TargetScore: targetScore,
		Status:      models.PartyStatusWaiting,
	}
	if err := s.partyRepo.Create(ctx, party); err != nil {
		return nil, err
	}

	// Add players
	for _, playerID := range playerIDs {
		if err := s.partyPlayerRepo.Create(ctx, &models.PartyPlayer{
			PartyID:  party.ID,
			PlayerID: playerID,
		}); err != nil {
			return nil, err
		}
	}

	return party, nil
}

// GetRoundHistory implements [PartyService].
func (s *partyService) GetRoundHistory(ctx context.Context, partyID uint) ([]dto.RoundHistoryDTO, error) {
	// Find party
	_, err := s.partyRepo.FindByID(ctx, partyID)
	if err != nil {
		return nil, errors.ErrPartyNotFound
	}

	// Load all rounds with scores and players
	rounds, err := s.roundRepo.FindByPartyID(ctx, partyID)
	if err != nil {
		return nil, err
	}

	// Build response
	history := make([]dto.RoundHistoryDTO, len(rounds))
	for i, round := range rounds {
		// Build scores list
		scores := make([]dto.RoundScoreDTO, len(round.Scores))
		for j, score := range round.Scores {
			var imageURL *string
			if score.ImagePath != nil {
				url := fmt.Sprintf("/uploads/%d/%d/%s.jpg",
					partyID, round.ID, score.Player.UUID)
				imageURL = &url
			}
			scores[j] = dto.RoundScoreDTO{
				PlayerName: score.Player.Name,
				Points:     score.Points,
				ImageURL:   imageURL,
			}
		}

		// Winner name
		winnerName := ""
		if round.Winner != nil {
			winnerName = round.Winner.Name
		}

		history[i] = dto.RoundHistoryDTO{
			RoundID:    round.ID,
			WinnerName: winnerName,
			CreatedAt:  round.CreatedAt,
			Scores:     scores,
		}
	}

	return history, nil
}

// saveImage decodes a base64 image and saves it to disk, returns the file path
func (s *partyService) saveImage(base64Data string, partyID, roundID uint, playerUUID string) (*string, error) {
	if base64Data == "" {
		return nil, nil
	}

	path := fmt.Sprintf("uploads/%d/%d/%s.jpg", partyID, roundID, playerUUID)
	if err := os.MkdirAll(filepath.Dir(path), os.ModePerm); err != nil {
		return nil, err
	}

	data, err := base64.StdEncoding.DecodeString(base64Data)
	if err != nil {
		return nil, err
	}

	if err := os.WriteFile(path, data, 0644); err != nil {
		return nil, err
	}

	return &path, nil
}

// generateCode generates a random 6-character alphanumeric code
func generateCode() string {
	const letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	code := make([]byte, 6)
	for i := range code {
		code[i] = letters[rand.Intn(len(letters))]
	}
	return string(code)
}
