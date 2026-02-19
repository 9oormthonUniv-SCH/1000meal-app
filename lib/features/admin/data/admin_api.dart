import '../../../common/dio/api_exception.dart';
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
    required int storeId,
    required int groupId,
    required String date,
    required List<String> menus,
    required String token,
  }) async {
    final root = await _client.post<Map<String, dynamic>>(
      '/stores/$storeId/menus/daily/groups/$groupId/menus',
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

  // 자주 쓰는 메뉴 API (menu-presets)
  // GET .../menu-presets → 200 목록, 404 MENU_PRESET_EMPTY 시 빈 목록 반환
  Future<List<MenuPreset>> getMenuPresets({
    required int storeId,
    required int groupId,
    required String token,
  }) async {
    try {
      final root = await _client.get<Map<String, dynamic>>(
        '/admin/stores/$storeId/menus/daily/groups/$groupId/menu-presets',
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = root['data'];
      final list = data is List ? data : <dynamic>[];
      return list
          .whereType<Map<String, dynamic>>()
          .map(MenuPreset.fromJson)
          .toList(growable: false);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return []; // MENU_PRESET_EMPTY
      rethrow;
    }
  }

  Future<MenuPresetDetail> getMenuPresetDetail({
    required int storeId,
    required int groupId,
    required int presetId,
    required String token,
  }) async {
    final root = await _client.get<Map<String, dynamic>>(
      '/admin/stores/$storeId/menus/daily/groups/$groupId/menu-presets/$presetId',
      headers: {'Authorization': 'Bearer $token'},
    );
    return MenuPresetDetail.fromJson(_unwrapData(root));
  }

  Future<MenuPresetDetail> createMenuPreset({
    required int storeId,
    required int groupId,
    required List<String> menus,
    required String token,
  }) async {
    final root = await _client.post<Map<String, dynamic>>(
      '/admin/stores/$storeId/menus/daily/groups/$groupId/menu-presets',
      headers: {'Authorization': 'Bearer $token'},
      data: {'menus': menus},
    );
    return MenuPresetDetail.fromJson(_unwrapData(root));
  }

  Future<void> deleteMenuPreset({
    required int storeId,
    required int groupId,
    required int presetId,
    required String token,
  }) async {
    await _client.delete<Object>(
      '/admin/stores/$storeId/menus/daily/groups/$groupId/menu-presets/$presetId',
      headers: {'Authorization': 'Bearer $token'},
    );
  }
}

