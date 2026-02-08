package admin

import (
	"bytes"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/serifu/backend/internal/admin/templates"
	"github.com/serifu/backend/internal/database"
)

func CategoryListHandler(c *gin.Context) {
	admin := GetAdminFromContext(c)
	db := database.GetDB()

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	if page < 1 {
		page = 1
	}
	pageSize := 20
	search := c.Query("search")

	query := db.Model(&database.Category{})
	if search != "" {
		query = query.Where("name ILIKE ?", "%"+search+"%")
	}

	var total int64
	query.Count(&total)

	var categories []database.Category
	query.Order("sort_order ASC, name ASC").
		Offset((page - 1) * pageSize).
		Limit(pageSize).
		Find(&categories)

	totalPages := int(total) / pageSize
	if int(total)%pageSize > 0 {
		totalPages++
	}

	var buf bytes.Buffer
	templates.CategoryList(admin.Name, categories, search, page, totalPages, int(total)).Render(c.Request.Context(), &buf)
	c.Data(http.StatusOK, "text/html; charset=utf-8", buf.Bytes())
}

func CategoryNewHandler(c *gin.Context) {
	admin := GetAdminFromContext(c)
	var buf bytes.Buffer
	templates.CategoryForm(admin.Name, nil, "").Render(c.Request.Context(), &buf)
	c.Data(http.StatusOK, "text/html; charset=utf-8", buf.Bytes())
}

func CategoryCreateHandler(c *gin.Context) {
	admin := GetAdminFromContext(c)
	db := database.GetDB()

	name := c.PostForm("name")
	if name == "" {
		var buf bytes.Buffer
		templates.CategoryForm(admin.Name, nil, "カテゴリ名は必須です").Render(c.Request.Context(), &buf)
		c.Data(http.StatusOK, "text/html; charset=utf-8", buf.Bytes())
		return
	}

	sortOrder, _ := strconv.Atoi(c.PostForm("sort_order"))

	category := database.Category{
		Name:        name,
		Description: c.PostForm("description"),
		Icon:        c.PostForm("icon"),
		Color:       c.PostForm("color"),
		SortOrder:   sortOrder,
		Status:      c.DefaultPostForm("status", "active"),
	}

	if err := db.Create(&category).Error; err != nil {
		var buf bytes.Buffer
		templates.CategoryForm(admin.Name, nil, "カテゴリの作成に失敗しました").Render(c.Request.Context(), &buf)
		c.Data(http.StatusOK, "text/html; charset=utf-8", buf.Bytes())
		return
	}

	db.Create(&database.AdminAuditLog{
		AdminUserID: admin.ID,
		Action:      "create_category",
		EntityType:  "category",
		EntityID:    category.ID.String(),
		IPAddress:   c.ClientIP(),
	})

	c.Redirect(http.StatusFound, "/admin/categories/"+category.ID.String())
}

func CategoryDetailHandler(c *gin.Context) {
	admin := GetAdminFromContext(c)
	db := database.GetDB()

	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.Redirect(http.StatusFound, "/admin/categories")
		return
	}

	var category database.Category
	if err := db.Preload("Quizzes").First(&category, "id = ?", id).Error; err != nil {
		c.Redirect(http.StatusFound, "/admin/categories")
		return
	}

	var buf bytes.Buffer
	templates.CategoryDetail(admin.Name, category).Render(c.Request.Context(), &buf)
	c.Data(http.StatusOK, "text/html; charset=utf-8", buf.Bytes())
}

func CategoryEditHandler(c *gin.Context) {
	admin := GetAdminFromContext(c)
	db := database.GetDB()

	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.Redirect(http.StatusFound, "/admin/categories")
		return
	}

	var category database.Category
	if err := db.First(&category, "id = ?", id).Error; err != nil {
		c.Redirect(http.StatusFound, "/admin/categories")
		return
	}

	var buf bytes.Buffer
	templates.CategoryForm(admin.Name, &category, "").Render(c.Request.Context(), &buf)
	c.Data(http.StatusOK, "text/html; charset=utf-8", buf.Bytes())
}

func CategoryUpdateHandler(c *gin.Context) {
	admin := GetAdminFromContext(c)
	db := database.GetDB()

	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.Redirect(http.StatusFound, "/admin/categories")
		return
	}

	var category database.Category
	if err := db.First(&category, "id = ?", id).Error; err != nil {
		c.Redirect(http.StatusFound, "/admin/categories")
		return
	}

	name := c.PostForm("name")
	if name == "" {
		var buf bytes.Buffer
		templates.CategoryForm(admin.Name, &category, "カテゴリ名は必須です").Render(c.Request.Context(), &buf)
		c.Data(http.StatusOK, "text/html; charset=utf-8", buf.Bytes())
		return
	}

	sortOrder, _ := strconv.Atoi(c.PostForm("sort_order"))

	db.Model(&category).Updates(map[string]interface{}{
		"name":        name,
		"description": c.PostForm("description"),
		"icon":        c.PostForm("icon"),
		"color":       c.PostForm("color"),
		"sort_order":  sortOrder,
		"status":      c.DefaultPostForm("status", "active"),
	})

	db.Create(&database.AdminAuditLog{
		AdminUserID: admin.ID,
		Action:      "update_category",
		EntityType:  "category",
		EntityID:    category.ID.String(),
		IPAddress:   c.ClientIP(),
	})

	c.Redirect(http.StatusFound, "/admin/categories/"+category.ID.String())
}

func CategoryDeleteHandler(c *gin.Context) {
	admin := GetAdminFromContext(c)
	db := database.GetDB()

	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.Redirect(http.StatusFound, "/admin/categories")
		return
	}

	var category database.Category
	if err := db.First(&category, "id = ?", id).Error; err != nil {
		c.Redirect(http.StatusFound, "/admin/categories")
		return
	}

	db.Delete(&category)

	db.Create(&database.AdminAuditLog{
		AdminUserID: admin.ID,
		Action:      "delete_category",
		EntityType:  "category",
		EntityID:    id.String(),
		IPAddress:   c.ClientIP(),
	})

	c.Redirect(http.StatusFound, "/admin/categories")
}
