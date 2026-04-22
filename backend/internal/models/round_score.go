package models

import "gorm.io/gorm"

type RoundScore struct {
	gorm.Model
	RoundID   uint `gorm:"not null"`
	Round     Round
	PlayerID  uint `gorm:"not null"`
	Player    Player
	Points    int     `gorm:"not null"`
	ImagePath *string `gorm:"size:255"`
}
