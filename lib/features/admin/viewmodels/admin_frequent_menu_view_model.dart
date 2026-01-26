import 'package:flutter/foundation.dart';

import '../../../common/dio/api_error_mapper.dart';
import '../../../common/dio/api_exception.dart';
import '../models/menu_models.dart';
import '../repositories/admin_repository.dart';

class AdminFrequentMenuViewModel extends ChangeNotifier {
  AdminFrequentMenuViewModel(this._repo);

  final AdminRepository _repo;

  bool loading = false;
  String? errorMessage;
  List<FavoriteGroup> groups = [];

  Future<void> init() async {
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final res = await _repo.getFavorites();
      groups = res.groups;
    } catch (e) {
      if (e is ApiException) {
        errorMessage = mapErrorToMessage(e, responseData: e.details);
      } else {
        errorMessage = '자주 쓰는 메뉴 불러오기 실패';
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> deleteGroups(List<int> groupIds) async {
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repo.deleteFavorites(groupIds: groupIds);
      groups = groups.where((g) => !groupIds.contains(g.groupId)).toList();
    } catch (e) {
      if (e is ApiException) {
        errorMessage = mapErrorToMessage(e, responseData: e.details);
      } else {
        errorMessage = '삭제 실패';
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await init();
  }
}
