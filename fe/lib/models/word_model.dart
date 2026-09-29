class WordModel {
  final String id;
  final String? lessonId;
  final String kanji;
  final String romaji;
  final String hiragana;
  final String vietnameseMeaning;
  final int difficultyLevel;
  final String? exampleSentence;
  final String? exampleMeaning;
  final String? audioUrl;
  final bool isMemorized;

  WordModel({
    required this.id,
    this.lessonId,
    required this.kanji,
    required this.romaji,
    required this.hiragana,
    required this.vietnameseMeaning,
    required this.difficultyLevel,
    this.exampleSentence,
    this.exampleMeaning,
    this.audioUrl,
    this.isMemorized = false,
  });

  factory WordModel.fromJson(Map<String, dynamic> json) {
    return WordModel(
      id: json['id']?.toString() ?? '',
      lessonId: json['lesson_id']?.toString(),
      kanji: json['kanji'] ?? '',
      romaji: json['romaji'] ?? '',
      hiragana: json['hiragana'] ?? '',
      vietnameseMeaning: json['vietnamese_meaning'] ?? json['meaning'] ?? '',
      difficultyLevel: json['difficulty_level'] ?? 1,
      exampleSentence: json['example_sentence'],
      exampleMeaning: json['example_meaning'],
      audioUrl: json['audio_url'],
      isMemorized: json['is_memorized'] ?? false,
    );
  }
}
