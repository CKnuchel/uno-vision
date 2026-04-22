package repository

import (
	"context"

	"github.com/CKnuchel/uno-vision/internal/models"
	"gorm.io/gorm"
)

type RoundScoreRepository interface {
	Create(ctx context.Context, roundScore *models.RoundScore) error
	FindByRoundID(ctx context.Context, roundID uint) ([]models.RoundScore, error)
	HasPlayerSubmitted(ctx context.Context, roundID, playerID uint) bool
	CountByRoundID(ctx context.Context, roundID uint) (int64, error)
}

type roundScoreRepository struct {
	db *gorm.DB
}

// CountByRoundID implements [RoundScoreRepository].
func (r *roundScoreRepository) CountByRoundID(ctx context.Context, roundID uint) (int64, error) {
	var count int64

	err := r.db.WithContext(ctx).Model(&models.RoundScore{}).Where("round_id = ?", roundID).Count(&count).Error
	if err != nil {
		return 0, err
	}

	return count, nil
}

// Create implements [RoundScoreRepository].
func (r *roundScoreRepository) Create(ctx context.Context, roundScore *models.RoundScore) error {
	return r.db.WithContext(ctx).Create(roundScore).Error
}

// FindByRoundID implements [RoundScoreRepository].
func (r *roundScoreRepository) FindByRoundID(ctx context.Context, roundID uint) ([]models.RoundScore, error) {
	var roundScores []models.RoundScore

	err := r.db.WithContext(ctx).Where("round_id = ?", roundID).Find(&roundScores).Error
	if err != nil {
		return nil, err
	}

	return roundScores, nil
}

// HasPlayerSubmitted implements [RoundScoreRepository].
func (r *roundScoreRepository) HasPlayerSubmitted(ctx context.Context, roundID uint, playerID uint) bool {
	var count int64

	err := r.db.WithContext(ctx).Model(&models.RoundScore{}).Where("round_id = ? AND player_id = ?", roundID, playerID).Count(&count).Error
	if err != nil {
		return false
	}

	return count > 0
}

func NewRoundScoreRepository(db *gorm.DB) RoundScoreRepository {
	return &roundScoreRepository{db: db}
}
