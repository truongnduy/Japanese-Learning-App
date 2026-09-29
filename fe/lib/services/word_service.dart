import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../models/word_model.dart';
import 'auth_service.dart';

class WordService {
  final AuthService _authService = AuthService();

  /// Tạo từ vựng / flashcard mới (POST /api/v1/words)
  Future<WordModel> createWord({
    required String kanji,
    required String vietnameseMeaning,
    required int difficultyLevel,
    String? hiragana,
    String? romaji,
    String? exampleSentence,
    String? exampleMeaning,
    String? lessonId,
  }) async {
    final endpoint = '${AppConstants.baseUrl}/words';
    final token = await _authService.getToken();

    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final Map<String, dynamic> wordData = {
      'kanji': kanji.trim(),
      'vietnamese_meaning': vietnameseMeaning.trim(),
      'difficulty_level': difficultyLevel,
    };

    if (hiragana != null && hiragana.trim().isNotEmpty) {
      wordData['hiragana'] = hiragana.trim();
    }
    if (romaji != null && romaji.trim().isNotEmpty) {
      wordData['romaji'] = romaji.trim();
    }
    if (exampleSentence != null && exampleSentence.trim().isNotEmpty) {
      wordData['example_sentence'] = exampleSentence.trim();
    }
    if (exampleMeaning != null && exampleMeaning.trim().isNotEmpty) {
      wordData['example_meaning'] = exampleMeaning.trim();
    }
    if (lessonId != null && lessonId.isNotEmpty) {
      wordData['lesson_id'] = lessonId;
    }

    final response = await http.post(
      Uri.parse(endpoint),
      headers: headers,
      body: jsonEncode({'word': wordData}),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return WordModel.fromJson(json['data'] ?? json);
    } else {
      final body = jsonDecode(response.body);
      final errorMsg = body['errors'] != null
          ? (body['errors'] as List).join(', ')
          : (body['error'] ?? 'Lỗi khi tạo từ vựng: ${response.statusCode}');
      throw Exception(errorMsg);
    }
  }

  /// Đánh dấu đã học từ / ôn tập từ (POST /api/v1/words/:id/study)
  Future<Map<String, dynamic>> markWordStudied(String wordId) async {
    final endpoint = '${AppConstants.baseUrl}/words/$wordId/study';
    final token = await _authService.getToken();

    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final response = await http.post(Uri.parse(endpoint), headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Không thể cập nhật tiến độ học: ${response.statusCode}');
    }
  }
}
