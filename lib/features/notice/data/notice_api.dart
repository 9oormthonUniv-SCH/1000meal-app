import '../../../common/dio/api_exception.dart';
import '../../../common/dio/dio_client.dart';
import 'package:dio/dio.dart';
import 'dart:typed_data';
import '../models/notice_models.dart';

class NoticeApi {
  final DioClient _client;
  NoticeApi(this._client);

  Map<String, String>? _authHeaderOrNull(String? token) {
    if (token == null) return null;
    final t = token.trim();
    if (t.isEmpty) return null;
    return {'Authorization': 'Bearer $t'};
  }

  Object _unwrapData(Object root) {
    if (root is Map) {
      final data = root['data'];
      if (data != null) return data;
    }
    return root;
  }

  List<dynamic> _extractList(Object data) {
    if (data is List) return data;
    if (data is Map) {
      for (final key in ['items', 'notices', 'content', 'list', 'results']) {
        final v = data[key];
        if (v is List) return v;
      }
    }
    return const [];
  }

  Future<List<Notice>> getNotices({String? token}) async {
    final root = await _client.get<Object>(
      '/notices',
      headers: _authHeaderOrNull(token),
    );
    final data = _unwrapData(root);
    final rawList = _extractList(data);
    return rawList
        .whereType<Map<String, dynamic>>()
        .map(Notice.fromJson)
        .toList(growable: false);
  }

  Future<Notice> getNotice({required int id, String? token}) async {
    final root = await _client.get<Object>(
      '/notices/$id',
      headers: _authHeaderOrNull(token),
    );
    final data = _unwrapData(root);
    if (data is Map<String, dynamic>) return Notice.fromJson(data);
    throw ApiException('잘못된 응답 형식입니다.');
  }

  Future<Notice> createNotice({required NoticeUpsertRequest request, required String token}) async {
    final root = await _client.post<Object>(
      '/notices',
      headers: {'Authorization': 'Bearer $token'},
      data: request.toJson(),
    );
    final data = _unwrapData(root);
    if (data is Map<String, dynamic>) return Notice.fromJson(data);
    throw ApiException('잘못된 응답 형식입니다.');
  }

  Future<Notice> updateNotice({required int id, required NoticeUpsertRequest request, required String token}) async {
    final root = await _client.put<Object>(
      '/notices/$id',
      headers: {'Authorization': 'Bearer $token'},
      data: request.toJson(),
    );
    final data = _unwrapData(root);
    if (data is Map<String, dynamic>) return Notice.fromJson(data);
    throw ApiException('잘못된 응답 형식입니다.');
  }

  Future<void> deleteNotice({required int id, required String token}) async {
    await _client.delete<Object>(
      '/notices/$id',
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  Future<List<NoticeImagePresign>> presignNoticeImages({
    required int id,
    required NoticePresignRequest request,
    required String token,
  }) async {
    final root = await _client.post<Object>(
      '/notices/$id/images/presign',
      headers: {'Authorization': 'Bearer $token'},
      data: request.toJson(),
    );
    final data = _unwrapData(root);
    final rawList = _extractList(data);
    return rawList
        .whereType<Map<String, dynamic>>()
        .map(NoticeImagePresign.fromJson)
        .toList(growable: false);
  }

  Future<List<NoticeImage>> registerNoticeImages({
    required int id,
    required NoticeImagesUpsertRequest request,
    required String token,
  }) async {
    final root = await _client.post<Object>(
      '/notices/$id/images',
      headers: {'Authorization': 'Bearer $token'},
      data: request.toJson(),
    );
    final data = _unwrapData(root);
    final rawList = _extractList(data);
    return rawList
        .whereType<Map<String, dynamic>>()
        .map(NoticeImage.fromJson)
        .toList(growable: false);
  }

  /// Uploads bytes to an S3 presigned URL (full URL).
  /// [method] 'PUT' (default, S3 PutObject presigned) or 'POST'.
  Future<void> uploadToPresignedUrl({
    required String uploadUrl,
    required List<int> bytes,
    required Map<String, String> headers,
    String method = 'PUT',
  }) async {
    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(milliseconds: 20000),
          sendTimeout: const Duration(milliseconds: 20000),
          receiveTimeout: const Duration(milliseconds: 20000),
          responseType: ResponseType.plain,
          followRedirects: true,
        ),
      );
      final body = Uint8List.fromList(bytes);
      // S3 presigned URL: only headers that were signed may be sent. Backend often signs only Content-Type.
      // Sending x-amz-acl (etc.) when not in SignedHeaders causes 403 "Headers present which were not signed".
      final safeHeaders = <String, String>{};
      final contentType = headers['Content-Type'] ?? headers['content-type'];
      if (contentType != null && contentType.isNotEmpty) {
        safeHeaders['Content-Type'] = contentType;
      }
      final options = Options(headers: safeHeaders);
      if (method.toUpperCase() == 'PUT') {
        await dio.put<void>(uploadUrl, data: body, options: options);
      } else {
        await dio.post<void>(uploadUrl, data: body, options: options);
      }
    } on DioException catch (e) {
      throw ApiException(
        e.message ?? '이미지 업로드에 실패했습니다.',
        statusCode: e.response?.statusCode,
        details: e.response?.data,
      );
    }
  }
}

