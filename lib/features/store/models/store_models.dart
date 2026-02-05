class StoreListItem {
  final int id;
  final String name;
  final String? imageUrl;
  final List<String> menus;
  final int remain;
  final bool? open;
  final TodayMenu? todayMenu;

  StoreListItem({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.menus,
    required this.remain,
    this.open,
    required this.todayMenu,
  });

  List<TodayMenuGroup> get menuGroups => todayMenu?.menuGroups ?? const <TodayMenuGroup>[];
  bool get hasMultiGroups => menuGroups.length >= 2;

  /// 단일 그룹일 때 기존 카드 레이아웃에 쓰는 메뉴 텍스트
  String get singleGroupMenusText {
    final g = menuGroups.isNotEmpty ? (menuGroups..sort((a, b) => a.sortOrder.compareTo(b.sortOrder))).first : null;
    if (g == null) {
      if (menus.isEmpty) return '메뉴 정보 없음';
      return menus.join(', ');
    }
    if (g.menus.isEmpty) return '메뉴 정보 없음';
    return g.menus.map((e) => e.name).join(', ');
  }

  /// 단일 그룹일 때 재고 숫자 (없으면 remain fallback)
  int get firstGroupStock {
    if (menuGroups.isEmpty) return remain;
    final sorted = [...menuGroups]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return sorted.first.stock;
  }

  factory StoreListItem.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v, {int fallback = 0}) =>
        v is int ? v : int.tryParse((v ?? '').toString()) ?? fallback;
    bool? toBool(dynamic v) {
      if (v == null) return null;
      if (v is bool) return v;
      if (v is num) return v != 0;
      final s = v.toString().trim().toLowerCase();
      if (s.isEmpty) return null;
      if (s == 'true' || s == '1' || s == 'y' || s == 'yes') return true;
      if (s == 'false' || s == '0' || s == 'n' || s == 'no') return false;
      return null;
    }

    List<String> toStringList(dynamic v) {
      if (v is List) {
        return v
            .map((e) => e.toString())
            .where((e) => e.trim().isNotEmpty)
            .toList();
      }
      if (v is String && v.trim().isNotEmpty) {
        return v
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      return [];
    }

    final todayMenu = json['todayMenu'];
    final menus = todayMenu is Map<String, dynamic>
        ? (todayMenu['menus'] ?? todayMenu['menuNames'] ?? todayMenu['menu'])
        : (json['menus'] ?? json['menuNames']);

    int? remainFromGroups;
    TodayMenu? parsedTodayMenu;
    if (todayMenu is Map<String, dynamic>) {
      parsedTodayMenu = TodayMenu.fromJson(todayMenu);
      if (parsedTodayMenu.menuGroups.isNotEmpty) {
        remainFromGroups = parsedTodayMenu.menuGroups.fold<int>(0, (sum, g) => sum + g.stock);
      }
    }

    final remain = remainFromGroups ??
        (todayMenu is Map<String, dynamic>
            ? (todayMenu['remain'] ?? todayMenu['stock'] ?? todayMenu['count'])
            : (json['remain'] ?? json['stock'] ?? json['count']));

    return StoreListItem(
      id: toInt(json['id'] ?? json['storeId']),
      name: (json['name'] ?? json['storeName'] ?? '').toString(),
      imageUrl:
          (json['imageUrl'] ??
                  json['image'] ??
                  json['thumbnailUrl'] ??
                  json['thumbnail'])
              ?.toString(),
      menus: toStringList(menus),
      remain: toInt(remain, fallback: 0),
      open: toBool(json['open'] ?? json['isOpen']),
      todayMenu: parsedTodayMenu,
    );
  }
}

class TodayMenuMenuItem {
  final int id;
  final String name;

  TodayMenuMenuItem({required this.id, required this.name});

  factory TodayMenuMenuItem.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v) => v is int ? v : int.tryParse((v ?? '').toString()) ?? 0;
    return TodayMenuMenuItem(
      id: toInt(json['id']),
      name: (json['name'] ?? '').toString(),
    );
  }
}

class TodayMenuGroup {
  final int id;
  final String name;
  final int sortOrder;
  final int capacity;
  final int stock;
  final List<TodayMenuMenuItem> menus;

