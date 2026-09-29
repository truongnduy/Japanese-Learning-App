import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AppConstants {
  /// Tự động nhận diện thiết bị:
  /// - Android Emulator: dùng 10.0.2.2 để kết nối về máy host Windows (nơi Rails chạy)
  /// - Web / Windows Desktop: dùng localhost
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api/v1';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api/v1';
    }
    return 'http://localhost:3000/api/v1';
  }

  static const String appTitle = 'Nihongo Learning';
}
