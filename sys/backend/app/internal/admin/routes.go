package admin

import (
	"github.com/gin-contrib/sessions"
	"github.com/gin-contrib/sessions/cookie"
	"github.com/gin-gonic/gin"
	"github.com/serifu/backend/internal/config"
)

func SetupRoutes(r *gin.Engine, cfg *config.Config) {
	store := cookie.NewStore([]byte(cfg.Admin.SessionSecret))
	store.Options(sessions.Options{
		Path:     "/admin",
		MaxAge:   cfg.Admin.SessionTTL * 3600,
		HttpOnly: true,
	})
	r.Use(sessions.Sessions("admin_session", store))

	adminGroup := r.Group("/admin")
	{
		// Public routes (no auth)
		adminGroup.GET("/login", LoginPage)
		adminGroup.POST("/login", LoginHandler)

		// Protected routes
		auth := adminGroup.Group("")
		auth.Use(AuthRequired())
		{
			auth.GET("/logout", LogoutHandler)
			auth.GET("/", DashboardHandler)

			// Categories
			auth.GET("/categories", CategoryListHandler)
			auth.GET("/categories/new", CategoryNewHandler)
			auth.POST("/categories", CategoryCreateHandler)
			auth.GET("/categories/:id", CategoryDetailHandler)
			auth.GET("/categories/:id/edit", CategoryEditHandler)
			auth.POST("/categories/:id", CategoryUpdateHandler)
			auth.POST("/categories/:id/delete", CategoryDeleteHandler)

			// Quizzes
			auth.GET("/quizzes", QuizListHandler)
			auth.GET("/quizzes/new", QuizNewHandler)
			auth.POST("/quizzes", QuizCreateHandler)
			auth.GET("/quizzes/:id", QuizDetailHandler)
			auth.GET("/quizzes/:id/edit", QuizEditHandler)
			auth.POST("/quizzes/:id", QuizUpdateHandler)
			auth.POST("/quizzes/:id/delete", QuizDeleteHandler)

			// Users
			auth.GET("/users", UserListHandler)
			auth.GET("/users/:id", UserDetailHandler)
			auth.POST("/users/:id/suspend", UserSuspendHandler)
			auth.POST("/users/:id/unsuspend", UserUnsuspendHandler)

			// Answers
			auth.GET("/answers", AnswerListHandler)
			auth.GET("/answers/:id", AnswerDetailHandler)
			auth.POST("/answers/:id/moderate", AnswerModerateHandler)
			auth.POST("/answers/:id/unmoderate", AnswerUnmoderateHandler)

			// Comments
			auth.GET("/comments", CommentListHandler)
			auth.GET("/comments/:id", CommentDetailHandler)
			auth.POST("/comments/:id/moderate", CommentModerateHandler)
			auth.POST("/comments/:id/unmoderate", CommentUnmoderateHandler)
		}
	}
}
