import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../models/lesson_model.dart';
import '../models/word_model.dart';
import 'auth_service.dart';

class LessonService {
  final AuthService _authService = AuthService();

  // 1. Lấy danh sách bài học (hỗ trợ lọc theo cấp độ N5, N4, N3... và tìm kiếm từ khóa)
  Future<List<LessonModel>> getLessons({String? level, String? query}) async {
    final queryParams = <String, String>{};
    if (level != null && level.isNotEmpty && level != 'All') {
      queryParams['level'] = level;
    }
    if (query != null && query.trim().isNotEmpty) {
      queryParams['query'] = query.trim();
    }

    final uri = Uri.parse('${AppConstants.baseUrl}/lessons').replace(
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );

    final token = await _authService.getToken();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List data = json['data'] ?? [];
      return data.map((item) => LessonModel.fromJson(item)).toList();
    } else {
      throw Exception('Không thể tải danh sách bài học: ${response.statusCode}');
    }
  }

  // 2. Lấy danh sách từ vựng thuộc 1 bài học
  Future<List<WordModel>> getLessonWords(String lessonId) async {
    final endpoint = '${AppConstants.baseUrl}/lessons/$lessonId/words';
    final token = await _authService.getToken();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final response = await http.get(Uri.parse(endpoint), headers: headers);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List data = json['data'] ?? [];
      return data.map((item) => WordModel.fromJson(item)).toList();
    } else {
      throw Exception('Không thể tải từ vựng: ${response.statusCode}');
    }
  }
}
