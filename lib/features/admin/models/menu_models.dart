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

    return DailyMenuResponse(
      id: toInt(json['id']),
      date: (json['date'] ?? '').toString(),
      stock: toInt(json['stock'] ?? 0),
      open: json['open'] == true || (json['open']?.toString().toLowerCase() == 'true'),
    );
  }
}

