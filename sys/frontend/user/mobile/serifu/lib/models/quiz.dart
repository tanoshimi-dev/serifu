class Quiz {
  final String id;
  final String title;
  final String description;
  final String requirement;
  final String? categoryId;
  final Category? category;
  final DateTime releaseDate;
  final String status;
  final int answerCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Quiz({
    required this.id,
    required this.title,
    required this.description,
    required this.requirement,
    this.categoryId,
    this.category,
    required this.releaseDate,
    required this.status,
    required this.answerCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      requirement: json['requirement'] as String? ?? '',
      categoryId: json['category_id'] as String?,
      category: json['category'] != null
          ? Category.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      releaseDate: DateTime.parse(json['release_date'] as String),
      status: json['status'] as String,
      answerCount: json['answer_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'requirement': requirement,
        'category_id': categoryId,
        'release_date': releaseDate.toIso8601String(),
        'status': status,
      };
}

class Category {
  final String id;
  final String name;
  final String? description;
  final String? icon;
  final String? color;
  final int sortOrder;
  final String status;

  const Category({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    this.color,
    required this.sortOrder,
    required this.status,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      status: json['status'] as String? ?? 'active',
    );
  }
}
