<script setup>
import { ref } from 'vue'

const menuOpen = ref(false)
</script>

<template>
  <header class="header">
    <div class="container header-inner">
      <a href="#" class="logo">
        <span class="logo-icon">🎭</span>
        <span class="logo-text">セリフ</span>
      </a>
      <nav class="nav" :class="{ open: menuOpen }">
        <a href="#features" @click="menuOpen = false">特徴</a>
        <a href="#how-it-works" @click="menuOpen = false">使い方</a>
        <a href="#categories" @click="menuOpen = false">カテゴリ</a>
        <a href="#download" class="nav-cta" @click="menuOpen = false">アプリを入手</a>
      </nav>
      <button class="menu-toggle" @click="menuOpen = !menuOpen" :aria-label="menuOpen ? 'メニューを閉じる' : 'メニューを開く'">
        <span :class="{ open: menuOpen }"></span>
      </button>
    </div>
  </header>
</template>

<style scoped>
.header {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  z-index: 100;
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(10px);
  border-bottom: 1px solid rgba(0, 0, 0, 0.06);
}

.header-inner {
  display: flex;
  align-items: center;
  justify-content: space-between;
  height: 64px;
}

.logo {
  display: flex;
  align-items: center;
  gap: 8px;
  text-decoration: none;
  color: var(--text);
}

.logo-icon {
  font-size: 28px;
}

.logo-text {
  font-size: 22px;
  font-weight: 900;
  background: linear-gradient(135deg, var(--primary), var(--secondary));
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.nav {
  display: flex;
  align-items: center;
  gap: 32px;
}

.nav a {
  text-decoration: none;
  color: var(--text-light);
  font-size: 14px;
  font-weight: 500;
  transition: color 0.2s;
}

.nav a:hover {
  color: var(--primary);
}

.nav-cta {
  background: var(--primary);
  color: #fff !important;
  padding: 8px 20px;
  border-radius: 20px;
  font-weight: 600 !important;
  transition: background 0.2s, transform 0.2s !important;
}

.nav-cta:hover {
  background: var(--primary-dark) !important;
  transform: translateY(-1px);
}

.menu-toggle {
  display: none;
  background: none;
  border: none;
  cursor: pointer;
  width: 32px;
  height: 32px;
  position: relative;
}

.menu-toggle span,
.menu-toggle span::before,
.menu-toggle span::after {
  display: block;
  width: 24px;
  height: 2px;
  background: var(--text);
  position: absolute;
  transition: 0.3s;
  left: 4px;
}

.menu-toggle span {
  top: 15px;
}

.menu-toggle span::before {
  content: '';
  top: -7px;
}

.menu-toggle span::after {
  content: '';
  top: 7px;
}

.menu-toggle span.open {
  background: transparent;
}

.menu-toggle span.open::before {
  top: 0;
  transform: rotate(45deg);
}

.menu-toggle span.open::after {
  top: 0;
  transform: rotate(-45deg);
}

@media (max-width: 768px) {
  .menu-toggle {
    display: block;
  }

  .nav {
    position: fixed;
    top: 64px;
    left: 0;
    right: 0;
    background: #fff;
    flex-direction: column;
    padding: 24px;
    gap: 20px;
    border-bottom: 1px solid rgba(0, 0, 0, 0.06);
    transform: translateY(-120%);
    transition: transform 0.3s;
  }

  .nav.open {
    transform: translateY(0);
  }

  .nav a {
    font-size: 16px;
  }
}
</style>
