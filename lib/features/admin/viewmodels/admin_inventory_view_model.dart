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
  bool open = false;

  bool showOpenModal = false;
  bool showCloseModal = false;

  // groupId -> current stock (editable)
  final Map<int, int> _groupStocks = <int, int>{};
  int _lastSavedTotalStock = 0;

  List<DailyMenuGroupItem> get groupsSorted {
    final groups = daily?.groups ?? const <DailyMenuGroupItem>[];
    final sorted = [...groups]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return sorted;
  }

  int get totalStock {
    if (_groupStocks.isNotEmpty) {
      return _groupStocks.values.fold<int>(0, (sum, v) => sum + v);
    }
    return daily?.totalStock ?? 0;
  }

  int groupStock(int groupId) {
    final v = _groupStocks[groupId];
    if (v != null) return v;
    final g = (daily?.groups ?? const <DailyMenuGroupItem>[]).where((e) => e.id == groupId).cast<DailyMenuGroupItem?>().firstWhere((_) => true, orElse: () => null);
    return g?.stock ?? 0;
  }

  Future<void> loadToday() async {
    loading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // 매장 영업 여부는 스토어 상세 API 기준으로 사용 (재고 페이지 진입 시 팝업/비활성 스타일 정확 반영)
      final storeFuture = _repo.getStoreDetail();
      final res = await _repo.getDailyMenu(date: date);
      daily = res;
      final store = await storeFuture;
      open = store.open;
      _groupStocks
        ..clear()
        ..addEntries((res?.groups ?? const <DailyMenuGroupItem>[]).map((g) => MapEntry(g.id, g.stock)));
      _lastSavedTotalStock = totalStock;
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
    // 영업 종료 상태에서 재고를 바꾸다가 모달에서 아니요 선택 시 로컬 재고를 서버 값으로 복구
    if (!open && daily != null) {
      _groupStocks.clear();
      _groupStocks.addEntries((daily!.groups ?? const <DailyMenuGroupItem>[]).map((g) => MapEntry(g.id, g.stock)));
      _lastSavedTotalStock = totalStock;
    }
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
    // legacy: no-op (group 기반으로 전환됨)
  }

  Future<void> adjustGroupStock(int groupId, int delta) async {
    if (!open) {
      showOpenModal = true;
      notifyListeners();
      return;
    }
    final next = (groupStock(groupId) + delta).clamp(0, 1 << 30);
    _groupStocks[groupId] = next;
    notifyListeners();
    await commitGroupStock(groupId);
  }

  void setGroupStockFromInput(int groupId, String raw) {
    if (!open) {
      showOpenModal = true;
      notifyListeners();
      return;
    }
    final parsed = int.tryParse(raw.trim()) ?? 0;
    _groupStocks[groupId] = parsed < 0 ? 0 : parsed;
    notifyListeners();
  }

  Future<void> commitGroupStock(int groupId) async {
    if (!open) {
      showOpenModal = true;
      notifyListeners();
      return;
    }
    final stock = _groupStocks[groupId] ?? 0;

    saving = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repo.updateMenuGroupStock(groupId: groupId, stock: stock);
      final nextTotal = totalStock;
      // 영업 중 상태에서 총 재고가 0으로 떨어졌을 때, 영업 종료 전환 모달 제안
      if (open && nextTotal == 0 && _lastSavedTotalStock > 0) {
        showCloseModal = true;
      }
      _lastSavedTotalStock = nextTotal;
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

  Future<void> deductGroupStock(int groupId, DeductionUnit unit) async {
    if (!open) {
      showOpenModal = true;
      notifyListeners();
      return;
    }
    final current = groupStock(groupId);
    final delta = switch (unit) {
      DeductionUnit.single => 1,
      DeductionUnit.multiFive => 5,
      DeductionUnit.multiTen => 10,
    };
    if (current < delta) return;
    saving = true;
    errorMessage = null;
    notifyListeners();
    try {
      final res = await _repo.deductMenuGroupStock(groupId: groupId, deductionUnit: unit);
      final nextStock = (res['stock'] is int) ? res['stock'] as int : int.tryParse('${res['stock']}') ?? groupStock(groupId);
      _groupStocks[groupId] = nextStock < 0 ? 0 : nextStock;
      final nextTotal = totalStock;
      if (open && nextTotal == 0 && _lastSavedTotalStock > 0) {
        showCloseModal = true;
      }
      _lastSavedTotalStock = nextTotal;
    } catch (e) {
      if (e is ApiException) {
        errorMessage = mapErrorToMessage(e, responseData: e.details);
      } else {
        errorMessage = '재고 차감 실패';
      }
    } finally {
      saving = false;
      notifyListeners();
    }
  }
}

