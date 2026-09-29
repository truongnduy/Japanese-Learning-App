class LessonModel {
  final String id;
  final String title;
  final String? description;
  final String level; // N5, N4, N3, N2, N1
  final int order;
  final int totalWords;
  final int totalQuestions;

  LessonModel({
    required this.id,
    required this.title,
    this.description,
    required this.level,
    required this.order,
    required this.totalWords,
    required this.totalQuestions,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      level: json['level'] ?? 'N5',
      order: json['order'] is int
          ? json['order']
          : int.tryParse(json['order']?.toString() ?? '1') ?? 1,
      totalWords: json['total_words'] ?? 0,
      totalQuestions: json['total_questions'] ?? 0,
    );
  }
}
