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
  String? errorMessage;

  /// weeks[0] is the top-most week.
  final List<List<AdminMenuDay>> weeks = [];
  final Set<String> _loadedMondays = <String>{};

  String todayYmd = kstTodayYmd();

  Future<void> init() async {
    if (weeks.isNotEmpty) return;
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final monday = mondayOfYmd(todayYmd);
      await _loadWeek(baseDate: monday, direction: 'next', force: true);
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
      final items = api?.menus ?? <String>[];

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
}

