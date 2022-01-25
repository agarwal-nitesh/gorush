package ginstatus

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// GinHandler is gin handle for get system status.
func GinHandler(c *gin.Context) {
	c.JSON(http.StatusOK, GetStats())
}
