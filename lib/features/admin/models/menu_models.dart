int _toInt(dynamic v) => v is int ? v : int.tryParse((v ?? '').toString()) ?? 0;
bool _toBool(dynamic v) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  final s = v?.toString().trim().toLowerCase();
  if (s == null || s.isEmpty) return false;
  return s == 'true' || s == '1' || s == 'y' || s == 'yes';
}

/// 주간 조회 시 하루에 해당하는 그룹 하나 (GET /menus/daily/weekly/{storeId}/groups)
class WeeklyDayGroup {
  final int groupId;
  final String name;
  final int sortOrder;
  final int stock;
  final int capacity;
  final List<String> menus;

  WeeklyDayGroup({
    required this.groupId,
    required this.name,
    required this.sortOrder,
    required this.stock,
    required this.capacity,
    required this.menus,
  });

  factory WeeklyDayGroup.fromJson(Map<String, dynamic> json) {
    final rawMenus = json['menus'];
    final menus = rawMenus is List ? rawMenus.map((e) => e.toString()).toList(growable: false) : <String>[];

    return WeeklyDayGroup(
      groupId: _toInt(json['groupId']),
      name: (json['name'] ?? '').toString(),
      sortOrder: _toInt(json['sortOrder']),
      stock: _toInt(json['stock']),
      capacity: _toInt(json['capacity']),
      menus: menus,
    );
  }
}

/// GET /menus/daily/weekly/{storeId}/groups?date= 응답의 day item
class WeeklyMenuDay {
  final int id;
  final String date; // YYYY-MM-DD
  final String dayOfWeek; // MONDAY, ...
  final bool holiday;
  final int totalStock;
  final List<WeeklyDayGroup> groups;
  final bool open;

  WeeklyMenuDay({
    required this.id,
    required this.date,
    required this.dayOfWeek,
    required this.holiday,
    required this.totalStock,
    required this.groups,
    required this.open,
  });

  /// 임시 호환용: 기존 UI가 "문자열 메뉴 리스트"를 기대할 때 사용.
  List<String> get flattenedMenus {
    final out = <String>[];
    for (final g in groups) {
      out.addAll(g.menus);
    }
    return out;
  }

  factory WeeklyMenuDay.fromJson(Map<String, dynamic> json) {
    final list = json['groups'];
    final groups = list is List
        ? list.whereType<Map>().map((e) => WeeklyDayGroup.fromJson(e.cast<String, dynamic>())).toList(growable: false)
        : <WeeklyDayGroup>[];

    return WeeklyMenuDay(
      id: _toInt(json['id']),
      date: (json['date'] ?? '').toString(),
      dayOfWeek: (json['dayOfWeek'] ?? '').toString(),
      holiday: _toBool(json['holiday']),
      totalStock: _toInt(json['totalStock']),
      groups: groups,
      open: _toBool(json['open']),
    );
  }
}

/// GET /menus/daily/weekly/{storeId}/groups?date= 응답
class WeeklyMenuResponse {
  final int storeId;
  final String startDate;
  final String endDate;
  final List<WeeklyMenuDay> dailyMenus;

  WeeklyMenuResponse({
    required this.storeId,
    required this.startDate,
    required this.endDate,
    required this.dailyMenus,
  });

  factory WeeklyMenuResponse.fromJson(Map<String, dynamic> json) {
    final list = json['dailyMenus'];
    final daily = list is List
        ? list.whereType<Map>().map((e) => WeeklyMenuDay.fromJson(e.cast<String, dynamic>())).toList(growable: false)
        : <WeeklyMenuDay>[];

    return WeeklyMenuResponse(
      storeId: _toInt(json['storeId']),
      startDate: (json['startDate'] ?? '').toString(),
      endDate: (json['endDate'] ?? '').toString(),
      dailyMenus: daily,
    );
  }
}

/// GET /menus/daily/{storeId}/groups?date= 응답의 그룹 한 개
class DailyMenuGroupItem {
  final int id;
  final String name;
  final int sortOrder;
  final int stock;
  final int capacity;
  final List<String> menus;

  DailyMenuGroupItem({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.stock,
    required this.capacity,
    required this.menus,
  });

  factory DailyMenuGroupItem.fromJson(Map<String, dynamic> json) {
    final rawMenus = json['menus'];
    final menus = rawMenus is List ? rawMenus.map((e) => e.toString()).toList(growable: false) : <String>[];

    return DailyMenuGroupItem(
      id: _toInt(json['id']),
      name: (json['name'] ?? '').toString(),
      sortOrder: _toInt(json['sortOrder']),
      stock: _toInt(json['stock']),
      capacity: _toInt(json['capacity']),
      menus: menus,
    );
  }
}

/// GET /menus/daily/{storeId}/groups?date= 응답 (특정 날짜의 그룹 목록 + 재고)
class DailyMenuResponse {
  final int id;
  final String date; // YYYY-MM-DD
  final String dayOfWeek; // MONDAY, ...
  final int totalStock;
  final List<DailyMenuGroupItem> groups;
  final bool open;
  final bool? holiday;

  DailyMenuResponse({
    required this.id,
    required this.date,
    required this.dayOfWeek,
    required this.totalStock,
    required this.groups,
    required this.open,
    required this.holiday,
  });

