<template>
  <section class="example">
    <div class="container">
      <p class="section-badge">Example</p>
      <h2 class="section-title">こんな感じで楽しめる</h2>
      <p class="section-desc">お題に対してユーザーが面白い一言を投稿</p>

      <div class="example-card">
        <div class="quiz-header">
          <span class="quiz-badge">🎭 今日のお題</span>
          <span class="quiz-category">日常</span>
        </div>
        <h3 class="quiz-title">「朝起きて最初に言うセリフ」</h3>
        <p class="quiz-desc">毎朝のルーティンを劇的に変える、あなたの目覚めの一言。</p>

        <div class="answers">
          <div class="answer" v-for="answer in answers" :key="answer.user">
            <div class="answer-header">
              <span class="answer-avatar">{{ answer.avatar }}</span>
              <span class="answer-user">{{ answer.user }}</span>
              <span class="answer-likes">❤️ {{ answer.likes }}</span>
            </div>
            <p class="answer-text">「{{ answer.text }}」</p>
          </div>
        </div>
      </div>
    </div>
  </section>
</template>

<script setup>
const answers = [
  {
    avatar: '👨‍💻',
    user: '@comedy_king',
    likes: 234,
    text: '二度寝の誘惑に勝ったので、今日は残りの人生で最も偉大な日です'
  },
  {
    avatar: '👩‍🎨',
    user: '@creative_writer',
    likes: 189,
    text: 'よし、今日も社会に貢献するフリをしに行くか'
  },
  {
    avatar: '🧑‍🚀',
    user: '@dream_chaser',
    likes: 156,
    text: 'あ、まだ生きてた。じゃあ朝ごはん食べよう'
  }
]
</script>

<style scoped>
.example {
  padding: 100px 0;
  background: linear-gradient(180deg, #f8f7ff 0%, #fff 100%);
}

.example-card {
  max-width: 640px;
  margin: 56px auto 0;
  background: #fff;
  border-radius: 20px;
  padding: 36px;
  box-shadow: 0 8px 32px rgba(108, 92, 231, 0.1);
  border: 1px solid rgba(108, 92, 231, 0.12);
}

.quiz-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 16px;
}

.quiz-badge {
  font-size: 13px;
  font-weight: 600;
  color: var(--primary);
}

.quiz-category {
  font-size: 12px;
  font-weight: 500;
  background: rgba(255, 165, 2, 0.1);
  color: #e67e00;
  padding: 4px 12px;
  border-radius: 12px;
}

.quiz-title {
  font-size: 22px;
  font-weight: 800;
  color: var(--text);
  margin-bottom: 8px;
}

.quiz-desc {
  font-size: 14px;
  color: var(--text-light);
  margin-bottom: 28px;
  padding-bottom: 24px;
  border-bottom: 1px solid #f0f0f0;
}

.answers {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.answer {
  padding: 16px;
  background: #fafafa;
  border-radius: 12px;
}

.answer-header {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 10px;
}

.answer-avatar {
  font-size: 20px;
}

.answer-user {
  font-size: 13px;
  font-weight: 600;
  color: var(--text);
  flex: 1;
}

.answer-likes {
  font-size: 13px;
  color: var(--text-light);
}

.answer-text {
  font-size: 15px;
  line-height: 1.6;
  color: var(--text);
  font-weight: 500;
}

@media (max-width: 768px) {
  .example {
    padding: 60px 0;
  }

  .example-card {
    padding: 24px;
    margin-top: 40px;
  }

  .quiz-title {
    font-size: 18px;
  }
}
</style>
