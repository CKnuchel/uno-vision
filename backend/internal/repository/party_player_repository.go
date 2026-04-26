package repository

import (
	"context"

	"github.com/CKnuchel/uno-vision/internal/models"
	"gorm.io/gorm"
)

type PartyPlayerRepository interface {
	Create(ctx context.Context, pp *models.PartyPlayer) error
	FindByPartyID(ctx context.Context, partyID uint) ([]models.PartyPlayer, error)
	FindByPartyAndPlayer(ctx context.Context, partyID, playerID uint) (*models.PartyPlayer, error)
	IsPlayerInParty(ctx context.Context, partyID, playerID uint) bool
	UpdateScore(ctx context.Context, partyID, playerID uint, points int) error
	GetHostByPartyID(ctx context.Context, partyID uint) (*models.Player, error) // <- Erster Eintrag = Host
	Delete(ctx context.Context, partyID, playerID uint) error
}

type partyPlayerRepository struct {
	db *gorm.DB
}

// Create implements [PartyPlayerRepository].
func (r *partyPlayerRepository) Create(ctx context.Context, pp *models.PartyPlayer) error {
	return r.db.WithContext(ctx).Create(pp).Error
}

// FindByPartyAndPlayer implements [PartyPlayerRepository].
func (r *partyPlayerRepository) FindByPartyAndPlayer(ctx context.Context, partyID uint, playerID uint) (*models.PartyPlayer, error) {
	var pp models.PartyPlayer

	err := r.db.WithContext(ctx).Where("party_id = ? AND player_id = ?", partyID, playerID).First(&pp).Error
	if err != nil {
		return nil, nil // Not found, return nil without error
	}

	return &pp, nil
}

// FindByPartyID implements [PartyPlayerRepository].
func (r *partyPlayerRepository) FindByPartyID(ctx context.Context, partyID uint) ([]models.PartyPlayer, error) {
	var pps []models.PartyPlayer

	err := r.db.WithContext(ctx).
		Preload("Player").
		Where("party_id = ?", partyID).
		Find(&pps).Error
	if err != nil {
		return nil, err
	}

	return pps, nil
}

// GetHostByPartyID implements [PartyPlayerRepository].
func (r *partyPlayerRepository) GetHostByPartyID(ctx context.Context, partyID uint) (*models.Player, error) {
	var pp models.PartyPlayer

	err := r.db.WithContext(ctx).Where("party_id = ?", partyID).Order("created_at").First(&pp).Error
	if err != nil {
		return nil, err
	}

	var player models.Player
	err = r.db.WithContext(ctx).First(&player, pp.PlayerID).Error
	if err != nil {
		return nil, err
	}

	return &player, nil
}

// IsPlayerInParty implements [PartyPlayerRepository].
func (r *partyPlayerRepository) IsPlayerInParty(ctx context.Context, partyID uint, playerID uint) bool {
	var count int64

	err := r.db.WithContext(ctx).Model(&models.PartyPlayer{}).Where("party_id = ? AND player_id = ?", partyID, playerID).Count(&count).Error
	if err != nil {
		return false
	}

	return count > 0
}

// UpdateScore implements [PartyPlayerRepository].
func (r *partyPlayerRepository) UpdateScore(ctx context.Context, partyID uint, playerID uint, points int) error {
	err := r.db.WithContext(ctx).Model(&models.PartyPlayer{}).Where("party_id = ? AND player_id = ?", partyID, playerID).Update("total_score", gorm.Expr("total_score + ?", points)).Error
	if err != nil {
		return err
	}

	return nil
}

// Delete implements [PartyPlayerRepository].
func (r *partyPlayerRepository) Delete(ctx context.Context, partyID uint, playerID uint) error {
	return r.db.WithContext(ctx).Where("party_id = ? AND player_id = ?", partyID, playerID).Delete(&models.PartyPlayer{}).Error
}

func NewPartyPlayerRepository(db *gorm.DB) PartyPlayerRepository {
	return &partyPlayerRepository{db: db}
}
