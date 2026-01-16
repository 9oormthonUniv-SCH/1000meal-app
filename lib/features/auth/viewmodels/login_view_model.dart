import 'package:flutter/material.dart';

import '../../../common/dio/api_error_mapper.dart';
import '../../../common/dio/api_exception.dart';
import '../models/role.dart';
import '../repositories/auth_repository.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthRepository _repo;

  LoginViewModel(this._repo);

  Role role = Role.student;
  String userId = '';
  String password = '';

  bool loading = false;
  String? errorMessage;

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

  bool get canSubmit => !loading && userId.trim().isNotEmpty && password.isNotEmpty;

  /// 성공 시 role 반환(라우팅 분기용)
  Future<Role?> submit() async {
    if (!canSubmit) return null;
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final meRole = await _repo.login(role: role, userId: userId.trim(), password: password);
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
