import 'package:flutter/foundation.dart';

import '../../../common/dio/api_error_mapper.dart';
import '../../../common/dio/api_exception.dart';
import '../models/store_models.dart';
import '../repositories/store_repository.dart';

class StoreDetailViewModel extends ChangeNotifier {
  StoreDetailViewModel(this._repo, this.storeId);

  final StoreRepository _repo;
  final int storeId;

  bool loading = false;
  String? errorMessage;
  StoreDetail? detail;
  List<StoreListItem> otherStores = [];

  Future<void> load() async {
    if (loading) return;
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      detail = await _repo.getStoreDetail(storeId);
      try {
        final list = await _repo.getStoreList();
        otherStores = list.where((store) => store.id != storeId).toList();
      } catch (_) {
        otherStores = [];
      }
    } catch (e) {
      if (e is ApiException) {
        errorMessage = mapErrorToMessage(e, responseData: e.details);
      } else {
        errorMessage = '매장 정보를 불러오지 못했습니다.';
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
