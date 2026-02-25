import '../../../common/dio/api_exception.dart';
import '../../../common/dio/dio_client.dart';
import '../models/store_models.dart';

//즐겨찾기 토글 응답 모델
class FavoriteToggleResponse {
  final int storeId;
  final bool favorite;

  FavoriteToggleResponse({required this.storeId, required this.favorite});

  factory FavoriteToggleResponse.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v) =>
        v is int ? v : int.tryParse((v ?? '').toString()) ?? 0;
    bool toBool(dynamic v) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      final s = v?.toString().trim().toLowerCase();
      if (s == null || s.isEmpty) return false;
      return s == 'true' || s == '1' || s == 'y' || s == 'yes';
    }

    return FavoriteToggleResponse(
      storeId: toInt(json['storeId'] ?? json['id']),
      favorite: toBool(json['favorite'] ?? json['isFavorite']),
    );
  }
}

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

  //GET /api/v1/favorite/stores/{storeId} 즐겨찾기 매장 ID 목록 조회
  Future<List<int>> getFavoriteStoreIds({required String token}) async {
    final root = await _client.get<Object>(
      '/favorites/stores',
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = _unwrapData(root);
    final list = _extractList(data);
    return list
        .whereType<Map>()
        .map((e) => e['storeId'] ?? e['id'])
        .where((e) => e != null)
        .map((e) => int.tryParse(e.toString()) ?? 0)
        .where((e) => e > 0)
        .toList(growable: false);
  }

  //POST
  Future<FavoriteToggleResponse> favoriteStore({
    required int storeId,
    required String token,
  }) async {
    final root = await _client.post<Object>(
      '/favorite/stores/$storeId',
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = _unwrapData(root);
    if (data is Map<String, dynamic>) {
      return FavoriteToggleResponse.fromJson(data);
    }
    throw ApiException('잘못된 응답 형식입니다.');
  }

  // DELETE
  Future<FavoriteToggleResponse> unfavoriteStore({
    required int storeId,
    required String token,
  }) async {
    final root = await _client.delete<Object>(
      '/favorite/stores/$storeId',
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = _unwrapData(root);
    if (data is Map<String, dynamic>) {
      return FavoriteToggleResponse.fromJson(data);
    }
    throw ApiException('잘못된 응답 형식입니다.');
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
