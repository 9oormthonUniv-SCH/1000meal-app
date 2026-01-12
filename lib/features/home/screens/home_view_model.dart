import 'package:flutter/material.dart';
import '../../store/repositories/store_repository.dart';
import '../../store/models/store_models.dart';

class HomeViewModel extends ChangeNotifier {
  final StoreRepository _storeRepository;

  HomeViewModel(this._storeRepository) {
    loadStores(); // 초기 데이터 로드
  }

  // 상태 변수들
  List<StoreListItem> _stores = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<StoreListItem> get stores => _stores;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 매장 목록 로드
  Future<void> loadStores() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _stores = await _storeRepository.fetchStores();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 새로고침 로직
  Future<void> refreshStores() async {
    await loadStores();
  }

  // 에러 클리어
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
