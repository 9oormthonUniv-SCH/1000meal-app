import 'package:flutter/material.dart';

import '../../../common/dio/api_error_mapper.dart';
import '../../../common/dio/api_exception.dart';
import '../../../common/storage/login_preference_storage.dart';
import '../models/role.dart';
import '../repositories/auth_repository.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthRepository _repo;
  final LoginPreferenceStorage _prefs;

  LoginViewModel(this._repo, this._prefs);

  Role role = Role.student;
  String userId = '';
  String password = '';

  bool saveUserIdOption = false;
  bool autoLoginOption = false;

  bool loading = false;
  String? errorMessage;
  bool _loaded = false;

  void setRole(Role v) {
    role = v;
    notifyListeners();
  }

  void setUserId(String v) {
    userId = v;
    notifyListeners();
  }

  void setPassword(String v) {
    password = v;
    notifyListeners();
  }

  void setSaveUserIdOption(bool v) {
    saveUserIdOption = v;
    notifyListeners();
  }

  void setAutoLoginOption(bool v) {
    autoLoginOption = v;
    notifyListeners();
  }

  bool get canSubmit => !loading && userId.trim().isNotEmpty && password.isNotEmpty;

  /// 저장된 아이디/자동 로그인 설정 로드. 로그인 화면 진입 시 한 번 호출.
  Future<void> loadSavedPreferences() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final data = await _prefs.load();
      if (data.savedUserId != null && data.savedUserId!.isNotEmpty) {
        userId = data.savedUserId!;
        if (data.savedRoleKey == 'admin') {
          role = Role.admin;
        } else {
          role = Role.student;
        }
      }
      saveUserIdOption = data.saveUserId;
      autoLoginOption = data.autoLogin;
      if (data.savedPassword != null && data.savedPassword!.isNotEmpty) {
        password = data.savedPassword!;
      }
      notifyListeners();
    } catch (_) {
      // ignore
    }
  }

  /// 로그아웃 후 true. 로그인 성공 전까지 자동 로그인 건너뜀.
  Future<bool> shouldSkipAutoLoginThisTime() async {
    return _prefs.getSkipAutoLoginOnce();
  }

  /// 성공 시 role 반환(라우팅 분기용)
  Future<Role?> submit() async {
    if (!canSubmit) return null;
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final meRole = await _repo.login(role: role, userId: userId.trim(), password: password);
      if (meRole != null) {
        try {
          final roleKey = role == Role.admin ? 'admin' : 'student';
          await _prefs.saveAfterLogin(
            saveUserId: saveUserIdOption,
            autoLogin: autoLoginOption,
            userId: userId.trim(),
            roleKey: roleKey,
            password: password,
          );
          await _prefs.clearSkipAutoLoginOnce();
        } catch (_) {
          // 아이디/자동 로그인 저장 실패해도 로그인 성공은 유지
        }
      }
      return meRole;
    } catch (e) {
      if (e is ApiException) {
        errorMessage = mapErrorToMessage(e, responseData: e.details);
      } else {
        errorMessage = '로그인에 실패했습니다.';
      }
      return null;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
