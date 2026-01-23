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
      '/menus/daily/$storeId',
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

  Future<void> updateDailyStock({required int menuId, required int stock, required String token}) async {
    await _client.post<Object>(
      '/menus/daily/stock/$menuId',
      headers: {'Authorization': 'Bearer $token'},
      data: {'stock': stock},
    );
  }

  Future<WeeklyMenuResponse> getWeeklyMenu({required int storeId, required String date, required String token}) async {
    final root = await _client.get<Map<String, dynamic>>(
      '/menus/weekly/$storeId',
      queryParameters: {'date': date},
      headers: {'Authorization': 'Bearer $token'},
    );

    final unwrapped = _unwrapData(root);
    return WeeklyMenuResponse.fromJson(unwrapped);
  }

  Future<DailyMenuResponse> saveDailyMenu({
    required int storeId,
    required String date,
    required List<String> menus,
    required String token,
  }) async {
    final root = await _client.post<Map<String, dynamic>>(
      '/menus/daily/$storeId',
      headers: {'Authorization': 'Bearer $token'},
      data: {'date': date, 'menus': menus},
    );
    return DailyMenuResponse.fromJson(_unwrapData(root));
  }
}

