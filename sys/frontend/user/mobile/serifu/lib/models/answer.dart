class Answer {
  final String id;
  final String quizId;
  final String username;
  final String avatarInitial;
  final String text;
  final int likes;
  final int comments;
  final String? topComment;

  const Answer({
    required this.id,
    required this.quizId,
    required this.username,
    required this.avatarInitial,
    required this.text,
    required this.likes,
    required this.comments,
    this.topComment,
  });
}

final List<Answer> sampleAnswers = [
  const Answer(
    id: '1',
    quizId: '1',
    username: '@username_123',
    avatarInitial: 'U',
    text: '「終わりだと？いいや、これからがショータイムだ」',
    likes: 156,
    comments: 23,
    topComment: 'すごいかっこいい！映画みたい',
  ),
  const Answer(
    id: '2',
    quizId: '1',
    username: '@cool_writer',
    avatarInitial: 'C',
    text: '「悪党よ、俺の怒りを見せてやる！最後の力を振り絞る！」',
    likes: 89,
    comments: 15,
  ),
  const Answer(
    id: '3',
    quizId: '1',
    username: '@story_master',
    avatarInitial: 'S',
    text: '「まだだ...まだ終わらせない。仲間を守るため、俺はまだ立つ！」',
    likes: 67,
    comments: 8,
  ),
];
