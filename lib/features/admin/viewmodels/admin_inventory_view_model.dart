import 'package:flutter/foundation.dart';

import '../../../common/dio/api_error_mapper.dart';
import '../../../common/dio/api_exception.dart';
import '../../../common/utils/kst_date.dart';
import '../models/menu_models.dart';
import '../repositories/admin_repository.dart';

class AdminInventoryViewModel extends ChangeNotifier {
  AdminInventoryViewModel(this._repo);

  final AdminRepository _repo;

  bool loading = false;
  bool saving = false;
  String? errorMessage;

  String date = kstTodayYmd(); // YYYY-MM-DD (KST fixed)

  DailyMenuResponse? daily;
  int stock = 0;
  bool open = false;

  bool showOpenModal = false;
  bool showCloseModal = false;
  int _lastSavedStock = 0;

  Future<void> loadToday() async {
    loading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final res = await _repo.getDailyMenu(date: date);
      daily = res;
      stock = res?.stock ?? 0;
      open = res?.open ?? false;
      _lastSavedStock = stock;
    } catch (e) {
      if (e is ApiException) {
        errorMessage = mapErrorToMessage(e, responseData: e.details);
      } else {
        errorMessage = '오늘 재고 불러오기 실패';
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void closeModal() {
    showOpenModal = false;
    showCloseModal = false;
    notifyListeners();
  }

  Future<void> confirmOpenAndUnlock() async {
    // modal confirm: 실제 영업 토글 API 호출 (요구사항)
    saving = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repo.toggleStoreStatus();
      open = true;
      showOpenModal = false;
    } catch (e) {
      if (e is ApiException) {
        errorMessage = mapErrorToMessage(e, responseData: e.details);
      } else {
        errorMessage = '영업 상태 변경에 실패했습니다.';
      }
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<void> confirmCloseAndLock() async {
    // modal confirm: 실제 영업 토글 API 호출 (요구사항)
    saving = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repo.toggleStoreStatus();
      open = false;
      showCloseModal = false;
    } catch (e) {
      if (e is ApiException) {
        errorMessage = mapErrorToMessage(e, responseData: e.details);
      } else {
        errorMessage = '영업 상태 변경에 실패했습니다.';
      }
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<void> adjustStock(int delta) async {
    if (!open) {
      showOpenModal = true;
      notifyListeners();
      return;
    }
    final next = (stock + delta).clamp(0, 1 << 30);
    stock = next;
    notifyListeners();
    await commitStock();
  }

  void setStockFromInput(String raw) {
    final parsed = int.tryParse(raw.trim()) ?? 0;
    stock = parsed < 0 ? 0 : parsed;
    notifyListeners();
  }

  Future<void> commitStock() async {
    if (!open) return;
    final menuId = daily?.id;
    if (menuId == null) return;

    saving = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repo.updateDailyStock(menuId: menuId, stock: stock);
      // 영업 중 상태에서 재고가 0으로 떨어졌을 때, 영업 종료 전환 모달 제안
      if (open && stock == 0 && _lastSavedStock > 0) {
        showCloseModal = true;
      }
      _lastSavedStock = stock;
    } catch (e) {
      if (e is ApiException) {
        errorMessage = mapErrorToMessage(e, responseData: e.details);
      } else {
        errorMessage = '재고 업데이트 실패';
      }
    } finally {
      saving = false;
      notifyListeners();
    }
  }
}

