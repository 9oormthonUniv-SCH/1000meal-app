import '../../../common/dio/api_exception.dart';
import '../../../common/dio/dio_client.dart';
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
}

