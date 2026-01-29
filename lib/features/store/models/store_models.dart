class StoreListItem {
  final int id;
  final String name;
  final String? imageUrl;
  final List<String> menus;
  final int remain;
  final bool? open;

  StoreListItem({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.menus,
    required this.remain,
    this.open,
  });

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

    final remain = todayMenu is Map<String, dynamic>
        ? (todayMenu['remain'] ?? todayMenu['stock'] ?? todayMenu['count'])
        : (json['remain'] ?? json['stock'] ?? json['count']);

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
