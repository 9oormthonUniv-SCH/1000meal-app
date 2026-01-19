class DailyMenuResponse {
  final int id;
  final String date; // YYYY-MM-DD
  final int stock;
  final bool open;

  DailyMenuResponse({
    required this.id,
    required this.date,
    required this.stock,
    required this.open,
  });

  factory DailyMenuResponse.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v) => v is int ? v : int.tryParse((v ?? '').toString()) ?? 0;
    bool toBool(dynamic v) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      final s = v?.toString().trim().toLowerCase();
      if (s == null || s.isEmpty) return false;
      return s == 'true' || s == '1' || s == 'y' || s == 'yes';
    }

    return DailyMenuResponse(
      id: toInt(json['id']),
      date: (json['date'] ?? '').toString(),
      stock: toInt(json['stock'] ?? 0),
      open: toBool(json['open']),
    );
  }
}