  /// 임시 호환용: 기존 UI가 "문자열 메뉴 리스트"를 기대할 때 사용.
  List<String> get flattenedMenus {
    final out = <String>[];
    for (final g in groups) {
      out.addAll(g.menus);
    }
    return out;
  }

  factory DailyMenuResponse.fromJson(Map<String, dynamic> json) {
    final list = json['groups'];
    final groups = list is List
        ? list.whereType<Map>().map((e) => DailyMenuGroupItem.fromJson(e.cast<String, dynamic>())).toList(growable: false)
        : <DailyMenuGroupItem>[];

    return DailyMenuResponse(
      id: _toInt(json['id']),
      date: (json['date'] ?? '').toString(),
      dayOfWeek: (json['dayOfWeek'] ?? '').toString(),
      totalStock: _toInt(json['totalStock']),
      groups: groups,
      open: _toBool(json['open']),
      holiday: json.containsKey('holiday') ? _toBool(json['holiday']) : null,
    );
  }
}

/// 메뉴 그룹 특정 날짜 메뉴 upsert 응답
class MenuGroupMenusResponse {
  final int id;
  final int groupId;
  final String groupName;
  final String date;
  final List<String> menus;

  MenuGroupMenusResponse({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.date,
    required this.menus,
  });

  factory MenuGroupMenusResponse.fromJson(Map<String, dynamic> json) {
    final rawMenus = json['menus'];
    final menus = rawMenus is List ? rawMenus.map((e) => e.toString()).toList(growable: false) : <String>[];

    return MenuGroupMenusResponse(
      id: _toInt(json['id']),
      groupId: _toInt(json['groupId']),
      groupName: (json['groupName'] ?? '').toString(),
      date: (json['date'] ?? '').toString(),
      menus: menus,
    );
  }
}

enum DeductionUnit { single, multiFive, multiTen }

extension DeductionUnitValue on DeductionUnit {
  String get apiValue {
    switch (this) {
      case DeductionUnit.single:
        return 'SINGLE';
      case DeductionUnit.multiFive:
        return 'MULTI_FIVE';
      case DeductionUnit.multiTen:
        return 'MULTI_TEN';
    }
  }
}

/// 자주 쓰는 메뉴 프리셋 목록 항목 (GET .../menu-presets)
class MenuPreset {
  final int id;
  final String preview;
  final String createdAt;
  final String updatedAt;

  MenuPreset({
    required this.id,
    required this.preview,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MenuPreset.fromJson(Map<String, dynamic> json) {
    return MenuPreset(
      id: _toInt(json['id']),
      preview: (json['preview'] ?? '').toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
      updatedAt: (json['updatedAt'] ?? '').toString(),
    );
  }
}

/// 자주 쓰는 메뉴 프리셋 상세 (GET .../menu-presets/{presetId}, POST 응답)
class MenuPresetDetail {
  final int id;
  final int storeId;
  final int groupId;
  final List<String> menus;
  final String preview;
  final String createdAt;
  final String updatedAt;

  MenuPresetDetail({
    required this.id,
    required this.storeId,
    required this.groupId,
    required this.menus,
    required this.preview,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MenuPresetDetail.fromJson(Map<String, dynamic> json) {
    final rawMenus = json['menus'];
    final menus = rawMenus is List
        ? rawMenus.map((e) => e.toString()).toList(growable: false)
        : <String>[];

    return MenuPresetDetail(
      id: _toInt(json['id']),
      storeId: _toInt(json['storeId']),
      groupId: _toInt(json['groupId']),
      menus: menus,
      preview: (json['preview'] ?? '').toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
      updatedAt: (json['updatedAt'] ?? '').toString(),
    );
  }
}

/// UI 호환용: 목록/선택에서 id + menus 표시 (MenuPresetDetail 또는 목록용 래퍼)
class FavoriteGroup {
  final int groupId;
  final List<String> menu;
  final String preview;

  FavoriteGroup({
    required this.groupId,
    required this.menu,
    this.preview = '',
  });

  int get id => groupId;
  List<String> get menus => menu;

  factory FavoriteGroup.fromJson(Map<String, dynamic> json) {
    final rawMenus = json['menu'];
    final menus = rawMenus is List ? rawMenus.map((e) => e.toString()).toList(growable: false) : <String>[];

    return FavoriteGroup(
      groupId: _toInt(json['groupId']),
      menu: menus,
      preview: (json['preview'] ?? '').toString(),
    );
  }

  factory FavoriteGroup.fromPresetDetail(MenuPresetDetail d) {
    return FavoriteGroup(groupId: d.id, menu: d.menus, preview: d.preview);
  }
}

class FavoritesResponse {
  final List<FavoriteGroup> groups;

  FavoritesResponse({required this.groups});

  factory FavoritesResponse.fromJson(Map<String, dynamic> json) {
    final list = json['groups'];
    final groups = list is List
        ? list.whereType<Map>().map((e) => FavoriteGroup.fromJson(e.cast<String, dynamic>())).toList(growable: false)
        : <FavoriteGroup>[];

    return FavoritesResponse(groups: groups);
  }

  /// menu-presets 목록을 FavoriteGroup 형태로 변환 (preview만 있음, 상세는 별도 조회)
  static FavoritesResponse fromPresetList(List<MenuPreset> presets) {
    final groups = presets
        .map((p) => FavoriteGroup(groupId: p.id, menu: const [], preview: p.preview))
        .toList(growable: false);
    return FavoritesResponse(groups: groups);
  }
}

