package handlers

import (
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/serifu/backend/internal/database"
	"github.com/serifu/backend/internal/utils"
)

type RankingHandler struct {
	defaultPageSize int
	maxPageSize     int
}

func NewRankingHandler(defaultPageSize, maxPageSize int) *RankingHandler {
	return &RankingHandler{
		defaultPageSize: defaultPageSize,
		maxPageSize:     maxPageSize,
	}
}

func (h *RankingHandler) GetTrendingAnswers(c *gin.Context) {
	db := database.GetDB()

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", strconv.Itoa(h.defaultPageSize)))
	if pageSize > h.maxPageSize {
		pageSize = h.maxPageSize
	}
	if page < 1 {
		page = 1
	}

	// Trending considers recency (last 7 days) with engagement score
	sevenDaysAgo := time.Now().AddDate(0, 0, -7)

	query := db.Model(&database.Answer{}).
		Preload("User").
		Preload("Quiz").
		Where("status = ? AND created_at >= ?", "active", sevenDaysAgo)

	var total int64
	query.Count(&total)

	// Trending score: likes + (comments * 2) + (views * 0.1)
	// With time decay built into the WHERE clause (last 7 days)
	var answers []database.Answer
	offset := (page - 1) * pageSize
	if err := query.
		Order("(like_count + comment_count * 2 + view_count * 0.1) DESC, created_at DESC").
		Offset(offset).
		Limit(pageSize).
		Find(&answers).Error; err != nil {
		utils.InternalErrorResponse(c, "Failed to fetch trending answers")
		return
	}

	utils.PaginatedSuccessResponse(c, answers, page, pageSize, total)
}

func (h *RankingHandler) GetDailyRankings(c *gin.Context) {
	db := database.GetDB()

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", strconv.Itoa(h.defaultPageSize)))
	if pageSize > h.maxPageSize {
		pageSize = h.maxPageSize
	}
	if page < 1 {
		page = 1
	}

	today := time.Now().Truncate(24 * time.Hour)
	tomorrow := today.Add(24 * time.Hour)

	query := db.Model(&database.Answer{}).
		Preload("User").
		Preload("Quiz").
		Where("status = ? AND created_at >= ? AND created_at < ?", "active", today, tomorrow)

	var total int64
	query.Count(&total)

	var answers []database.Answer
	offset := (page - 1) * pageSize
	if err := query.
		Order("like_count DESC, created_at DESC").
		Offset(offset).
		Limit(pageSize).
		Find(&answers).Error; err != nil {
		utils.InternalErrorResponse(c, "Failed to fetch daily rankings")
		return
	}

	utils.PaginatedSuccessResponse(c, answers, page, pageSize, total)
}

func (h *RankingHandler) GetWeeklyRankings(c *gin.Context) {
	db := database.GetDB()

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", strconv.Itoa(h.defaultPageSize)))
	if pageSize > h.maxPageSize {
		pageSize = h.maxPageSize
	}
	if page < 1 {
		page = 1
	}

	sevenDaysAgo := time.Now().AddDate(0, 0, -7)

	query := db.Model(&database.Answer{}).
		Preload("User").
		Preload("Quiz").
		Where("status = ? AND created_at >= ?", "active", sevenDaysAgo)

	var total int64
	query.Count(&total)

	var answers []database.Answer
	offset := (page - 1) * pageSize
	if err := query.
		Order("like_count DESC, created_at DESC").
		Offset(offset).
		Limit(pageSize).
		Find(&answers).Error; err != nil {
		utils.InternalErrorResponse(c, "Failed to fetch weekly rankings")
		return
	}

	utils.PaginatedSuccessResponse(c, answers, page, pageSize, total)
}

func (h *RankingHandler) GetAllTimeRankings(c *gin.Context) {
	db := database.GetDB()

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", strconv.Itoa(h.defaultPageSize)))
	if pageSize > h.maxPageSize {
		pageSize = h.maxPageSize
	}
	if page < 1 {
		page = 1
	}

	query := db.Model(&database.Answer{}).
		Preload("User").
		Preload("Quiz").
		Where("status = ?", "active")

	var total int64
	query.Count(&total)

	var answers []database.Answer
	offset := (page - 1) * pageSize
	if err := query.
		Order("like_count DESC, created_at DESC").
		Offset(offset).
		Limit(pageSize).
		Find(&answers).Error; err != nil {
		utils.InternalErrorResponse(c, "Failed to fetch all-time rankings")
		return
	}

	utils.PaginatedSuccessResponse(c, answers, page, pageSize, total)
}

func (h *RankingHandler) GetCategories(c *gin.Context) {
	db := database.GetDB()

	var categories []database.Category
	if err := db.Where("status = ?", "active").Order("sort_order ASC, name ASC").Find(&categories).Error; err != nil {
		utils.InternalErrorResponse(c, "Failed to fetch categories")
		return
	}

	utils.SuccessResponse(c, categories)
}
