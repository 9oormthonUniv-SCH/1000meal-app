import '../../../common/dio/api_exception.dart';
import '../../../common/dio/dio_client.dart';
import '../models/store_models.dart';

class StoreApi {
  final DioClient _client;
  StoreApi(this._client);

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
      for (final key in ['items', 'stores', 'content', 'list', 'results']) {
        final v = data[key];
        if (v is List) return v;
      }
    }
    return const [];
  }

  Future<List<StoreListItem>> getStoreList() async {
    final root = await _client.get<Object>('/stores');
    final data = _unwrapData(root);
    final rawList = _extractList(data);
    return rawList
        .whereType<Map<String, dynamic>>()
        .map(StoreListItem.fromJson)
        .toList();
  }

  Future<StoreDetail> getStoreDetail(int id) async {
    final root = await _client.get<Object>('/stores/$id');
    final data = _unwrapData(root);
    if (data is Map<String, dynamic>) {
      return StoreDetail.fromJson(data);
    }
    throw ApiException('잘못된 응답 형식입니다.');
  }
}
