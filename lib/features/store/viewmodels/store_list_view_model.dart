import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../common/dio/api_error_mapper.dart';
import '../../../common/dio/api_exception.dart';
import '../models/store_models.dart';
import '../repositories/store_repository.dart';

class StoreListViewModel extends ChangeNotifier {
  /// API 호출 및 즐겨찾기 동기화, 에러 처리까지 담당하는 내부 메서드
  Future<void> _fetchStoreList({bool isRefresh = false}) async {
    errorMessage = null;
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
        errorMessage = isRefresh
            ? '매장 목록을 새로고침하지 못했습니다.'
            : '매장 목록을 불러오지 못했습니다.';
      }
    }
    notifyListeners();
  }

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
    notifyListeners();
    try {
      await _fetchStoreList();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  DateTime? _lastRefreshTime; // 중복 새로고침 방지 (5초 이내 연타 방지)

  Future<void> refresh() async {
    final now = DateTime.now();
    if (_lastRefreshTime != null &&
        now.difference(_lastRefreshTime!) < const Duration(seconds: 1)) {
      if (kDebugMode) debugPrint("최근 새로고침 시도");
      return;
    }
    _lastRefreshTime = now;
    loading = true;
    notifyListeners();
    try {
      await _fetchStoreList(isRefresh: true);
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

    if (!items.any((s) => s.id == storeId)) {
      items = [store, ...items];
    }

    final prev = store.isFavorite;
    _updateFavoriteLocal(storeId, !prev);
    notifyListeners();

    try {
      if (prev) {
        await _repo.unfavoriteStore(storeId);
        _updateFavoriteLocal(storeId, !prev);
      } else {
        await _repo.favoriteStore(storeId);
        _updateFavoriteLocal(storeId, !prev);
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
