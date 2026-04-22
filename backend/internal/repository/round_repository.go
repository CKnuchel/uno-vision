package repository

import (
	"context"

	"github.com/CKnuchel/uno-vision/internal/models"
	"gorm.io/gorm"
)

type RoundRepository interface {
	Create(ctx context.Context, round *models.Round) error
	FindByID(ctx context.Context, id uint) (*models.Round, error)
}

type roundRepository struct {
	db *gorm.DB
}

// Create implements [RoundRepository].
func (r *roundRepository) Create(ctx context.Context, round *models.Round) error {
	return r.db.WithContext(ctx).Create(round).Error
}

// FindByID implements [RoundRepository].
func (r *roundRepository) FindByID(ctx context.Context, id uint) (*models.Round, error) {
	var round models.Round

	err := r.db.WithContext(ctx).First(&round, id).Error
	if err != nil {
		return nil, err
	}

	return &round, nil
}

func NewRoundRepository(db *gorm.DB) RoundRepository {
	return &roundRepository{db: db}
}
