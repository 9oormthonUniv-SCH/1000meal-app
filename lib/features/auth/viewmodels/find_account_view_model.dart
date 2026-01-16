import 'package:flutter/material.dart';

import '../../../common/dio/api_error_mapper.dart';
import '../../../common/dio/api_exception.dart';
import '../models/account_recovery_models.dart';
import '../repositories/auth_repository.dart';

enum FindAccountTab { id, pw }

class FindAccountViewModel extends ChangeNotifier {
  FindAccountViewModel(this._repo);

  final AuthRepository _repo;

  FindAccountTab tab = FindAccountTab.id;

  bool loading = false;
  bool verifying = false;
  String? error;
  String? success;

  // Find ID
  String name = '';
  String email = '';
  String? foundUserId;

  // Reset password
  String resetEmail = '';
  String token = '';
  String newPw = '';
  String newPw2 = '';
  bool emailSent = false;

  void initTabFromArgs(Object? args) {
    if (args is String && args == 'pw') {
      tab = FindAccountTab.pw;
    } else {
      tab = FindAccountTab.id;
    }
    notifyListeners();
  }

  void setTab(FindAccountTab v) {
    tab = v;
    error = null;
    success = null;
    foundUserId = null;
    notifyListeners();
  }

  void setName(String v) {
    name = v;
    notifyListeners();
  }

  void setEmail(String v) {
    email = v;
    notifyListeners();
  }

  Future<void> findId() async {
    if (loading) return;
    loading = true;
    error = null;
    success = null;
    foundUserId = null;
    notifyListeners();
    try {
      final res = await _repo.findUserId(name: name.trim(), email: email.trim());
      foundUserId = res.userId;
    } catch (e) {
      error = e is ApiException ? mapErrorToMessage(e, responseData: e.details) : '아이디를 찾을 수 없습니다.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void setResetEmail(String v) {
    resetEmail = v;
    notifyListeners();
  }

  void setToken(String v) {
    token = v;
    notifyListeners();
  }

  void setNewPw(String v) {
    newPw = v;
    notifyListeners();
  }

  void setNewPw2(String v) {
    newPw2 = v;
    notifyListeners();
  }

  Future<void> requestResetEmail() async {
    if (loading) return;
    loading = true;
    error = null;
    success = null;
    notifyListeners();
    try {
      await _repo.resetPasswordRequest(resetEmail.trim());
      emailSent = true;
      success = '인증 메일이 발송되었습니다.';
    } catch (e) {
      error = e is ApiException ? mapErrorToMessage(e, responseData: e.details) : '메일 발송 실패';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> confirmResetPassword() async {
    if (verifying) return;
    error = null;
    success = null;
    if (newPw != newPw2) {
      error = '비밀번호가 일치하지 않습니다.';
      notifyListeners();
      return;
    }
    verifying = true;
    notifyListeners();
    try {
      await _repo.resetPasswordConfirm(
        ResetPasswordConfirmRequest(
          email: resetEmail.trim(),
          token: token.trim(),
          newPassword: newPw,
          confirmPassword: newPw2,
        ),
      );
      success = '비밀번호가 변경되었습니다.';
    } catch (e) {
      error = e is ApiException ? mapErrorToMessage(e, responseData: e.details) : '재설정 실패';
    } finally {
      verifying = false;
      notifyListeners();
    }
  }
}


