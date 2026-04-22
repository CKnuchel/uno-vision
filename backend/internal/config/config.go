package config

import "os"

type Config struct {
	Port        string
	DBPath      string
	UploadPath  string
	MaxFileSize int64
}

func Load() *Config {
	return &Config{
		Port:        getEnv("PORT", "8080"),
		DBPath:      getEnv("DB_PATH", "sqlite.db"),
		UploadPath:  getEnv("UPLOAD_PATH", "uploads/"),
		MaxFileSize: 10 << 20, // 10MB
	}
}

func getEnv(key, fallback string) string {
	if value, exists := os.LookupEnv(key); exists {
		return value
	}
	return fallback
}
