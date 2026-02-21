import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  static const String _envFile = 'assets/env/.env';

  static Future<void> load() async {
    await dotenv.load(fileName: _envFile);
  }

  static String get apiBaseUrl {
    final raw = dotenv.env['NEXT_PUBLIC_API_URL']?.trim();
    if (raw == null || raw.isEmpty) {
      throw StateError('NEXT_PUBLIC_API_URL is missing in $_envFile');
    }
    final normalized = raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
    return '$normalized/api/v1';
  }

  /// 앱 다운로드/소개 고정 URL. QR이 이 base로 시작하고 qrToken 파라미터가 있으면 인앱 명부 등록 플로우.
  static String? get appDownloadUrlBase {
    final raw = dotenv.env['APP_DOWNLOAD_URL']?.trim();
    if (raw == null || raw.isEmpty) return null;
    return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
  }
}


