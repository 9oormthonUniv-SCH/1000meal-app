import 'package:flutter/foundation.dart';

import '../../../common/dio/api_error_mapper.dart';
import '../../../common/dio/api_exception.dart';
import '../../../common/utils/kst_date.dart';
import '../../../common/utils/week_kst.dart';
import '../repositories/admin_repository.dart';

class AdminMenuEditViewModel extends ChangeNotifier {
  AdminMenuEditViewModel(this._repo, {String? initialDate})
      : selectedId = initialDate?.isNotEmpty == true ? initialDate! : kstTodayYmd(),
        mondayId = mondayOfYmd(initialDate?.isNotEmpty == true ? initialDate! : kstTodayYmd());

  final AdminRepository _repo;

  String selectedId; // YYYY-MM-DD
  String mondayId; // YYYY-MM-DD (monday)

  bool loading = false;
  bool saving = false;
  bool dirty = false;
  String input = '';
  String? errorMessage;

  List<String> menus = [];

  bool showSavedToast = false;

  Future<void> load() async {
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final res = await _repo.getDailyMenu(date: selectedId);
      menus = res?.menus ?? <String>[];
      dirty = false;
    } catch (e) {
      if (e is ApiException) {
        errorMessage = mapErrorToMessage(e, responseData: e.details);
      } else {
        errorMessage = '메뉴 불러오기 실패';
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void setInput(String v) {
    input = v;
    notifyListeners();
  }

  void addMenu([String? menuText]) {
    final text = (menuText ?? input).trim();
    if (text.isEmpty) return;
    menus = [...menus, text];
    if (menuText == null) input = '';
    dirty = true;
    notifyListeners();
  }

  void removeMenu(int idx) {
    if (idx < 0 || idx >= menus.length) return;
    final next = List<String>.from(menus);
    next.removeAt(idx);
    menus = next;
    dirty = true;
    notifyListeners();
  }

  Future<void> save() async {
    if (saving) return;
    saving = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repo.saveDailyMenu(date: selectedId, menus: menus);
      dirty = false;
      showSavedToast = true;
    } catch (e) {
      if (e is ApiException) {
        errorMessage = mapErrorToMessage(e, responseData: e.details);
      } else {
        errorMessage = '저장 실패';
      }
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  void hideToast() {
    if (!showSavedToast) return;
    showSavedToast = false;
    notifyListeners();
  }

  Future<void> selectDate(String ymd) async {
    if (ymd == selectedId) return;
    selectedId = ymd;
    mondayId = mondayOfYmd(ymd);
    await load();
  }

  Future<void> shiftWeek(int deltaWeeks) async {
    final nextMonday = addWeeksYmd(mondayId, deltaWeeks);
    // 편집 화면은 mondayId를 선택 날짜로 사용(웹과 동일하게 monday로 이동)
    await selectDate(nextMonday);
  }
}

