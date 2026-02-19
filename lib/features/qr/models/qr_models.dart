/// POST /qr/usages 200 응답 data
class QrUsageResponse {
  final int storeId;
  final String storeName;
  final String usedAt;
  final String usedDate;

  QrUsageResponse({
    required this.storeId,
    required this.storeName,
    required this.usedAt,
    required this.usedDate,
  });

  factory QrUsageResponse.fromJson(Map<String, dynamic> json) {
    return QrUsageResponse(
      storeId: _toInt(json['storeId']),
      storeName: (json['storeName'] ?? '').toString(),
      usedAt: (json['usedAt'] ?? '').toString(),
      usedDate: (json['usedDate'] ?? '').toString(),
    );
  }
}

int _toInt(dynamic v) => v is int ? v : int.tryParse((v ?? '').toString()) ?? 0;
