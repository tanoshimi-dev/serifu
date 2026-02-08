<template>
  <section id="categories" class="categories">
    <div class="container">
      <p class="section-badge">Categories</p>
      <h2 class="section-title">多彩なカテゴリ</h2>
      <p class="section-desc">あらゆるシチュエーションから面白いセリフが生まれる</p>
      <div class="categories-grid">
        <div class="category-card" v-for="cat in categories" :key="cat.name" :style="{ borderColor: cat.color + '40' }">
          <span class="category-icon">{{ cat.icon }}</span>
          <span class="category-name">{{ cat.name }}</span>
        </div>
      </div>
    </div>
  </section>
</template>

<script setup>
const categories = [
  { name: '日常', icon: '☀️', color: '#FFA502' },
  { name: '仕事', icon: '💼', color: '#6C5CE7' },
  { name: '恋愛', icon: '💕', color: '#FF6B6B' },
  { name: '友達', icon: '🤝', color: '#26DE81' },
  { name: '家族', icon: '🏠', color: '#FFA502' },
  { name: 'ユーモア', icon: '😂', color: '#FF6B6B' },
  { name: '哲学', icon: '🤔', color: '#6C5CE7' },
  { name: 'やる気', icon: '🔥', color: '#26DE81' }
]
</script>

<style scoped>
.categories {
  padding: 100px 0;
  background: #fff;
}

.categories-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 20px;
  margin-top: 56px;
}

.category-card {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 20px 24px;
  border-radius: 14px;
  background: #fafafa;
  border: 2px solid #f0f0f0;
  transition: transform 0.2s, box-shadow 0.2s;
  cursor: default;
}

.category-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.06);
}

.category-icon {
  font-size: 28px;
}

.category-name {
  font-size: 16px;
  font-weight: 600;
  color: var(--text);
}

@media (max-width: 768px) {
  .categories {
    padding: 60px 0;
  }

  .categories-grid {
    grid-template-columns: repeat(2, 1fr);
    gap: 14px;
    margin-top: 40px;
  }
}
</style>
