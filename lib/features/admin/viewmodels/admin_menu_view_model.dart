import 'package:flutter/foundation.dart';

import '../../../common/dio/api_error_mapper.dart';
import '../../../common/dio/api_exception.dart';
import '../../../common/utils/kst_date.dart';
import '../../../common/utils/week_kst.dart';
import '../models/admin_menu_week.dart';
import '../models/menu_models.dart';
import '../repositories/admin_repository.dart';

class AdminMenuViewModel extends ChangeNotifier {
  AdminMenuViewModel(this._repo);

  final AdminRepository _repo;

  bool loading = false;
  bool loadingNext = false;
  bool loadingPrev = false;
  bool loadingGroups = false;
  String? errorMessage;

  List<DailyMenuGroupItem> groups = [];
  int? selectedGroupId;

  /// weeks[0] is the top-most week.
  final List<List<AdminMenuDay>> weeks = [];
  final Set<String> _loadedMondays = <String>{};
  final Map<String, List<WeeklyMenuDay>> _rawWeeksByMonday = <String, List<WeeklyMenuDay>>{};

  String todayYmd = kstTodayYmd();

  /// 메뉴 수정 화면에서 저장 후 돌아왔을 때 주간 데이터 다시 로드
  Future<void> refreshAfterEdit() async {
    weeks.clear();
    _loadedMondays.clear();
    _rawWeeksByMonday.clear();
    await init();
  }

