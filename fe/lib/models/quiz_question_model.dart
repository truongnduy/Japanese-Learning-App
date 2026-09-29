class QuizQuestionModel {
  final String id;
  final String? lessonId;
  final String questionText;
  final String questionType;
  final List<String> options;
  final String? correctAnswer;
  final String? explanation;
  final int points;

  QuizQuestionModel({
    required this.id,
    this.lessonId,
    required this.questionText,
    this.questionType = 'multiple_choice',
    this.options = const [],
    this.correctAnswer,
    this.explanation,
    this.points = 10,
  });

  factory QuizQuestionModel.fromJson(Map<String, dynamic> json) {
    return QuizQuestionModel(
      id: json['id']?.toString() ?? '',
      lessonId: json['lesson_id']?.toString(),
      questionText: json['question_text'] ?? '',
      questionType: json['question_type'] ?? 'multiple_choice',
      options: (json['options'] as List?)?.map((e) => e.toString()).toList() ?? [],
      correctAnswer: json['correct_answer'],
      explanation: json['explanation'],
      points: json['points'] ?? 10,
    );
  }
}
