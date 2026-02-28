import '../../../common/dio/api_exception.dart';
import '../../auth/repositories/auth_repository.dart';
import '../data/store_api.dart';
import '../models/store_models.dart';

class StoreRepository {
  final StoreApi _api;
  final AuthRepository _authRepo;
  StoreRepository(this._api, this._authRepo);

  Future<List<StoreListItem>> getStoreList() => _api.getStoreList();

  Future<StoreDetail> getStoreDetail(int id) => _api.getStoreDetail(id);

  Future<List<int>> getFavoriteStoreIds() async {
    final token = await _authRepo.getAccessToken();
    if (token == null || token.isEmpty) throw ApiException('로그인이 필요합니다.');
    return _api.getFavoriteStoreIds(token: token);
  }

  Future<FavoriteToggleResponse> favoriteStore(int storeId) async {
    final token = await _authRepo.getAccessToken();
    if (token == null || token.isEmpty) throw ApiException('로그인이 필요합니다.');
    return _api.favoriteStore(storeId: storeId, token: token);
  }

  Future<FavoriteToggleResponse> unfavoriteStore(int storeId) async {
    final token = await _authRepo.getAccessToken();
    if (token == null || token.isEmpty) throw ApiException('로그인이 필요합니다.');
    return _api.unfavoriteStore(storeId: storeId, token: token);
  }
}
