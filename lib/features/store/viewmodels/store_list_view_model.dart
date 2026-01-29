import 'package:flutter/foundation.dart';

import '../../../common/dio/api_error_mapper.dart';
import '../../../common/dio/api_exception.dart';
import '../models/store_models.dart';
import '../repositories/store_repository.dart';

class StoreListViewModel extends ChangeNotifier {
  StoreListViewModel(this._repo);

  final StoreRepository _repo;

  bool loading = false;
  String? errorMessage;
  List<StoreListItem> items = [];

  Future<void> load() async {
    if (loading) return;
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      items = await _repo.getStoreList();
    } catch (e) {
      if (e is ApiException) {
        errorMessage = mapErrorToMessage(e, responseData: e.details);
      } else {
        errorMessage = '매장 목록을 불러오지 못했습니다.';
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