  Future<void> init() async {
    if (weeks.isNotEmpty) return;
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _loadGroupsIfNeeded();
      final monday = mondayOfYmd(todayYmd);
      // 초기 4주를 로드해서 충분한 스크롤/무한로딩 UX를 확보한다.
      await _loadWeek(baseDate: monday, direction: 'next', force: true);
      await _loadWeek(baseDate: addWeeksYmd(monday, 1), direction: 'next', force: true);
      await _loadWeek(baseDate: addWeeksYmd(monday, 2), direction: 'next', force: true);
      await _loadWeek(baseDate: addWeeksYmd(monday, 3), direction: 'next', force: true);
    } catch (e) {
      if (e is ApiException) {
        errorMessage = mapErrorToMessage(e, responseData: e.details);
      } else {
        errorMessage = '주간 메뉴 불러오기 실패';
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> jumpToWeek({required String dateYmd}) async {
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _loadGroupsIfNeeded();
      final monday = mondayOfYmd(dateYmd);

      // 멀리 점프 시에는 현재 캐시/리스트를 초기화하고 해당 주 기준으로 재구성한다.
      weeks.clear();
      _loadedMondays.clear();
      _rawWeeksByMonday.clear();

      await _loadWeek(baseDate: monday, direction: 'next', force: true);
      await _loadWeek(baseDate: addWeeksYmd(monday, 1), direction: 'next', force: true);
      await _loadWeek(baseDate: addWeeksYmd(monday, 2), direction: 'next', force: true);
      await _loadWeek(baseDate: addWeeksYmd(monday, 3), direction: 'next', force: true);
    } catch (e) {
      if (e is ApiException) {
        errorMessage = mapErrorToMessage(e, responseData: e.details);
      } else {
        errorMessage = '주간 메뉴 불러오기 실패';
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _loadGroupsIfNeeded() async {
    if (groups.isNotEmpty && selectedGroupId != null) return;
    loadingGroups = true;
    notifyListeners();
    try {
      final res = await _repo.getDailyMenu(date: todayYmd);
      final list = res?.groups ?? const <DailyMenuGroupItem>[];
      groups = list;
      if (list.isNotEmpty) {
        if (selectedGroupId == null || !list.any((g) => g.id == selectedGroupId)) {
          selectedGroupId = list.first.id;
        }
      } else {
        selectedGroupId = null;
      }
    } finally {
      loadingGroups = false;
      notifyListeners();
    }
  }

  void selectGroup(int groupId) {
    if (selectedGroupId == groupId) return;
    selectedGroupId = groupId;
    // 이미 로드된 주차는 raw cache로 즉시 재매핑한다 (웹 useWeeklyMenus와 동일).
    _remapWeeksFromRaw();
    notifyListeners();
  }

  void _remapWeeksFromRaw() {
    if (weeks.isEmpty) return;
    final rebuilt = <List<AdminMenuDay>>[];
    for (final week in weeks) {
      final monday = mondayOfYmd(week.first.id);
      final raw = _rawWeeksByMonday[monday];
      if (raw == null || raw.isEmpty) {
        rebuilt.add(week);
      } else {
        final res = WeeklyMenuResponse(
          storeId: 0,
          startDate: '',
          endDate: '',
          dailyMenus: raw,
        );
        rebuilt.add(_buildWeekFromApiOrEmpty(res, monday));
      }
    }
    weeks
      ..clear()
      ..addAll(rebuilt);
  }

  Future<void> loadNextWeek() async {
    if (loadingNext || weeks.isEmpty) return;
    loadingNext = true;
    errorMessage = null;
    notifyListeners();
    try {
      final lastWeek = weeks.last;
      final lastMonday = mondayOfYmd(lastWeek.first.id);
      final nextMonday = addWeeksYmd(lastMonday, 1);
      await _loadWeek(baseDate: nextMonday, direction: 'next', force: false);
    } catch (e) {
      if (e is ApiException) {
        errorMessage = mapErrorToMessage(e, responseData: e.details);
      } else {
        errorMessage = '다음 주 불러오기 실패';
      }
    } finally {
      loadingNext = false;
      notifyListeners();
    }
  }

  Future<bool> loadPrevWeek() async {
    if (loadingPrev || weeks.isEmpty) return false;
    loadingPrev = true;
    errorMessage = null;
    notifyListeners();
    try {
      final firstWeek = weeks.first;
      final firstMonday = mondayOfYmd(firstWeek.first.id);
      final prevMonday = addWeeksYmd(firstMonday, -1);
      final before = weeks.length;
      await _loadWeek(baseDate: prevMonday, direction: 'prev', force: false);
      return weeks.length > before;
    } catch (e) {
      if (e is ApiException) {
        errorMessage = mapErrorToMessage(e, responseData: e.details);
      } else {
        errorMessage = '이전 주 불러오기 실패';
      }
      return false;
    } finally {
      loadingPrev = false;
      notifyListeners();
    }
  }

  Future<void> _loadWeek({
    required String baseDate,
    required String direction, // 'prev' | 'next'
    required bool force,
  }) async {
    final monday = mondayOfYmd(baseDate);
    if (!force && _loadedMondays.contains(monday)) return;
    if (weeks.any((w) => mondayOfYmd(w.first.id) == monday)) {
      _loadedMondays.add(monday);
      return;
    }

    final res = await _repo.getWeeklyMenu(date: baseDate);
    _rawWeeksByMonday[monday] = res.dailyMenus;
    final week = _buildWeekFromApiOrEmpty(res, monday);
    if (direction == 'next') {
      weeks.add(week);
    } else {
      weeks.insert(0, week);
    }
    _loadedMondays.add(monday);
  }

  List<AdminMenuDay> _buildWeekFromApiOrEmpty(WeeklyMenuResponse res, String monday) {
    // 요구사항: 주간 리스트는 월~금(5일)만
    final map = <String, WeeklyMenuDay>{};
    for (final d in res.dailyMenus) {
      map[d.date] = d;
    }

    final result = <AdminMenuDay>[];
    for (int i = 0; i < 5; i++) {
      final ymd = addDaysYmd(monday, i);
      final dt = _parseYmdLocal(ymd);
      final dateLabel = '${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
      const weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];
      final weekdayLabel = weekdayLabels[(dt.weekday - 1).clamp(0, 6)];

      final api = map[ymd];
      // 웹(useWeeklyMenus)과 동일: groupId가 있으면 해당 그룹, 없으면 첫 그룹.
      final g = _pickGroupForDay(api?.groups ?? const <WeeklyDayGroup>[], selectedGroupId);
      final items = g?.menus ?? <String>[];

      final isPast = dt.isBefore(_parseYmdLocal(todayYmd));
      final isToday = ymd == todayYmd;

      result.add(
        AdminMenuDay(
          id: ymd,
          dateLabel: dateLabel,
          weekdayLabel: weekdayLabel,
          items: items,
          isPast: isPast,
          isToday: isToday,
        ),
      );
    }
    return result;
  }

  DateTime _parseYmdLocal(String ymd) {
    final parts = ymd.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }

  WeeklyDayGroup? _pickGroupForDay(List<WeeklyDayGroup> groups, int? groupId) {
    if (groups.isEmpty) return null;
    if (groupId == null) return groups.first;
    final hit = groups.where((g) => g.groupId == groupId).cast<WeeklyDayGroup?>().firstWhere((_) => true, orElse: () => null);
    return hit ?? groups.first;
  }
}

