package router

import (
	"github.com/gin-gonic/gin"
	"github.com/serifu/backend/internal/config"
	"github.com/serifu/backend/internal/handlers"
	"github.com/serifu/backend/internal/middleware"
	"github.com/serifu/backend/internal/utils"
)

func SetupRouter(cfg *config.Config) *gin.Engine {
	gin.SetMode(cfg.Server.GinMode)

	r := gin.Default()

	r.Use(middleware.CORSMiddleware())

	r.GET("/health", func(c *gin.Context) {
		utils.SuccessResponse(c, gin.H{
			"status":  "healthy",
			"service": "serifu-backend",
		})
	})

	authHandler := handlers.NewAuthHandler(cfg.JWT.Secret, cfg.JWT.TTLHours)
	socialAuthHandler := handlers.NewSocialAuthHandler(cfg.JWT.Secret, cfg.JWT.TTLHours, cfg.SocialAuth)
	quizHandler := handlers.NewQuizHandler(cfg.Pagination.DefaultPageSize, cfg.Pagination.MaxPageSize)
	answerHandler := handlers.NewAnswerHandler(cfg.Pagination.DefaultPageSize, cfg.Pagination.MaxPageSize)
	likeHandler := handlers.NewLikeHandler()
	commentHandler := handlers.NewCommentHandler(cfg.Pagination.DefaultPageSize, cfg.Pagination.MaxPageSize)
	userHandler := handlers.NewUserHandler(cfg.Pagination.DefaultPageSize, cfg.Pagination.MaxPageSize)
	followHandler := handlers.NewFollowHandler(cfg.Pagination.DefaultPageSize, cfg.Pagination.MaxPageSize)
	rankingHandler := handlers.NewRankingHandler(cfg.Pagination.DefaultPageSize, cfg.Pagination.MaxPageSize)
	notificationHandler := handlers.NewNotificationHandler(cfg.Pagination.DefaultPageSize, cfg.Pagination.MaxPageSize)

	v1 := r.Group("/api/v1")
	{
		// Auth routes
		auth := v1.Group("/auth")
		{
			auth.POST("/register", authHandler.Register)
			auth.POST("/login", authHandler.Login)
			auth.GET("/me", middleware.JWTAuthMiddleware(cfg.JWT.Secret), authHandler.GetMe)
			auth.POST("/google", socialAuthHandler.GoogleLogin)
			auth.POST("/apple", socialAuthHandler.AppleLogin)
			auth.POST("/line", socialAuthHandler.LineLogin)
		}

		// Quiz routes
		quizzes := v1.Group("/quizzes")
		{
			quizzes.GET("/daily", quizHandler.GetDailyQuizzes)
			quizzes.GET("", quizHandler.ListQuizzes)
			quizzes.GET("/:id", quizHandler.GetQuiz)
			quizzes.POST("", quizHandler.CreateQuiz)
			quizzes.PUT("/:id", quizHandler.UpdateQuiz)

			// Answer routes under quiz
			quizzes.GET("/:id/answers", answerHandler.GetAnswersForQuiz)
			quizzes.POST("/:id/answers", answerHandler.CreateAnswer)
		}

		// Answer routes
		answers := v1.Group("/answers")
		{
			answers.GET("/:id", answerHandler.GetAnswer)
			answers.PUT("/:id", answerHandler.UpdateAnswer)
			answers.DELETE("/:id", answerHandler.DeleteAnswer)

			// Like routes
			answers.POST("/:id/like", likeHandler.LikeAnswer)
			answers.DELETE("/:id/like", likeHandler.UnlikeAnswer)

			// Comment routes
			answers.GET("/:id/comments", commentHandler.GetCommentsForAnswer)
			answers.POST("/:id/comments", commentHandler.CreateComment)
		}

		// Comment routes
		comments := v1.Group("/comments")
		{
			comments.DELETE("/:id", commentHandler.DeleteComment)
		}

		// User routes
		users := v1.Group("/users")
		{
			users.GET("/:id", userHandler.GetUser)
			users.GET("/:id/answers", userHandler.GetUserAnswers)
			users.PUT("/:id", userHandler.UpdateUser)

			// Follow routes
			users.POST("/:id/follow", followHandler.FollowUser)
			users.DELETE("/:id/follow", followHandler.UnfollowUser)
			users.GET("/:id/followers", followHandler.GetFollowers)
			users.GET("/:id/following", followHandler.GetFollowing)
		}

		// Trending routes
		trending := v1.Group("/trending")
		{
			trending.GET("/answers", rankingHandler.GetTrendingAnswers)
		}

		// Rankings routes
		rankings := v1.Group("/rankings")
		{
			rankings.GET("/daily", rankingHandler.GetDailyRankings)
			rankings.GET("/weekly", rankingHandler.GetWeeklyRankings)
			rankings.GET("/all-time", rankingHandler.GetAllTimeRankings)
		}

		// Notification routes
		notifications := v1.Group("/notifications")
		{
			notifications.GET("", notificationHandler.GetNotifications)
			notifications.PUT("/read-all", notificationHandler.MarkAllAsRead)
			notifications.GET("/unread-count", notificationHandler.GetUnreadCount)
		}

		// Category routes
		categories := v1.Group("/categories")
		{
			categories.GET("", rankingHandler.GetCategories)
		}
	}

	return r
}
