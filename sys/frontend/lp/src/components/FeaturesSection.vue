<template>
  <section id="features" class="features">
    <div class="container">
      <p class="section-badge">Features</p>
      <h2 class="section-title">セリフの特徴</h2>
      <p class="section-desc">面白さを追求するすべての人のために</p>
      <div class="features-grid">
        <div class="feature-card" v-for="feature in features" :key="feature.title">
          <div class="feature-icon" :style="{ background: feature.bg }">{{ feature.icon }}</div>
          <h3>{{ feature.title }}</h3>
          <p>{{ feature.desc }}</p>
        </div>
      </div>
    </div>
  </section>
</template>

<script setup>
const features = [
  {
    icon: '🤖',
    title: 'AIが毎日お題を生成',
    desc: '毎朝5つの新しいシチュエーションお題が届きます。AIが多彩なジャンルから面白いお題を自動生成。',
    bg: 'rgba(108, 92, 231, 0.1)'
  },
  {
    icon: '✍️',
    title: '150文字のセリフ',
    desc: '短いからこそ光るセンス。150文字以内で最高の一言を考えよう。制限があるからこそ創造力が試される。',
    bg: 'rgba(255, 107, 107, 0.1)'
  },
  {
    icon: '❤️',
    title: 'いいね＆コメント',
    desc: '面白い回答にはいいねで応援。コメントで盛り上がろう。みんなの創造力を楽しもう。',
    bg: 'rgba(255, 165, 2, 0.1)'
  },
  {
    icon: '🏆',
    title: 'ランキング',
    desc: 'デイリー・ウィークリー・歴代ランキングで競い合い。あなたのセリフが1位に輝くかも。',
    bg: 'rgba(38, 222, 129, 0.1)'
  },
  {
    icon: '👥',
    title: 'フォロー＆つながり',
    desc: 'センスのあるユーザーをフォロー。フォローしている人の回答をタイムラインで楽しめる。',
    bg: 'rgba(108, 92, 231, 0.1)'
  },
  {
    icon: '🔥',
    title: 'トレンド',
    desc: '今バズっている回答をチェック。話題のお題や人気の回答をリアルタイムで発見。',
    bg: 'rgba(255, 107, 107, 0.1)'
  }
]
</script>

<style scoped>
.features {
  padding: 100px 0;
  background: #fff;
}

.features-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 32px;
  margin-top: 56px;
}

.feature-card {
  padding: 32px;
  border-radius: 16px;
  background: #fafafa;
  border: 1px solid #f0f0f0;
  transition: transform 0.2s, box-shadow 0.2s;
}

.feature-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 12px 32px rgba(0, 0, 0, 0.08);
}

.feature-icon {
  width: 56px;
  height: 56px;
  border-radius: 14px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 28px;
  margin-bottom: 20px;
}

.feature-card h3 {
  font-size: 18px;
  font-weight: 700;
  color: var(--text);
  margin-bottom: 10px;
}

.feature-card p {
  font-size: 14px;
  line-height: 1.7;
  color: var(--text-light);
}

@media (max-width: 768px) {
  .features {
    padding: 60px 0;
  }

  .features-grid {
    grid-template-columns: 1fr;
    gap: 20px;
    margin-top: 40px;
  }
}
</style>
