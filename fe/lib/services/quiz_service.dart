import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../models/quiz_question_model.dart';
import 'auth_service.dart';

class QuizService {
  final AuthService _authService = AuthService();

  /// Lấy danh sách câu hỏi trắc nghiệm của 1 bài học
  Future<List<QuizQuestionModel>> getLessonQuestions(String lessonId) async {
    final endpoint = '${AppConstants.baseUrl}/lessons/$lessonId/quiz_questions';
    final token = await _authService.getToken();

    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final response = await http.get(Uri.parse(endpoint), headers: headers);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List data = json['data'] ?? [];
      return data.map((item) => QuizQuestionModel.fromJson(item)).toList();
    } else {
      throw Exception('Không thể tải câu hỏi trắc nghiệm: ${response.statusCode}');
    }
  }

  /// Nộp bài trắc nghiệm và nhận đánh giá chi tiết
  Future<Map<String, dynamic>> submitQuiz({
    required String lessonId,
    required List<Map<String, dynamic>> answers,
  }) async {
    final endpoint = '${AppConstants.baseUrl}/quiz/submit';
    final token = await _authService.getToken();

    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final body = jsonEncode({
      'lesson_id': lessonId,
      'answers': answers,
    });

    final response = await http.post(
      Uri.parse(endpoint),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['error'] ?? 'Lỗi khi nộp bài: ${response.statusCode}');
    }
  }
}
