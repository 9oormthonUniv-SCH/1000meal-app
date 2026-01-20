import '../data/store_api.dart';
import '../models/store_models.dart';

class StoreRepository {
  final StoreApi _api;
  StoreRepository(this._api);

  Future<List<StoreListItem>> getStoreList() => _api.getStoreList();

  Future<StoreDetail> getStoreDetail(int id) => _api.getStoreDetail(id);
}
