import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// iOS Keychain은 앱 삭제 후에도 보존된다(Apple 정책). 그래서 재설치한 사용자가
/// 만료된 access/refresh token을 그대로 복원받아 무한 로딩에 빠지는 문제가 있다.
///
/// SharedPreferences는 앱 삭제 시 함께 삭제되므로, 그 안에 "첫 실행 완료" 플래그를
/// 두면 재설치(=첫 실행)를 정확히 감지할 수 있다. 첫 실행이면 secure storage 전체를
/// 비워서 stale 토큰을 강제로 정리한다. 정상 업데이트(앱 삭제 X)에서는 SharedPreferences가
/// 보존되므로 플래그가 살아있어 영향 없다.
class AppBootstrap {
  static const _firstLaunchKey = 'app_first_launch_completed_v1';

  /// 앱 시작 시 main()에서 호출. SharedPreferences/Keychain 모두 5초 timeout으로
  /// 보호하여 어떤 환경에서도 hang 없음을 보장한다.
  static Future<void> clearStaleSecureStorageOnFirstLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 5),
      );
      final completed = prefs.getBool(_firstLaunchKey) ?? false;
      if (completed) return;

      // 재설치 / 첫 설치 — Keychain에 남아있을 stale token 모두 정리.
      const storage = FlutterSecureStorage();
      await storage.deleteAll().timeout(
        const Duration(seconds: 5),
        onTimeout: () {},
      );
      await prefs.setBool(_firstLaunchKey, true);

      if (kDebugMode) {
        debugPrint('[AppBootstrap] First launch detected — secure storage cleared.');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AppBootstrap] First-launch cleanup failed (continuing): $e');
      }
    }
  }
}
