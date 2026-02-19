import '../../../common/dio/api_exception.dart';
import '../../../common/dio/dio_client.dart';
import '../models/qr_models.dart';

/// QR 사용 등록 API (스캔한 URL로 POST, body에 qrToken, 헤더에 엑세스 토큰)
class QrApi {
  QrApi(this._client);

  final DioClient _client;

  /// 스캔한 URL에서 endpoint와 qrToken을 추출해 POST 요청.
  /// URL 예: https://domain/api/v1/qr/usages?qrToken=매장토큰
  /// 또는 path에 토큰: .../qr/usages/매장토큰
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
