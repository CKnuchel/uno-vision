package models

import "gorm.io/gorm"

type PartyStatus string
type PartyMode string

const (
	PartyStatusWaiting  PartyStatus = "waiting"
	PartyStatusPlaying  PartyStatus = "playing"
	PartyStatusFinished PartyStatus = "finished"
)

const (
	PartyModeClassic PartyMode = "classic"
	PartyModeGolf    PartyMode = "golf"
)

type Party struct {
	gorm.Model
	Code        string      `gorm:"unique;not null"`
	Mode        PartyMode   `gorm:"not null"`
	TargetScore int         `gorm:"not null"`
	Status      PartyStatus `gorm:"not null"`
}
