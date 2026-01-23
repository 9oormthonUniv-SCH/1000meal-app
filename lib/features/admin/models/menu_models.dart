class DailyMenuResponse {
  final int id;
  final String date; // YYYY-MM-DD
  final String dayOfWeek; // MONDAY, TUESDAY ...
  final int? stock;
  final List<String> menus;
  final bool open;

  DailyMenuResponse({
    required this.id,
    required this.date,
    required this.dayOfWeek,
    required this.stock,
    required this.menus,
    required this.open,
  });

  factory DailyMenuResponse.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v) => v is int ? v : int.tryParse((v ?? '').toString()) ?? 0;
    int? toIntNullable(dynamic v) => v == null ? null : (v is int ? v : int.tryParse(v.toString()));
    bool toBool(dynamic v) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      final s = v?.toString().trim().toLowerCase();
      if (s == null || s.isEmpty) return false;
      return s == 'true' || s == '1' || s == 'y' || s == 'yes';
    }

    final rawMenus = json['menus'];
    final menus = rawMenus is List ? rawMenus.map((e) => e.toString()).toList(growable: false) : <String>[];

    return DailyMenuResponse(
      id: toInt(json['id']),
      date: (json['date'] ?? '').toString(),
      dayOfWeek: (json['dayOfWeek'] ?? '').toString(),
      stock: toIntNullable(json['stock']),
      menus: menus,
      open: toBool(json['open']),
    );
  }
}

class WeeklyMenuDay {
  final int id;
  final String date; // YYYY-MM-DD
  final String dayOfWeek; // 월, 화, ... or MONDAY...
  final int? stock;
  final List<String> menus;
  final bool open;

  WeeklyMenuDay({
    required this.id,
    required this.date,
    required this.dayOfWeek,
    required this.stock,
    required this.menus,
    required this.open,
  });

  factory WeeklyMenuDay.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v) => v is int ? v : int.tryParse((v ?? '').toString()) ?? 0;
    int? toIntNullable(dynamic v) => v == null ? null : (v is int ? v : int.tryParse(v.toString()));
    bool toBool(dynamic v) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      final s = v?.toString().trim().toLowerCase();
      if (s == null || s.isEmpty) return false;
      return s == 'true' || s == '1' || s == 'y' || s == 'yes';
    }

    final rawMenus = json['menus'];
    final menus = rawMenus is List ? rawMenus.map((e) => e.toString()).toList(growable: false) : <String>[];

    return WeeklyMenuDay(
      id: toInt(json['id']),
      date: (json['date'] ?? '').toString(),
      dayOfWeek: (json['dayOfWeek'] ?? '').toString(),
      stock: toIntNullable(json['stock']),
      menus: menus,
      open: toBool(json['open']),
    );
  }
}

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
    int toInt(dynamic v) => v is int ? v : int.tryParse((v ?? '').toString()) ?? 0;
    final list = json['dailyMenus'];
    final daily = list is List
        ? list.whereType<Map>().map((e) => WeeklyMenuDay.fromJson(e.cast<String, dynamic>())).toList(growable: false)
        : <WeeklyMenuDay>[];

    return WeeklyMenuResponse(
      storeId: toInt(json['storeId']),
      startDate: (json['startDate'] ?? '').toString(),
      endDate: (json['endDate'] ?? '').toString(),
      dailyMenus: daily,
    );
  }
}

