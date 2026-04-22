package models

import "gorm.io/gorm"

type Player struct {
	gorm.Model
	UUID string `gorm:"unique;not null"`
	Name string `gorm:"not null;size:255"`
}
