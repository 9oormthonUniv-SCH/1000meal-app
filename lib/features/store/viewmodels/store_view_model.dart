import 'package:flutter/material.dart';
import '../models/store_models.dart';
import '../repositories/store_repository.dart';

class StoreViewModel extends ChangeNotifier {
  final StoreRepository _repository;

  StoreViewModel(this._repository);

  // 상태 관리
  List<StoreListItem> _stores = [];
  bool _isLoading = false;
  String? _error;
  StoreDetail? _selectedStore;

  List<StoreListItem> get stores => _stores;
  bool get isLoading => _isLoading;
  String? get error => _error;
  StoreDetail? get selectedStore => _selectedStore;

  // 매장 목록 로드
  Future<void> loadStores() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _stores = await _repository.fetchStores();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 매장 상세 로드
  Future<void> loadStoreDetail(int storeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedStore = await _repository.fetchStoreDetail(storeId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshStores() async {
    await loadStores();
  }

  // 에러 클리어
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // 선택된 매장 클리어
  void clearSelectedStore() {
    _selectedStore = null;
    notifyListeners();
  }

  // 유틸리티 메서드들
  StoreListItem? findStoreById(int id) {
    return _stores.cast<StoreListItem?>().firstWhere(
      (store) => store?.id == id,
      orElse: () => null,
    );
  }

  // 영업중인 매장만 필터링
  List<StoreListItem> get openStores {
    return _stores.where((store) => store.open).toList();
  }

  // 오늘 메뉴가 있는 매장만 필터링
  List<StoreListItem> get storesWithTodayMenu {
    return _stores.where((store) => store.todayMenu != null).toList();
  }

  // 남은 수량이 있는 매장만 필터링
  List<StoreListItem> get availableStores {
    return _stores.where((store) => store.remain > 0).toList();
  }
}
