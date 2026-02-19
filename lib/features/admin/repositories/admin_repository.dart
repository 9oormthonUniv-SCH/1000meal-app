import '../../../common/dio/api_exception.dart';
import '../../../common/utils/jwt_payload.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../users/models/me_response.dart';
import '../data/admin_api.dart';
import '../models/menu_models.dart';
import '../models/store_models.dart';

class AdminRepository {
  final AuthRepository _authRepo;
  final AdminApi _api;

  AdminRepository({required AuthRepository authRepo, required AdminApi api})
      : _authRepo = authRepo,
        _api = api;

  Future<String> _requireToken() async {
    final token = await _authRepo.getAccessToken();
    if (token == null || token.isEmpty) throw ApiException('로그인이 필요합니다.');
    return token;
  }

  Future<int> _requireStoreId(String token) async {
    final fromToken = getStoreIdFromToken(token);
    if (fromToken != null) return fromToken;

    // fallback: /auth/me
    final me = await _authRepo.getMe();
    if (me.storeId == null) throw ApiException('가게 정보가 없습니다.');
    return me.storeId!;
  }

  Future<MeResponse> getMe() => _authRepo.getMe();

  Future<StoreDetail> getStoreDetail() async {
    final token = await _requireToken();
    final storeId = await _requireStoreId(token);
    return _api.getStoreDetail(storeId: storeId, token: token);
  }

  Future<void> toggleStoreStatus() async {
    final token = await _requireToken();
    final storeId = await _requireStoreId(token);
    await _api.toggleStoreStatus(storeId: storeId, token: token);
  }

  Future<DailyMenuResponse?> getDailyMenu({required String date}) async {
    final token = await _requireToken();
    final storeId = await _requireStoreId(token);
    return _api.getDailyMenu(storeId: storeId, date: date, token: token);
  }

  Future<void> updateDailyStock({required int menuId, required int stock}) async {
    final token = await _requireToken();
    await _api.updateDailyStock(menuId: menuId, stock: stock, token: token);
  }

  Future<WeeklyMenuResponse> getWeeklyMenu({required String date}) async {
    final token = await _requireToken();
    final storeId = await _requireStoreId(token);
    return _api.getWeeklyMenu(storeId: storeId, date: date, token: token);
  }

  Future<DailyMenuResponse> saveDailyMenu({required String date, required List<String> menus}) async {
    final token = await _requireToken();
    final storeId = await _requireStoreId(token);
    return _api.saveDailyMenu(storeId: storeId, date: date, menus: menus, token: token);
  }

  Future<Map<String, dynamic>> createMenuGroup({
    required String name,
    required int sortOrder,
    required int capacity,
  }) async {
    final token = await _requireToken();
    final storeId = await _requireStoreId(token);
    return _api.createMenuGroup(
      storeId: storeId,
      name: name,
      sortOrder: sortOrder,
      capacity: capacity,
      token: token,
    );
  }

  Future<MenuGroupMenusResponse> upsertMenuGroupMenus({
    required int groupId,
    required String date,
    required List<String> menus,
  }) async {
    final token = await _requireToken();
    final storeId = await _requireStoreId(token);
    return _api.upsertMenuGroupMenus(
      storeId: storeId,
      groupId: groupId,
      date: date,
      menus: menus,
      token: token,
    );
  }

  Future<Map<String, dynamic>> updateMenuGroupStock({
    required int groupId,
    required int stock,
  }) async {
    final token = await _requireToken();
    return _api.updateMenuGroupStock(groupId: groupId, stock: stock, token: token);
  }

  Future<Map<String, dynamic>> deductMenuGroupStock({
    required int groupId,
    required DeductionUnit deductionUnit,
  }) async {
    final token = await _requireToken();
    return _api.deductMenuGroupStock(groupId: groupId, deductionUnit: deductionUnit, token: token);
  }

  // 자주 쓰는 메뉴 API (menu-presets: storeId + groupId = 일일 메뉴 그룹)
  Future<List<MenuPreset>> getMenuPresets({required int groupId}) async {
    final token = await _requireToken();
    final storeId = await _requireStoreId(token);
    return _api.getMenuPresets(storeId: storeId, groupId: groupId, token: token);
  }

  Future<MenuPresetDetail> getMenuPresetDetail({required int groupId, required int presetId}) async {
    final token = await _requireToken();
    final storeId = await _requireStoreId(token);
    return _api.getMenuPresetDetail(
      storeId: storeId,
      groupId: groupId,
      presetId: presetId,
      token: token,
    );
  }

  Future<MenuPresetDetail> createMenuPreset({required int groupId, required List<String> menus}) async {
    final token = await _requireToken();
    final storeId = await _requireStoreId(token);
    return _api.createMenuPreset(
      storeId: storeId,
      groupId: groupId,
      menus: menus,
      token: token,
    );
  }

  Future<void> deleteMenuPreset({required int groupId, required int presetId}) async {
    final token = await _requireToken();
    final storeId = await _requireStoreId(token);
    await _api.deleteMenuPreset(
      storeId: storeId,
      groupId: groupId,
      presetId: presetId,
      token: token,
    );
  }

  /// 메뉴 수정 화면용: 해당 그룹의 프리셋 목록을 FavoriteGroup 형태로 (preview만)
  Future<FavoritesResponse> getFavoritesForGroup({required int groupId}) async {
    final presets = await getMenuPresets(groupId: groupId);
    return FavoritesResponse.fromPresetList(presets);
  }
}