  TodayMenuGroup({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.capacity,
    required this.stock,
    required this.menus,
  });

  factory TodayMenuGroup.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v) => v is int ? v : int.tryParse((v ?? '').toString()) ?? 0;
    final rawMenus = json['menus'];
    final menus = rawMenus is List
        ? rawMenus
            .whereType<Map>()
            .map((e) => TodayMenuMenuItem.fromJson(e.cast<String, dynamic>()))
            .toList(growable: false)
        : <TodayMenuMenuItem>[];
    return TodayMenuGroup(
      id: toInt(json['id']),
      name: (json['name'] ?? '').toString(),
      sortOrder: toInt(json['sortOrder']),
      capacity: toInt(json['capacity']),
      stock: toInt(json['stock']),
      menus: menus,
    );
  }
}

class TodayMenu {
  final int id;
  final String date; // YYYY-MM-DD
  final String dayOfWeek; // MONDAY, ...
  final List<TodayMenuGroup> menuGroups;
  final bool open;
  final bool? holiday;

  TodayMenu({
    required this.id,
    required this.date,
    required this.dayOfWeek,
    required this.menuGroups,
    required this.open,
    required this.holiday,
  });

  factory TodayMenu.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v) => v is int ? v : int.tryParse((v ?? '').toString()) ?? 0;
    bool toBool(dynamic v) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      final s = v?.toString().trim().toLowerCase();
      if (s == null || s.isEmpty) return false;
      return s == 'true' || s == '1' || s == 'y' || s == 'yes';
    }

    final rawGroups = json['menuGroups'];
    final groups = rawGroups is List
        ? rawGroups.whereType<Map>().map((e) => TodayMenuGroup.fromJson(e.cast<String, dynamic>())).toList(growable: false)
        : <TodayMenuGroup>[];

    return TodayMenu(
      id: toInt(json['id']),
      date: (json['date'] ?? '').toString(),
      dayOfWeek: (json['dayOfWeek'] ?? '').toString(),
      menuGroups: groups,
      open: toBool(json['open']),
      holiday: json.containsKey('holiday') ? toBool(json['holiday']) : null,
    );
  }
}

class StoreDetail {
  final int id;
  final String name;
  final bool? open;
  final String? imageUrl;
  final String? address;
  final String? phone;
  final List<String> menus;

  StoreDetail({
    required this.id,
    required this.name,
    this.open,
    this.imageUrl,
    this.address,
    this.phone,
    required this.menus,
  });

  factory StoreDetail.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v, {int fallback = 0}) =>
        v is int ? v : int.tryParse((v ?? '').toString()) ?? fallback;
    bool? toBool(dynamic v) {
      if (v == null) return null;
      if (v is bool) return v;
      if (v is num) return v != 0;
      final s = v.toString().trim().toLowerCase();
      if (s.isEmpty) return null;
      if (s == 'true' || s == '1' || s == 'y' || s == 'yes') return true;
      if (s == 'false' || s == '0' || s == 'n' || s == 'no') return false;
      return null;
    }

    List<String> toStringList(dynamic v) {
      if (v is List) {
        return v
            .map((e) => e.toString())
            .where((e) => e.trim().isNotEmpty)
            .toList();
      }
      if (v is String && v.trim().isNotEmpty) {
        return v
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      return [];
    }

    final todayMenu = json['todayMenu'];
    final menus = todayMenu is Map<String, dynamic>
        ? (todayMenu['menus'] ?? todayMenu['menuNames'] ?? todayMenu['menu'])
        : (json['menus'] ?? json['menuNames']);

    return StoreDetail(
      id: toInt(json['id'] ?? json['storeId']),
      name: (json['name'] ?? json['storeName'] ?? '').toString(),
      open: toBool(json['open'] ?? json['isOpen']),
      imageUrl:
          (json['imageUrl'] ??
                  json['image'] ??
                  json['thumbnailUrl'] ??
                  json['thumbnail'])
              ?.toString(),
      address: json['address']?.toString(),
      phone: json['phone']?.toString(),
      menus: toStringList(menus),
    );
  }
}
