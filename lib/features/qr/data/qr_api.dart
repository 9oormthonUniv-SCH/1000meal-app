import '../../../common/config/app_config.dart';
import '../../../common/dio/api_exception.dart';
import '../../../common/dio/dio_client.dart';
import '../models/qr_models.dart';

/// QR 사용 등록 API (스캔한 URL로 POST, body에 qrToken, 헤더에 엑세스 토큰)
class QrApi {
  QrApi(this._client);

  final DioClient _client;

  /// 당일 명부 등록 정보 (GET /qr/usages/today). 404면 미등록.
  Future<QrTodayResponse?> getTodayUsage(String accessToken) async {
    try {
      final res = await _client.get<Map<String, dynamic>>(
        '/qr/usages/today',
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );
      if (res == null) return null;
      final data = res['data'] is Map<String, dynamic>
          ? res['data'] as Map<String, dynamic>
          : res;
      final today = QrTodayResponse.fromJson(Map<String, dynamic>.from(data));
      return today.used ? today : null;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// qrToken으로 매장 이름 조회 (GET /qr/stores?qrToken= 또는 동일 형식). 없으면 null.
  Future<String?> getStoreNameByQrToken(String qrToken, String accessToken) async {
    try {
      final res = await _client.get<Map<String, dynamic>>(
        '/qr/stores',
        queryParameters: {'qrToken': qrToken},
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );
      if (res == null) return null;
      final data = res['data'];
      if (data is! Map<String, dynamic>) return null;
      final name = data['storeName'] ?? data['name'];
      return name?.toString();
    } on ApiException catch (_) {
      return null;
    }
  }

  /// qrToken만으로 명부 등록 (확인 버튼 후 호출).
  Future<QrUsageResponse> reportQrUsageByToken(
    String qrToken,
    String accessToken,
  ) async {
    final url = '${AppConfig.apiBaseUrl}/qr/usages';
    return _postWithAuth(url, qrToken: qrToken, accessToken: accessToken);
  }

  /// 스캔한 URL에서 endpoint와 qrToken을 추출해 POST 요청.
  /// URL 예: https://domain/api/v1/qr/usages?qrToken=매장토큰
  Future<QrUsageResponse> reportQrUsage(String scannedUrl, String accessToken) {
    final uri = Uri.tryParse(scannedUrl);
    if (uri == null || !uri.hasAbsolutePath) {
      throw ApiException('유효하지 않은 QR URL입니다.');
    }

    String qrToken;
    String requestUrl;

    final queryToken = uri.queryParameters['qrToken'];
    if (queryToken != null && queryToken.isNotEmpty) {
      qrToken = queryToken;
      requestUrl = '${uri.origin}${uri.path}';
    } else {
      final segments = uri.pathSegments;
      if (segments.isEmpty) {
        throw ApiException('QR에서 매장 정보를 찾을 수 없습니다.');
      }
      qrToken = segments.last;
      requestUrl = '${uri.origin}/${segments.sublist(0, segments.length - 1).join('/')}';
    }

    return _postWithAuth(requestUrl, qrToken: qrToken, accessToken: accessToken);
  }

  Future<QrUsageResponse> _postWithAuth(
    String url, {
    required String qrToken,
    required String accessToken,
  }) async {
    try {
      final res = await _client.post<Map<String, dynamic>>(
        url,
        data: {'qrToken': qrToken},
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );
      if (res == null) {
        throw ApiException('응답이 없습니다.');
      }
      final data = res['data'];
      if (data is! Map<String, dynamic>) {
        throw ApiException('응답 형식이 올바르지 않습니다.');
      }
      return QrUsageResponse.fromJson(Map<String, dynamic>.from(data));
    } on ApiException {
      rethrow;
    }
  }
}
