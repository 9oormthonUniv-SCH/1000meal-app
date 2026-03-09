import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 로그인 화면 "아이디 저장" / "자동 로그인" 설정 및 저장된 아이디·비밀번호 보관.
class LoginPreferenceStorage {
  static const _prefSaveId = 'login_save_id';
  static const _prefUserId = 'login_user_id';
  static const _prefRole = 'login_role';
  static const _prefAutoLogin = 'login_auto_login';
  static const _prefSkipAutoLoginOnce = 'login_skip_auto_login_once';
  static const _securePassword = 'login_password';

  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  Future<bool> getSaveUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefSaveId) ?? false;
  }

  Future<void> setSaveUserId(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefSaveId, value);
  }

  Future<bool> getAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefAutoLogin) ?? false;
  }

  Future<void> setAutoLogin(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefAutoLogin, value);
  }

  Future<String?> getSavedUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefUserId);
  }

  Future<String?> getSavedRoleKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefRole);
  }

  Future<String?> getSavedPassword() async => _secure.read(key: _securePassword);

  /// 로그아웃 시 true로 설정. 로그인 성공 전까지 자동 로그인 건너뜀. (초기화는 로그인 성공 시에만)
  Future<bool> getSkipAutoLoginOnce() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefSkipAutoLoginOnce) ?? false;
  }

  /// 로그인 성공 시 호출하여 자동 로그인 건너뛰기 플래그 해제.
  Future<void> clearSkipAutoLoginOnce() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefSkipAutoLoginOnce, false);
  }

  Future<void> setSkipAutoLoginOnce() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefSkipAutoLoginOnce, true);
  }

  /// 로그인 성공 시 호출: 아이디 저장/자동 로그인 옵션에 따라 저장.
  Future<void> saveAfterLogin({
    required bool saveUserId,
    required bool autoLogin,
    required String userId,
    required String roleKey,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefSaveId, saveUserId);
    await prefs.setBool(_prefAutoLogin, autoLogin);
    if (saveUserId) {
      await prefs.setString(_prefUserId, userId);
      await prefs.setString(_prefRole, roleKey);
    } else {
      await prefs.remove(_prefUserId);
      await prefs.remove(_prefRole);
    }
    if (autoLogin) {
      await _secure.write(key: _securePassword, value: password);
    } else {
      await _secure.delete(key: _securePassword);
    }
  }

  /// 저장된 값만 로드 (옵션 + 아이디/역할/비밀번호).
  Future<LoginSavedData> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saveId = prefs.getBool(_prefSaveId) ?? false;
    final autoLogin = prefs.getBool(_prefAutoLogin) ?? false;
    final userId = prefs.getString(_prefUserId);
    final roleKey = prefs.getString(_prefRole);
    final password = autoLogin ? await _secure.read(key: _securePassword) : null;
    return LoginSavedData(
      saveUserId: saveId,
      autoLogin: autoLogin,
      savedUserId: userId,
      savedRoleKey: roleKey,
      savedPassword: password,
    );
  }
}

class LoginSavedData {
  final bool saveUserId;
  final bool autoLogin;
  final String? savedUserId;
  final String? savedRoleKey;
  final String? savedPassword;

  LoginSavedData({
    required this.saveUserId,
    required this.autoLogin,
    this.savedUserId,
    this.savedRoleKey,
    this.savedPassword,
  });
}
