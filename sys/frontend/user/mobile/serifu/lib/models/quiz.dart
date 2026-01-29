class Quiz {
  final String id;
  final int number;
  final int totalQuizzes;
  final String title;
  final String situation;
  final String requirement;
  final int answerCount;

  const Quiz({
    required this.id,
    required this.number,
    required this.totalQuizzes,
    required this.title,
    required this.situation,
    required this.requirement,
    required this.answerCount,
  });
}

final List<Quiz> sampleQuizzes = [
  const Quiz(
    id: '1',
    number: 1,
    totalQuizzes: 5,
    title: '絶体絶命のヒーロー',
    situation: '悪の組織のボスに追い詰められ、武器も力も尽きた主人公。しかし、背後の仲間たちを守るためにゆっくりと立ち上がった。',
    requirement: '逆転の予感を感じさせる、最高にかっこいい「最後の一言」',
    answerCount: 1234,
  ),
  const Quiz(
    id: '2',
    number: 2,
    totalQuizzes: 5,
    title: '100年後の再会',
    situation: 'かつての恋人と、お互い幽霊（またはアンドロイド）になって100年ぶりに再会した。場所は廃墟となった思い出の公園。',
    requirement: '最初に口にする、切なくて少しシュールな「挨拶」',
    answerCount: 987,
  ),
  const Quiz(
    id: '3',
    number: 3,
    totalQuizzes: 5,
    title: '勇者の勘違い',
    situation: '魔王の城に乗り込んだ勇者。しかし、扉を開けたら魔王がパジャマ姿でカップラーメンを食べていた。',
    requirement: '気まずい空気の中で、勇者が振り絞って放った「第一声」',
    answerCount: 1456,
  ),
];
