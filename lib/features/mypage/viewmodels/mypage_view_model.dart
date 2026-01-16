import 'package:flutter/foundation.dart';

import '../../auth/repositories/auth_repository.dart';
import '../../users/models/me_response.dart';
import '../../../common/dio/api_exception.dart';
import '../../../common/dio/api_error_mapper.dart';

class MyPageViewModel extends ChangeNotifier {
  MyPageViewModel(this._repo);

  final AuthRepository _repo;

  MeResponse? me;
  bool loading = false;
  String? errorMessage;
  bool shouldRelogin = false;

  Future<void> load() async {
    loading = true;
    errorMessage = null;
    shouldRelogin = false;
    notifyListeners();

    try {
      me = await _repo.getMe();
    } catch (e) {
      if (e is ApiException) {
        // 토큰 만료/미보유 등은 로그인으로 유도
        if (e.statusCode == 401 || e.message.contains('로그인이 필요')) {
          shouldRelogin = true;
        }
        errorMessage = mapErrorToMessage(e, responseData: e.details);
      } else {
        errorMessage = '불러오기에 실패했습니다.';
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _repo.logout();
  }

  Future<bool> deleteAccount() async {
    loading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _repo.deleteAccount(currentPassword: '', agree: true);
      await _repo.logout();
      return true;
    } catch (e) {
      if (e is ApiException) {
        errorMessage = mapErrorToMessage(e, responseData: e.details);
      } else {
        errorMessage = '회원 탈퇴에 실패했습니다. 다시 시도해주세요.';
      }
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}


