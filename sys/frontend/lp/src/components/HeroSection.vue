<template>
  <section class="hero">
    <div class="container hero-inner">
      <div class="hero-content">
        <p class="hero-badge">🎭 大喜利SNSアプリ</p>
        <h1 class="hero-title">
          毎日のお題に、<br />
          <span class="gradient-text">あなたのセリフ</span>を。
        </h1>
        <p class="hero-desc">
          AIが毎日届けるシチュエーションに、面白い一言で回答しよう。<br />
          150文字であなたのユーモアセンスが光る。
        </p>
        <div class="hero-actions">
          <a href="#download" class="btn btn-primary">
            <span>無料ではじめる</span>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="5" y1="12" x2="19" y2="12"/><polyline points="12 5 19 12 12 19"/></svg>
          </a>
          <a href="#how-it-works" class="btn btn-secondary">使い方を見る</a>
        </div>
        <div class="hero-stats">
          <div class="stat">
            <span class="stat-num">5</span>
            <span class="stat-label">毎日のお題</span>
          </div>
          <div class="stat-divider"></div>
          <div class="stat">
            <span class="stat-num">150</span>
            <span class="stat-label">文字の回答</span>
          </div>
          <div class="stat-divider"></div>
          <div class="stat">
            <span class="stat-num">8</span>
            <span class="stat-label">カテゴリ</span>
          </div>
        </div>
      </div>
      <div class="hero-image">
        <img src="/image/programmer.jpg" alt="セリフアプリのイラスト" />
      </div>
    </div>
  </section>
</template>

<style scoped>
.hero {
  padding: 120px 0 80px;
  background: linear-gradient(180deg, #f8f7ff 0%, #fff 100%);
  overflow: hidden;
}

.hero-inner {
  display: flex;
  align-items: center;
  gap: 60px;
}

.hero-content {
  flex: 1;
  min-width: 0;
}

.hero-badge {
  display: inline-block;
  background: rgba(108, 92, 231, 0.1);
  color: var(--primary);
  font-size: 14px;
  font-weight: 600;
  padding: 6px 16px;
  border-radius: 20px;
  margin-bottom: 24px;
}

.hero-title {
  font-size: 48px;
  font-weight: 900;
  line-height: 1.3;
  color: var(--text);
  margin-bottom: 20px;
}

.gradient-text {
  background: linear-gradient(135deg, var(--primary), var(--secondary));
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.hero-desc {
  font-size: 17px;
  line-height: 1.8;
  color: var(--text-light);
  margin-bottom: 36px;
}

.hero-actions {
  display: flex;
  gap: 16px;
  margin-bottom: 48px;
}

.hero-stats {
  display: flex;
  align-items: center;
  gap: 24px;
}

.stat {
  text-align: center;
}

.stat-num {
  display: block;
  font-size: 28px;
  font-weight: 900;
  color: var(--primary);
}

.stat-label {
  font-size: 13px;
  color: var(--text-light);
}

.stat-divider {
  width: 1px;
  height: 40px;
  background: #e0e0e0;
}

.hero-image {
  flex: 1;
  min-width: 0;
}

.hero-image img {
  width: 100%;
  height: auto;
  border-radius: 16px;
  filter: drop-shadow(0 20px 40px rgba(108, 92, 231, 0.15));
}

@media (max-width: 768px) {
  .hero {
    padding: 100px 0 60px;
  }

  .hero-inner {
    flex-direction: column;
    gap: 40px;
  }

  .hero-title {
    font-size: 32px;
  }

  .hero-desc br {
    display: none;
  }

  .hero-actions {
    flex-direction: column;
  }

  .hero-actions .btn {
    width: 100%;
    justify-content: center;
  }
}
</style>
