import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';

  // 1. Lưu token vào máy
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // 2. Lấy token đã lưu
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // 3. Xóa token khi Đăng xuất
  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // 4. Gọi API Đăng nhập
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('${AppConstants.baseUrl}/auth/login');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final token = data['token'];
      await saveToken(token);
      final user = UserModel.fromJson(data['user']);
      return {'success': true, 'user': user, 'token': token};
    } else {
      return {
        'success': false,
        'message': data['message'] ?? 'Đăng nhập không thành công',
      };
    }
  }

  // 5. Gọi API Đăng ký
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final url = Uri.parse('${AppConstants.baseUrl}/auth/register');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'user': {
          'name': name.trim(),
          'email': email.trim(),
          'password': password,
          'password_confirmation': passwordConfirmation,
          'role': 'student',
        }
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      final token = data['token'];
      await saveToken(token);
      final user = UserModel.fromJson(data['user']);
      return {'success': true, 'user': user, 'token': token};
    } else {
      final errors = data['errors'] is List ? (data['errors'] as List).join(', ') : data['message'];
      return {
        'success': false,
        'message': errors ?? 'Đăng ký tài khoản thất bại',
      };
    }
  }

  // 6. Lấy thông tin user hiện tại qua Token (tự động đăng nhập khi mở app)
  Future<UserModel?> getCurrentUser() async {
    final token = await getToken();
    if (token == null) return null;

    final url = Uri.parse('${AppConstants.baseUrl}/auth/me');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return UserModel.fromJson(data['user']);
    } else {
      await removeToken();
      return null;
    }
  }
}
