package models

import "gorm.io/gorm"

type Round struct {
	gorm.Model
	PartyID  uint `gorm:"not null"`
	Party    Party
	WinnerID *uint
	Winner   *Player
}
