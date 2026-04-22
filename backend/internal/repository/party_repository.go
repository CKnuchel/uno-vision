package repository

import (
	"context"

	"github.com/CKnuchel/uno-vision/internal/models"
	"gorm.io/gorm"
)

type PartyRepository interface {
	FindByID(ctx context.Context, id uint) (*models.Party, error)
	FindByCode(ctx context.Context, code string) (*models.Party, error)
	Create(ctx context.Context, party *models.Party) error
	UpdateStatus(ctx context.Context, id uint, status models.PartyStatus) error
	ExistsByCode(ctx context.Context, code string) (bool, error)
}

type partyRepository struct {
	db *gorm.DB
}

// ExistsByCode implements [PartyRepository].
func (r *partyRepository) ExistsByCode(ctx context.Context, code string) (bool, error) {
	var count int64

	err := r.db.WithContext(ctx).Model(&models.Party{}).Where("code = ?", code).Count(&count).Error
	if err != nil {
		return false, err
	}

	return count > 0, nil
}

// Create implements [PartyRepository].
func (r *partyRepository) Create(ctx context.Context, party *models.Party) error {
	return r.db.WithContext(ctx).Create(party).Error
}

// FindByCode implements [PartyRepository].
func (r *partyRepository) FindByCode(ctx context.Context, code string) (*models.Party, error) {
	var party models.Party

	err := r.db.WithContext(ctx).Where("code = ?", code).First(&party).Error
	if err != nil {
		return nil, err
	}

	return &party, nil
}

// FindByID implements [PartyRepository].
func (r *partyRepository) FindByID(ctx context.Context, id uint) (*models.Party, error) {
	var party models.Party

	err := r.db.WithContext(ctx).First(&party, id).Error
	if err != nil {
		return nil, err
	}

	return &party, nil
}

// UpdateStatus implements [PartyRepository].
func (r *partyRepository) UpdateStatus(ctx context.Context, id uint, status models.PartyStatus) error {
	return r.db.WithContext(ctx).Model(&models.Party{}).Where("id = ?", id).Update("status", status).Error
}

func NewPartyRepository(db *gorm.DB) PartyRepository {
	return &partyRepository{db: db}
}
