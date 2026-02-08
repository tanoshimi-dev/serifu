package admin

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"strings"

	"github.com/google/generative-ai-go/genai"
	"google.golang.org/api/option"
)

type GenerateRow struct {
	CategoryID   string `json:"category_id"`
	CategoryName string `json:"category_name"`
	Count        int    `json:"count"`
}

type GeneratedQuiz struct {
	CategoryID   string `json:"category_id"`
	CategoryName string `json:"category_name"`
	Title        string `json:"title"`
	Description  string `json:"description"`
}

type geminiQuiz struct {
	CategoryName string `json:"category_name"`
	Title        string `json:"title"`
	Description  string `json:"description"`
}

func GenerateQuizzes(ctx context.Context, rows []GenerateRow) ([]GeneratedQuiz, error) {
	apiKey := os.Getenv("GEMINI_API_KEY")
	if apiKey == "" {
		return nil, fmt.Errorf("GEMINI_API_KEY is not set")
	}

	client, err := genai.NewClient(ctx, option.WithAPIKey(apiKey))
	if err != nil {
		return nil, fmt.Errorf("failed to create Gemini client: %w", err)
	}
	defer client.Close()

	model := client.GenerativeModel("gemini-2.0-flash")
	temp := float32(0.9)
	model.Temperature = &temp
	model.ResponseMIMEType = "application/json"

	prompt := buildPrompt(rows)

	resp, err := model.GenerateContent(ctx, genai.Text(prompt))
	if err != nil {
		return nil, fmt.Errorf("failed to generate content: %w", err)
	}

	if len(resp.Candidates) == 0 || len(resp.Candidates[0].Content.Parts) == 0 {
		return nil, fmt.Errorf("empty response from Gemini")
	}

	text, ok := resp.Candidates[0].Content.Parts[0].(genai.Text)
	if !ok {
		return nil, fmt.Errorf("unexpected response type from Gemini")
	}

	var parsed []geminiQuiz
	if err := json.Unmarshal([]byte(text), &parsed); err != nil {
		return nil, fmt.Errorf("failed to parse Gemini response: %w", err)
	}

	// Map category_name back to category_id from input rows
	nameToID := make(map[string]string)
	for _, row := range rows {
		nameToID[row.CategoryName] = row.CategoryID
	}

	var quizzes []GeneratedQuiz
	for _, q := range parsed {
		catID, ok := nameToID[q.CategoryName]
		if !ok {
			continue
		}
		quizzes = append(quizzes, GeneratedQuiz{
			CategoryID:   catID,
			CategoryName: q.CategoryName,
			Title:        q.Title,
			Description:  q.Description,
		})
	}

	return quizzes, nil
}

func buildPrompt(rows []GenerateRow) string {
	var requestLines []string
	for _, row := range rows {
		requestLines = append(requestLines, fmt.Sprintf("- カテゴリ「%s」: %d件", row.CategoryName, row.Count))
	}

	return fmt.Sprintf(`あなたは「セリフ」というユーモア大喜利アプリのお題作成AIです。
ユーザーが面白い回答を投稿できるような「お題」を作成してください。

【生成リクエスト】
%s

【お題の例】
- 「朝起きて最初に言うセリフ」
- 「上司に怒られた時に心の中で思うセリフ」
- 「好きな人に告白する時のセリフ」

【ルール】
1. 日本語で書く
2. 「〜のセリフ」「〜の時に言う一言」形式
3. 多様な面白い回答が可能なお題にする
4. 例と重複しない
5. 各お題にdescriptionとして短い補足説明をつける

JSON配列形式: [{"category_name":"...","title":"...","description":"..."}]`, strings.Join(requestLines, "\n"))
}
