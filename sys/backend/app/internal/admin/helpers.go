package admin

import (
	"strconv"

	"github.com/gin-gonic/gin"
)

func parseSizeParam(c *gin.Context, defaultSize int) int {
	size, err := strconv.Atoi(c.Query("size"))
	if err != nil || size < 1 {
		return defaultSize
	}
	if size > 100 {
		return 100
	}
	return size
}
