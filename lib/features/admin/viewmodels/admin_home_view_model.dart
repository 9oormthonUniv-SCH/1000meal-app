import 'package:flutter/foundation.dart';

import '../../auth/repositories/auth_repository.dart';
import '../../users/models/me_response.dart';
import '../../../common/dio/api_error_mapper.dart';
import '../../../common/dio/api_exception.dart';
import '../data/admin_api.dart';
import '../models/store_models.dart';

class AdminHomeViewModel extends ChangeNotifier {
  AdminHomeViewModel(this._repo, this._adminApi);

  final AuthRepository _repo;
  final AdminApi _adminApi;

  bool loading = false;
  String? errorMessage;
  MeResponse? me;
  StoreDetail? store;
  bool isOpen = false;
  bool toggling = false;

  Future<void> load() async {
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      me = await _repo.getMe();
      final token = await _repo.getAccessToken();
      final storeId = me?.storeId;
      if (token == null || token.isEmpty) throw ApiException('로그인이 필요합니다.');
      if (storeId == null) throw ApiException('가게 정보가 없습니다.');

      store = await _adminApi.getStoreDetail(storeId: storeId, token: token);
      isOpen = store?.open ?? false;
    } catch (e) {
      if (e is ApiException) {
        errorMessage = mapErrorToMessage(e, responseData: e.details);
      } else {
        errorMessage = '불러오기에 실패했습니다.';
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> toggleOpen() async {
    if (toggling) return;
    final token = await _repo.getAccessToken();
    final storeId = me?.storeId;
    if (token == null || token.isEmpty || storeId == null) {
      errorMessage = '로그인이 필요합니다.';
      notifyListeners();
      return;
    }

    toggling = true;
    errorMessage = null;
    final prev = isOpen;
    isOpen = !isOpen; // optimistic
    notifyListeners();

    try {
      await _adminApi.toggleStoreStatus(storeId: storeId, token: token);
    } catch (e) {
      // rollback
      isOpen = prev;
      if (e is ApiException) {
        errorMessage = mapErrorToMessage(e, responseData: e.details);
      } else {
        errorMessage = '영업 상태 변경에 실패했습니다.';
      }
    } finally {
      toggling = false;
      notifyListeners();
    }
  }
}


