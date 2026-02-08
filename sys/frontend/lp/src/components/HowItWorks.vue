<template>
  <section id="how-it-works" class="how-it-works">
    <div class="container">
      <p class="section-badge">How It Works</p>
      <h2 class="section-title">3ステップで簡単</h2>
      <p class="section-desc">毎日の大喜利習慣を始めよう</p>
      <div class="steps">
        <div class="step" v-for="(step, i) in steps" :key="i">
          <div class="step-number">{{ i + 1 }}</div>
          <div class="step-content">
            <h3>{{ step.title }}</h3>
            <p>{{ step.desc }}</p>
          </div>
          <div class="step-visual">{{ step.icon }}</div>
        </div>
      </div>
    </div>
  </section>
</template>

<script setup>
const steps = [
  {
    title: 'お題をチェック',
    desc: '毎朝届く5つのお題から、気になるシチュエーションを選ぼう。日常、恋愛、仕事など多彩なジャンル。',
    icon: '📋'
  },
  {
    title: 'セリフを投稿',
    desc: 'そのシチュエーションで最高に面白い一言を150文字以内で書こう。短いからこそセンスが光る。',
    icon: '💬'
  },
  {
    title: 'みんなと楽しむ',
    desc: '他のユーザーの回答を読んで、いいねやコメントで盛り上がろう。ランキングで実力を競い合い。',
    icon: '🎉'
  }
]
</script>

<style scoped>
.how-it-works {
  padding: 100px 0;
  background: linear-gradient(180deg, #f8f7ff 0%, #fff 100%);
}

.steps {
  display: flex;
  flex-direction: column;
  gap: 32px;
  margin-top: 56px;
  max-width: 700px;
  margin-left: auto;
  margin-right: auto;
}

.step {
  display: flex;
  align-items: center;
  gap: 24px;
  padding: 32px;
  background: #fff;
  border-radius: 16px;
  border: 1px solid #f0f0f0;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.04);
}

.step-number {
  flex-shrink: 0;
  width: 48px;
  height: 48px;
  border-radius: 50%;
  background: linear-gradient(135deg, var(--primary), var(--secondary));
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 20px;
  font-weight: 900;
}

.step-content {
  flex: 1;
}

.step-content h3 {
  font-size: 18px;
  font-weight: 700;
  color: var(--text);
  margin-bottom: 6px;
}

.step-content p {
  font-size: 14px;
  line-height: 1.7;
  color: var(--text-light);
}

.step-visual {
  flex-shrink: 0;
  font-size: 40px;
}

@media (max-width: 768px) {
  .how-it-works {
    padding: 60px 0;
  }

  .step {
    padding: 24px;
  }

  .step-visual {
    display: none;
  }
}
</style>
