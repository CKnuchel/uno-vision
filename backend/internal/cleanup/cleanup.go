package cleanup

import (
	"log"
	"os"
	"time"

	"github.com/CKnuchel/uno-vision/internal/models"
	"gorm.io/gorm"
)

const retentionDays = 90

// Start launches the cleanup job as a background goroutine
// Runs once immediately and then every 24 hours
func Start(db *gorm.DB) {
	go func() {
		// Run once on startup
		run(db)

		// Then every 24 hours
		ticker := time.NewTicker(24 * time.Hour)
		for range ticker.C {
			run(db)
		}
	}()
}

// run performs the actual cleanup
func run(db *gorm.DB) {
	cutoff := time.Now().AddDate(0, 0, -retentionDays)
	log.Printf("[Cleanup] Starting cleanup of data older than %s", cutoff.Format("2006-01-02"))

	// 1. Delete images from disk before DB entries are gone
	deleteImages(db, cutoff)

	// 2. Delete old parties (CASCADE deletes rounds, scores, party_players)
	result := db.Where("created_at < ?", cutoff).Delete(&models.Party{})
	if result.Error != nil {
		log.Printf("[Cleanup] Error deleting old parties: %v", result.Error)
		return
	}

	log.Printf("[Cleanup] Deleted %d parties older than %s", result.RowsAffected, cutoff.Format("2006-01-02"))
}

// deleteImages removes image files from disk for old round scores
func deleteImages(db *gorm.DB, cutoff time.Time) {
	var scores []models.RoundScore

	err := db.
		Joins("JOIN rounds ON rounds.id = round_scores.round_id").
		Joins("JOIN parties ON parties.id = rounds.party_id").
		Where("parties.created_at < ? AND round_scores.image_path IS NOT NULL", cutoff).
		Find(&scores).Error

	if err != nil {
		log.Printf("[Cleanup] Error finding old images: %v", err)
		return
	}

	deleted := 0
	for _, score := range scores {
		if score.ImagePath != nil {
			if err := os.Remove(*score.ImagePath); err != nil && !os.IsNotExist(err) {
				log.Printf("[Cleanup] Error deleting image %s: %v", *score.ImagePath, err)
			} else {
				deleted++
			}
		}
	}

	log.Printf("[Cleanup] Deleted %d images from disk", deleted)
}
