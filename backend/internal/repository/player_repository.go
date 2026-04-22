package repository

import (
	"context"

	"github.com/CKnuchel/uno-vision/internal/models"
	"gorm.io/gorm"
)

type PlayerRepository interface {
	FindByUUID(ctx context.Context, uuid string) (*models.Player, error)
	FindOrCreate(ctx context.Context, uuid, name string) (*models.Player, error)
}

type playerRepository struct {
	db *gorm.DB
}

// FindByUUID implements [PlayerRepository].
func (r *playerRepository) FindByUUID(ctx context.Context, uuid string) (*models.Player, error) {
	var player models.Player

	err := r.db.WithContext(ctx).Where("uuid = ?", uuid).First(&player).Error
	if err != nil {
		return nil, err
	}

	return &player, nil
}

// FindOrCreate implements [PlayerRepository].
func (r *playerRepository) FindOrCreate(ctx context.Context, uuid string, name string) (*models.Player, error) {
	player := models.Player{UUID: uuid, Name: name}

	err := r.db.WithContext(ctx).Where("uuid = ?", uuid).FirstOrCreate(&player).Error
	if err != nil {
		return nil, err
	}

	return &player, nil
}

func NewPlayerRepository(db *gorm.DB) PlayerRepository {
	return &playerRepository{db: db}
}
