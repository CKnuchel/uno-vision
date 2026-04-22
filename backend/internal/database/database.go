package database

import (
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"

	"github.com/CKnuchel/uno-vision/internal/config"
	"github.com/CKnuchel/uno-vision/internal/models"
)

func Connect(conf *config.Config) (*gorm.DB, error) {
	db, err := gorm.Open(sqlite.Open(conf.DBPath), &gorm.Config{})
	if err != nil {
		return nil, err
	}

	// Auto Migrate the database schema
	err = db.AutoMigrate(
		&models.Player{},
		&models.Party{},
		&models.Round{},
		&models.RoundScore{},
		&models.PartyPlayer{},
	)
	if err != nil {
		return nil, err
	}

	return db, nil
}
