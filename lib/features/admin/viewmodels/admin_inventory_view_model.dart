import 'dart:async';

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

  /// 단일 API 타임아웃 (188488b 동작하던 시절은 getDailyMenu 하나만 호출).
  static const Duration _loadTimeout = Duration(seconds: 25);
  /// 버튼 적용(저장) 시 API가 멈추면 무한 로딩 방지.
  static const Duration _saveTimeout = Duration(seconds: 15);

  /// 188488b 시절과 동일: getDailyMenu() 단일 호출, open은 응답의 res?.open 사용.
  /// getStoreDetail 제거로 "한쪽만 완료되고 다른 쪽이 안 끝나는" 무한로딩 원인 제거.
  Future<void> loadToday() async {
    if (loading) {
      loading = false;
      errorMessage = null;
      notifyListeners();
    }

    final storeId = await _repo.getStoreIdOrNull();
    if (storeId == null) {
      errorMessage = '가게 정보가 없습니다.';
      notifyListeners();
      return;
    }

    loading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final res = await _repo.getDailyMenu(date: date).timeout(
        _loadTimeout,
        onTimeout: () => throw TimeoutException('로딩 시간이 초과되었습니다. 네트워크를 확인해 주세요.'),
      );
      daily = res;
      open = res?.open ?? false;
      _groupStocks
        ..clear()
        ..addEntries((res?.groups ?? const <DailyMenuGroupItem>[]).map((g) => MapEntry(g.id, g.stock)));
      _lastSavedTotalStock = totalStock;
    } on TimeoutException catch (e) {
      errorMessage = e.message ?? '로딩 시간이 초과되었습니다. 네트워크를 확인해 주세요.';
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
    saving = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repo.toggleStoreStatus().timeout(
        _saveTimeout,
        onTimeout: () => throw TimeoutException('처리 시간이 초과되었습니다. 네트워크를 확인해 주세요.'),
      );
      open = true;
      showOpenModal = false;
    } on TimeoutException catch (e) {
      errorMessage = e.message ?? '처리 시간이 초과되었습니다. 네트워크를 확인해 주세요.';
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
    saving = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repo.toggleStoreStatus().timeout(
        _saveTimeout,
        onTimeout: () => throw TimeoutException('처리 시간이 초과되었습니다. 네트워크를 확인해 주세요.'),
      );
      open = false;
      showCloseModal = false;
    } on TimeoutException catch (e) {
      errorMessage = e.message ?? '처리 시간이 초과되었습니다. 네트워크를 확인해 주세요.';
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
      await _repo.updateMenuGroupStock(groupId: groupId, stock: stock).timeout(
        _saveTimeout,
        onTimeout: () => throw TimeoutException('처리 시간이 초과되었습니다. 네트워크를 확인해 주세요.'),
      );
      final nextTotal = totalStock;
      // 영업 중 상태에서 총 재고가 0으로 떨어졌을 때, 영업 종료 전환 모달 제안
      if (open && nextTotal == 0 && _lastSavedTotalStock > 0) {
        showCloseModal = true;
      }
      _lastSavedTotalStock = nextTotal;
    } on TimeoutException catch (e) {
      errorMessage = e.message ?? '처리 시간이 초과되었습니다. 네트워크를 확인해 주세요.';
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
      final res = await _repo.deductMenuGroupStock(groupId: groupId, deductionUnit: unit).timeout(
        _saveTimeout,
        onTimeout: () => throw TimeoutException('처리 시간이 초과되었습니다. 네트워크를 확인해 주세요.'),
      );
      final nextStock = (res['stock'] is int) ? res['stock'] as int : int.tryParse('${res['stock']}') ?? groupStock(groupId);
      _groupStocks[groupId] = nextStock < 0 ? 0 : nextStock;
      final nextTotal = totalStock;
      if (open && nextTotal == 0 && _lastSavedTotalStock > 0) {
        showCloseModal = true;
      }
      _lastSavedTotalStock = nextTotal;
    } on TimeoutException catch (e) {
      errorMessage = e.message ?? '처리 시간이 초과되었습니다. 네트워크를 확인해 주세요.';
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

