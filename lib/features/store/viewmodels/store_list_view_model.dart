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
  final Set<int> _favoriteUpdating = {};

  bool isFavoriteUpdating(int storeId) => _favoriteUpdating.contains(storeId);

  Future<void> load() async {
    if (loading) return;
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final list = await _repo.getStoreList();
      try {
        final favoriteIds = await _repo.getFavoriteStoreIds();
        final favoriteSet = favoriteIds.toSet();
        items = list
            .map((s) => s.copyWith(isFavorite: favoriteSet.contains(s.id)))
            .toList(growable: false);
      } catch (_) {
        items = list;
      }
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

  Future<void> toggleFavorite(StoreListItem store) async {
    final storeId = store.id;
    if (_favoriteUpdating.contains(storeId)) return;
    _favoriteUpdating.add(storeId);
    errorMessage = null;

    final prev = store.isFavorite;
    _updateFavoriteLocal(storeId, !prev);
    notifyListeners();

    try {
      if (prev) {
        final res = await _repo.unfavoriteStore(storeId);
        _updateFavoriteLocal(storeId, res.favorite);
      } else {
        final res = await _repo.favoriteStore(storeId);
        _updateFavoriteLocal(storeId, res.favorite);
      }
    } catch (e) {
      _updateFavoriteLocal(storeId, prev);
      if (e is ApiException) {
        errorMessage = mapErrorToMessage(e, responseData: e.details);
      } else {
        errorMessage = '즐겨찾기 처리에 실패했습니다.';
      }
    } finally {
      _favoriteUpdating.remove(storeId);
      notifyListeners();
    }
  }

  void _updateFavoriteLocal(int storeId, bool isFavorite) {
    items = items
        .map((s) => s.id == storeId ? s.copyWith(isFavorite: isFavorite) : s)
        .toList(growable: false);
  }
}
