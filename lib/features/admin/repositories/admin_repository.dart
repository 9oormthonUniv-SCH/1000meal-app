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

  // 자주 쓰는 메뉴 API
  Future<FavoritesResponse> getFavorites() async {
    final token = await _requireToken();
    final storeId = await _requireStoreId(token);
    return _api.getFavorites(storeId: storeId, token: token);
  }

  Future<FavoritesResponse> getFavoriteGroup({required int groupId}) async {
    final token = await _requireToken();
    return _api.getFavoriteGroup(groupId: groupId, token: token);
  }

  Future<void> createFavorite({required List<String> menus}) async {
    final token = await _requireToken();
    final storeId = await _requireStoreId(token);
    await _api.createFavorite(storeId: storeId, menus: menus, token: token);
  }

  Future<void> updateFavorite({required int groupId, required List<String> menus}) async {
    final token = await _requireToken();
    await _api.updateFavorite(groupId: groupId, menus: menus, token: token);
  }

  Future<void> deleteFavorites({required List<int> groupIds}) async {
    final token = await _requireToken();
    final storeId = await _requireStoreId(token);
    await _api.deleteFavorites(storeId: storeId, groupIds: groupIds, token: token);
  }
}

