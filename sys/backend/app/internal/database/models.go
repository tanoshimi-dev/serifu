package database

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type User struct {
	ID           uuid.UUID      `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	Email        string         `gorm:"uniqueIndex;not null" json:"email"`
	Name         string         `gorm:"not null" json:"name"`
	PasswordHash string         `gorm:"default:''" json:"-"`
	Avatar       string         `json:"avatar"`
	Bio          string         `json:"bio"`
	TotalLikes   int            `gorm:"default:0" json:"total_likes"`
	Status       string         `gorm:"default:active" json:"status"`
	CreatedAt  time.Time      `json:"created_at"`
	UpdatedAt  time.Time      `json:"updated_at"`
	DeletedAt  gorm.DeletedAt `gorm:"index" json:"-"`

	Answers   []Answer  `gorm:"foreignKey:UserID" json:"-"`
	Comments  []Comment `gorm:"foreignKey:UserID" json:"-"`
	Likes     []Like    `gorm:"foreignKey:UserID" json:"-"`
	Followers []Follow  `gorm:"foreignKey:FollowingID" json:"-"`
	Following []Follow  `gorm:"foreignKey:FollowerID" json:"-"`
}

type Category struct {
	ID          uuid.UUID `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	Name        string    `gorm:"not null" json:"name"`
	Description string    `json:"description"`
	Icon        string    `json:"icon"`
	Color       string    `json:"color"`
	SortOrder   int       `gorm:"default:0" json:"sort_order"`
	Status      string    `gorm:"default:active" json:"status"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`

	Quizzes []Quiz `gorm:"foreignKey:CategoryID" json:"-"`
}

type Quiz struct {
	ID          uuid.UUID      `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	Title       string         `gorm:"not null" json:"title"`
	Description string         `json:"description"`
	Requirement string         `json:"requirement"`
	CategoryID  *uuid.UUID     `gorm:"type:uuid;index" json:"category_id"`
	ReleaseDate time.Time      `gorm:"index" json:"release_date"`
	Status      string         `gorm:"default:draft" json:"status"`
	AnswerCount int            `gorm:"default:0" json:"answer_count"`
	CreatedAt   time.Time      `json:"created_at"`
	UpdatedAt   time.Time      `json:"updated_at"`
	DeletedAt   gorm.DeletedAt `gorm:"index" json:"-"`

	Category *Category `gorm:"foreignKey:CategoryID" json:"category,omitempty"`
	Answers  []Answer  `gorm:"foreignKey:QuizID" json:"-"`
}

type Answer struct {
	ID           uuid.UUID      `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	QuizID       uuid.UUID      `gorm:"type:uuid;index;not null" json:"quiz_id"`
	UserID       uuid.UUID      `gorm:"type:uuid;index;not null" json:"user_id"`
	Content      string         `gorm:"size:150;not null" json:"content"`
	LikeCount    int            `gorm:"default:0" json:"like_count"`
	CommentCount int            `gorm:"default:0" json:"comment_count"`
	ViewCount    int            `gorm:"default:0" json:"view_count"`
	Status       string         `gorm:"default:active" json:"status"`
	CreatedAt    time.Time      `json:"created_at"`
	UpdatedAt    time.Time      `json:"updated_at"`
	DeletedAt    gorm.DeletedAt `gorm:"index" json:"-"`

	Quiz     *Quiz     `gorm:"foreignKey:QuizID" json:"quiz,omitempty"`
	User     *User     `gorm:"foreignKey:UserID" json:"user,omitempty"`
	Comments []Comment `gorm:"foreignKey:AnswerID" json:"-"`
	Likes    []Like    `gorm:"foreignKey:AnswerID" json:"-"`
}

type Comment struct {
	ID        uuid.UUID      `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	AnswerID  uuid.UUID      `gorm:"type:uuid;index;not null" json:"answer_id"`
	UserID    uuid.UUID      `gorm:"type:uuid;index;not null" json:"user_id"`
	Content   string         `gorm:"not null" json:"content"`
	Status    string         `gorm:"default:active" json:"status"`
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"`

	Answer *Answer `gorm:"foreignKey:AnswerID" json:"-"`
	User   *User   `gorm:"foreignKey:UserID" json:"user,omitempty"`
}

type Like struct {
	ID        uuid.UUID `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	AnswerID  uuid.UUID `gorm:"type:uuid;index;not null" json:"answer_id"`
	UserID    uuid.UUID `gorm:"type:uuid;index;not null" json:"user_id"`
	CreatedAt time.Time `json:"created_at"`

	Answer *Answer `gorm:"foreignKey:AnswerID" json:"-"`
	User   *User   `gorm:"foreignKey:UserID" json:"user,omitempty"`
}

type Follow struct {
	ID          uuid.UUID `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	FollowerID  uuid.UUID `gorm:"type:uuid;index;not null" json:"follower_id"`
	FollowingID uuid.UUID `gorm:"type:uuid;index;not null" json:"following_id"`
	CreatedAt   time.Time `json:"created_at"`

	Follower  *User `gorm:"foreignKey:FollowerID" json:"follower,omitempty"`
	Following *User `gorm:"foreignKey:FollowingID" json:"following,omitempty"`
}

type AdminUser struct {
	ID           uuid.UUID  `gorm:"type:uuid;primaryKey;default:gen_random_uuid()"`
	Email        string     `gorm:"uniqueIndex;not null"`
	Name         string     `gorm:"not null"`
	PasswordHash string     `gorm:"not null"`
	Role         string     `gorm:"default:admin"`
	Status       string     `gorm:"default:active"`
	LastLoginAt  *time.Time
	CreatedAt    time.Time
	UpdatedAt    time.Time
}

type AdminAuditLog struct {
	ID          uuid.UUID `gorm:"type:uuid;primaryKey;default:gen_random_uuid()"`
	AdminUserID uuid.UUID `gorm:"type:uuid;index;not null"`
	Action      string    `gorm:"not null"`
	EntityType  string
	EntityID    string
	IPAddress   string
	CreatedAt   time.Time

	AdminUser *AdminUser `gorm:"foreignKey:AdminUserID"`
}

func (Like) TableName() string {
	return "likes"
}

func (Follow) TableName() string {
	return "follows"
}
