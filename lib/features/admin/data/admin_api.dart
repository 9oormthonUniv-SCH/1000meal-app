import '../../../common/dio/dio_client.dart';

import '../models/menu_models.dart';
import '../models/store_models.dart';

class AdminApi {
  final DioClient _client;
  AdminApi(this._client);

  Map<String, dynamic> _unwrapData(Map<String, dynamic> root) {
    final inner = root['data'];
    if (inner is Map<String, dynamic>) return inner;
    return root;
  }

  Future<StoreDetail> getStoreDetail({required int storeId, required String token}) async {
    final root = await _client.get<Map<String, dynamic>>(
      '/stores/$storeId',
      headers: {'Authorization': 'Bearer $token'},
    );
    return StoreDetail.fromJson(_unwrapData(root));
  }

  Future<void> toggleStoreStatus({required int storeId, required String token}) async {
    await _client.post<Object>(
      '/stores/status/$storeId',
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  Future<DailyMenuResponse?> getDailyMenu({required int storeId, required String date, required String token}) async {
    final root = await _client.get<Map<String, dynamic>>(
      '/menus/daily/$storeId/groups',
      queryParameters: {'date': date},
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = root['data'];
    if (data == null) return null;
    if (data is Map<String, dynamic>) return DailyMenuResponse.fromJson(data);

    final unwrapped = _unwrapData(root);
    if (unwrapped.isEmpty) return null;
    return DailyMenuResponse.fromJson(unwrapped);
  }

  Future<WeeklyMenuResponse> getWeeklyMenu({required int storeId, required String date, required String token}) async {
    final root = await _client.get<Map<String, dynamic>>(
      '/menus/daily/weekly/$storeId/groups',
      queryParameters: {'date': date},
      headers: {'Authorization': 'Bearer $token'},
    );

    final unwrapped = _unwrapData(root);
    return WeeklyMenuResponse.fromJson(unwrapped);
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Menu-group 기반 API
  // ────────────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> createMenuGroup({
    required int storeId,
    required String name,
    required int sortOrder,
    required int capacity,
    required String token,
  }) async {
    final root = await _client.post<Map<String, dynamic>>(
      '/menus/daily/$storeId/groups',
      headers: {'Authorization': 'Bearer $token'},
      data: {
        'name': name,
        'sortOrder': sortOrder,
        'capacity': capacity,
      },
    );
    return _unwrapData(root);
  }

  Future<MenuGroupMenusResponse> upsertMenuGroupMenus({
    required int groupId,
    required String date,
    required List<String> menus,
    required String token,
  }) async {
    final root = await _client.post<Map<String, dynamic>>(
      '/menus/daily/groups/$groupId/menus',
      queryParameters: {'date': date},
      headers: {'Authorization': 'Bearer $token'},
      data: {'menus': menus},
    );
    return MenuGroupMenusResponse.fromJson(_unwrapData(root));
  }

  Future<Map<String, dynamic>> updateMenuGroupStock({
    required int groupId,
    required int stock,
    required String token,
  }) async {
    final root = await _client.post<Map<String, dynamic>>(
      '/menus/daily/groups/$groupId/stock',
      headers: {'Authorization': 'Bearer $token'},
      data: {'stock': stock},
    );
    return _unwrapData(root);
  }

  Future<Map<String, dynamic>> deductMenuGroupStock({
    required int groupId,
    required DeductionUnit deductionUnit,
    required String token,
  }) async {
    final root = await _client.patch<Map<String, dynamic>>(
      '/menus/daily/groups/$groupId/deduct',
      queryParameters: {'deductionUnit': deductionUnit.apiValue},
      headers: {'Authorization': 'Bearer $token'},
    );
    return _unwrapData(root);
  }

  // ────────────────────────────────────────────────────────────────────────────
  // 레거시 호환 (Next.js도 deprecated로 유지 중)
  // ────────────────────────────────────────────────────────────────────────────

  Future<DailyMenuResponse> saveDailyMenu({
    required int storeId,
    required String date,
    required List<String> menus,
    required String token,
  }) async {
    final root = await _client.post<Map<String, dynamic>>(
      '/menus/daily/$storeId/groups',
      queryParameters: {'date': date},
      headers: {'Authorization': 'Bearer $token'},
      data: {'menus': menus},
    );
    return DailyMenuResponse.fromJson(_unwrapData(root));
  }

  Future<void> updateDailyStock({required int menuId, required int stock, required String token}) async {
    await _client.post<Object>(
      '/menus/daily/group/$menuId/stock',
      headers: {'Authorization': 'Bearer $token'},
      data: {'stock': stock},
    );
  }

  // 자주 쓰는 메뉴 API
  Future<FavoritesResponse> getFavorites({required int storeId, required String token}) async {
    final root = await _client.get<Map<String, dynamic>>(
      '/favorites/store/$storeId',
      headers: {'Authorization': 'Bearer $token'},
    );
    return FavoritesResponse.fromJson(_unwrapData(root));
  }

  Future<FavoritesResponse> getFavoriteGroup({required int groupId, required String token}) async {
    final root = await _client.get<Map<String, dynamic>>(
      '/favorites/group/$groupId',
      headers: {'Authorization': 'Bearer $token'},
    );
    return FavoritesResponse.fromJson(_unwrapData(root));
  }

  Future<void> createFavorite({required int storeId, required List<String> menus, required String token}) async {
    await _client.post<Object>(
      '/favorites/$storeId',
      headers: {'Authorization': 'Bearer $token'},
      data: menus,
    );
  }

  Future<void> updateFavorite({required int groupId, required List<String> menus, required String token}) async {
    await _client.put<Object>(
      '/favorites/$groupId',
      headers: {'Authorization': 'Bearer $token'},
      data: menus,
    );
  }

  Future<void> deleteFavorites({required int storeId, required List<int> groupIds, required String token}) async {
    await _client.delete<Object>(
      '/favorites/$storeId/groups',
      headers: {'Authorization': 'Bearer $token'},
      data: groupIds,
    );
  }
}

