import 'package:flutter/material.dart';

class AppColors {
  // Màu chủ đạo: Đỏ Crimson Nhật Bản sang trọng (Theo chuẩn Stitch)
  static const Color primary = Color(0xFF9E1C1C);
  static const Color primaryLight = Color(0xFFC62828);
  static const Color primaryDark = Color(0xFF7F1313);

  // Màu phụ & Trạng thái SRS
  static const Color secondary = Color(0xFF1E3A8A); // Xanh Indigo trầm
  static const Color secondaryLight = Color(0xFF2563EB);
  static const Color accentMatcha = Color(0xFF2E7D32); // Xanh Matcha (Đã thuộc / Passed)
  static const Color accentMatchaLight = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFE65100); // Cam SRS Level 2
  static const Color warning = Color(0xFFF59E0B);
  static const Color infoBlue = Color(0xFF0284C7); // Xanh dương đang học dở

  // Màu nền & Trung tính: Tông ấm nhẹ nhàng, tránh mỏi mắt
  static const Color background = Color(0xFFFAF8F5); // Trắng kem Nhật Bản
  static const Color surface = Colors.white;
  static const Color cardBg = Colors.white;
  static const Color textPrimary = Color(0xFF1E293B); // Đen than thanh lịch
  static const Color textSecondary = Color(0xFF64748B); // Xám Slate
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);

  // Trạng thái Quiz & Thông báo
  static const Color success = Color(0xFF2E7D32);
  static const Color error = Color(0xFFDC2626);
}
