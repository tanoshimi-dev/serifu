<template>
  <footer class="footer">
    <div class="container footer-inner">
      <div class="footer-brand">
        <div class="footer-logo">
          <span>🎭</span>
          <span class="footer-logo-text">セリフ</span>
        </div>
        <p>毎日の大喜利で、あなたのセンスを見せつけろ。</p>
      </div>
      <div class="footer-links">
        <div class="footer-col">
          <h4>プロダクト</h4>
          <a href="#features">特徴</a>
          <a href="#how-it-works">使い方</a>
          <a href="#categories">カテゴリ</a>
        </div>
        <div class="footer-col">
          <h4>サポート</h4>
          <a href="#">お問い合わせ</a>
          <a href="#">プライバシーポリシー</a>
          <a href="#">利用規約</a>
        </div>
      </div>
    </div>
    <div class="container footer-bottom">
      <p>&copy; 2026 セリフ. All rights reserved.</p>
    </div>
  </footer>
</template>

<style scoped>
.footer {
  background: var(--text);
  color: #fff;
  padding: 60px 0 0;
}

.footer-inner {
  display: flex;
  justify-content: space-between;
  gap: 60px;
  padding-bottom: 40px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
}

.footer-logo {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 20px;
  margin-bottom: 12px;
}

.footer-logo-text {
  font-weight: 900;
}

.footer-brand p {
  font-size: 14px;
  color: rgba(255, 255, 255, 0.6);
  line-height: 1.6;
}

.footer-links {
  display: flex;
  gap: 60px;
}

.footer-col {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.footer-col h4 {
  font-size: 14px;
  font-weight: 700;
  margin-bottom: 4px;
}

.footer-col a {
  font-size: 14px;
  color: rgba(255, 255, 255, 0.6);
  text-decoration: none;
  transition: color 0.2s;
}

.footer-col a:hover {
  color: #fff;
}

.footer-bottom {
  padding: 20px 0;
}

.footer-bottom p {
  font-size: 13px;
  color: rgba(255, 255, 255, 0.4);
}

@media (max-width: 768px) {
  .footer {
    padding: 40px 0 0;
  }

  .footer-inner {
    flex-direction: column;
    gap: 32px;
  }

  .footer-links {
    gap: 40px;
  }
}
</style>
