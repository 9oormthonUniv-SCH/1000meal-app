import 'package:flutter/foundation.dart';

import '../../../common/dio/api_error_mapper.dart';
import '../../../common/dio/api_exception.dart';
import '../../../common/utils/kst_date.dart';
import '../../../common/utils/week_kst.dart';
import '../models/menu_models.dart';
import '../repositories/admin_repository.dart';

class AdminMenuEditViewModel extends ChangeNotifier {
  AdminMenuEditViewModel(
    this._repo, {
    String? initialDate,
    required this.groupId,
  })  :
        selectedId = initialDate?.isNotEmpty == true ? initialDate! : kstTodayYmd(),
        mondayId = mondayOfYmd(initialDate?.isNotEmpty == true ? initialDate! : kstTodayYmd());

  final AdminRepository _repo;

  final int? groupId;

  String selectedId; // YYYY-MM-DD
  String mondayId; // YYYY-MM-DD (monday)

  bool loading = false;
  bool saving = false;
  bool dirty = false;
  String input = '';
  String? errorMessage;

  List<String> menus = [];
  String groupName = '';

  bool showSavedToast = false;
  bool showFrequentMenu = false;
  List<FavoriteGroup> frequentMenus = [];

  Future<void> load() async {
    if (groupId == null) {
      menus = [];
      groupName = '';
      dirty = false;
      loading = false;
      notifyListeners();
      return;
    }
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final res = await _repo.getDailyMenu(date: selectedId);
      final groups = res?.groups ?? const <DailyMenuGroupItem>[];
      final group = groups.where((g) => g.id == groupId).cast<DailyMenuGroupItem?>().firstWhere((_) => true, orElse: () => null);
      menus = group?.menus ?? <String>[];
      groupName = group?.name ?? '';
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
    if (groupId == null) return;
    if (saving) return;
    saving = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repo.upsertMenuGroupMenus(groupId: groupId!, date: selectedId, menus: menus);
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

  Future<bool> loadFrequentMenus() async {
    if (groupId == null) return false;
    try {
      final res = await _repo.getFavoritesForGroup(groupId: groupId!);
      frequentMenus = res.groups;
      notifyListeners();
      return res.groups.isNotEmpty;
    } catch (e) {
      // 에러는 무시 (자주 쓰는 메뉴는 선택사항)
      return false;
    }
  }

  Future<bool> toggleFrequentMenu() async {
    if (!showFrequentMenu) {
      // 열 때: 목록이 비어있으면 로드
      if (frequentMenus.isEmpty) {
        final hasMenus = await loadFrequentMenus();
        if (!hasMenus) {
          // 목록이 없으면 toast 표시를 위해 false 반환
          showFrequentMenu = false;
          notifyListeners();
          return false; // 목록이 없음을 알림
        }
      }
      // 목록이 있으면 드롭다운 표시
      showFrequentMenu = true;
      notifyListeners();
      return true;
    } else {
      // 닫을 때
      showFrequentMenu = false;
      notifyListeners();
      return true;
    }
  }

  Future<void> selectFrequentMenu(FavoriteGroup group) async {
    if (groupId == null) return;
    try {
      final detail = await _repo.getMenuPresetDetail(groupId: groupId!, presetId: group.id);
      menus = [...menus, ...detail.menus];
      dirty = true;
      showFrequentMenu = false;
      notifyListeners();
    } catch (_) {
      // 실패 시 무시
    }
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

