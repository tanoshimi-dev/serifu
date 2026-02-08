<template>
  <section id="download" class="cta">
    <div class="container">
      <div class="cta-card">
        <h2>さあ、あなたのセリフを<br />世界に届けよう。</h2>
        <p>毎日5つのお題があなたを待っています。<br />無料で今すぐはじめよう。</p>
        <div class="cta-buttons">
          <a href="#" class="store-btn">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M17.05 20.28c-.98.95-2.05.8-3.08.35-1.09-.46-2.09-.48-3.24 0-1.44.62-2.2.44-3.06-.35C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.8 1.18-.24 2.31-.93 3.57-.84 1.51.12 2.65.72 3.4 1.8-3.12 1.87-2.38 5.98.48 7.13-.57 1.5-1.31 2.99-2.54 4.09zM12.03 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25z"/></svg>
            <div>
              <span class="store-sub">Download on the</span>
              <span class="store-name">App Store</span>
            </div>
          </a>
          <a href="#" class="store-btn">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M3.609 1.814L13.792 12 3.61 22.186a.996.996 0 01-.61-.92V2.734a1 1 0 01.609-.92zm10.89 10.893l2.302 2.302-10.937 6.333 8.635-8.635zm3.199-3.199l2.302 2.302a1 1 0 010 1.38l-2.302 2.302L15.396 12l2.302-3.492zM5.864 2.658L16.8 9.001l-2.302 2.302L5.864 2.658z"/></svg>
            <div>
              <span class="store-sub">GET IT ON</span>
              <span class="store-name">Google Play</span>
            </div>
          </a>
        </div>
      </div>
    </div>
  </section>
</template>

<style scoped>
.cta {
  padding: 100px 0;
  background: #fff;
}

.cta-card {
  text-align: center;
  padding: 80px 40px;
  background: linear-gradient(135deg, var(--primary), #8b7ff0);
  border-radius: 24px;
  color: #fff;
}

.cta-card h2 {
  font-size: 36px;
  font-weight: 900;
  line-height: 1.4;
  margin-bottom: 16px;
}

.cta-card p {
  font-size: 16px;
  opacity: 0.9;
  line-height: 1.7;
  margin-bottom: 40px;
}

.cta-buttons {
  display: flex;
  gap: 16px;
  justify-content: center;
}

.store-btn {
  display: flex;
  align-items: center;
  gap: 12px;
  background: rgba(0, 0, 0, 0.3);
  color: #fff;
  text-decoration: none;
  padding: 14px 28px;
  border-radius: 12px;
  transition: background 0.2s, transform 0.2s;
}

.store-btn:hover {
  background: rgba(0, 0, 0, 0.5);
  transform: translateY(-2px);
}

.store-sub {
  display: block;
  font-size: 10px;
  opacity: 0.8;
  text-align: left;
}

.store-name {
  display: block;
  font-size: 16px;
  font-weight: 700;
  text-align: left;
}

@media (max-width: 768px) {
  .cta {
    padding: 60px 0;
  }

  .cta-card {
    padding: 48px 24px;
  }

  .cta-card h2 {
    font-size: 24px;
  }

  .cta-buttons {
    flex-direction: column;
    align-items: center;
  }

  .store-btn {
    width: 100%;
    max-width: 260px;
    justify-content: center;
  }
}
</style>
