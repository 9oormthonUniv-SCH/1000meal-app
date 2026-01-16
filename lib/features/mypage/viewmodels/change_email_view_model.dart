import 'package:flutter/foundation.dart';

import '../../../common/dio/api_exception.dart';
import '../../../common/dio/api_error_mapper.dart';
import '../../auth/repositories/auth_repository.dart';

class ChangeEmailViewModel extends ChangeNotifier {
  ChangeEmailViewModel(this._repo);

  final AuthRepository _repo;

  bool loading = false;
  String? errMsg;

  String currentEmail = '';
  String password = '';
  String newEmail = '';
  String code = '';

  String? changeId;

  bool step1Done = false;
  bool step2Done = false;
  bool verified = false;

  Future<void> load() async {
    errMsg = null;
    notifyListeners();
    try {
      final me = await _repo.getMe();
      currentEmail = me.email;
      notifyListeners();
    } catch (e) {
      if (e is ApiException) {
        errMsg = mapErrorToMessage(e, responseData: e.details);
      } else {
        errMsg = '불러오기에 실패했습니다.';
      }
      notifyListeners();
    }
  }

  void setPassword(String v) {
    password = v;
    notifyListeners();
  }

  void setNewEmail(String v) {
    newEmail = v;
    notifyListeners();
  }

  void setCode(String v) {
    code = v;
    notifyListeners();
  }

  bool get isValidNewEmail => newEmail.trim().endsWith('@sch.ac.kr');

  Future<void> verifyPassword() async {
    if (loading) return;
    loading = true;
    errMsg = null;
    notifyListeners();
    try {
      final res = await _repo.startEmailChange(currentEmail: currentEmail, password: password);
      changeId = res.changeId;
      step1Done = true;
    } catch (e) {
      if (e is ApiException) {
        errMsg = mapErrorToMessage(e, responseData: e.details);
      } else {
        errMsg = '비밀번호 확인 실패';
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> sendCode() async {
    if (loading) return;
    if (changeId == null) return;

    if (!isValidNewEmail) {
      errMsg = '이메일은 반드시 @sch.ac.kr 형식이어야 합니다.';
      notifyListeners();
      return;
    }

    loading = true;
    errMsg = null;
    notifyListeners();
    try {
      await _repo.sendEmailChangeCode(changeId: changeId!, newEmail: newEmail.trim());
      step2Done = true;
    } catch (e) {
      if (e is ApiException) {
        errMsg = mapErrorToMessage(e, responseData: e.details);
      } else {
        errMsg = '인증 요청 실패';
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> verifyCode() async {
    if (loading) return;
    if (changeId == null) return;

    loading = true;
    errMsg = null;
    notifyListeners();
    try {
      await _repo.verifyEmailChange(changeId: changeId!, code: code.trim());
      verified = true;
    } catch (e) {
      if (e is ApiException) {
        errMsg = mapErrorToMessage(e, responseData: e.details);
      } else {
        errMsg = '코드 검증 실패';
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// true면 /mypage로 이동, false면 /login 유도(웹과 동일)
  Future<bool> finalizeAndRefreshMe() async {
    try {
      await _repo.getMe();
      return true;
    } catch (_) {
      return false;
    }
  }
}


