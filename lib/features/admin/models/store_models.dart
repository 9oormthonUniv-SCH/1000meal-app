class StoreDetail {
  final int id;
  final String name;
  final bool open;

  StoreDetail({required this.id, required this.name, required this.open});

  factory StoreDetail.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v) => v is int ? v : int.tryParse((v ?? '').toString()) ?? 0;

    return StoreDetail(
      id: toInt(json['id']),
      name: (json['name'] ?? '').toString(),
      open: json['open'] == true || (json['open']?.toString().toLowerCase() == 'true'),
    );
  }
}

