package models

import "gorm.io/gorm"

type PartyPlayer struct {
	gorm.Model
	PartyID    uint `gorm:"not null"`
	Party      Party
	PlayerID   uint `gorm:"not null"`
	Player     Player
	TotalScore int `gorm:"not null"`
}
