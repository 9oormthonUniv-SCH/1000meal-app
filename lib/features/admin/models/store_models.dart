class StoreDetail {
  final int id;
  final String name;
  final bool open;

  StoreDetail({required this.id, required this.name, required this.open});

  factory StoreDetail.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v) => v is int ? v : int.tryParse((v ?? '').toString()) ?? 0;
    bool toBool(dynamic v) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      final s = v?.toString().trim().toLowerCase();
      if (s == null || s.isEmpty) return false;
      return s == 'true' || s == '1' || s == 'y' || s == 'yes';
    }

    return StoreDetail(
      id: toInt(json['id']),
      name: (json['name'] ?? '').toString(),
      open: toBool(json['open']),
    );
  }
}

