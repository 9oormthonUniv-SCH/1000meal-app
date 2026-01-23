import 'package:flutter/foundation.dart';

import '../../../common/dio/api_error_mapper.dart';
import '../../../common/dio/api_exception.dart';
import '../repositories/admin_repository.dart';

class AdminFrequentMenuEditViewModel extends ChangeNotifier {
  AdminFrequentMenuEditViewModel(this._repo, {this.groupId});

  final AdminRepository _repo;
  final int? groupId; // null이면 새로 만들기, 있으면 수정

  bool loading = false;
  bool saving = false;
  String? errorMessage;
  List<String> menus = [];
  String input = '';
  bool dirty = false;
  bool showConfirm = false;
  VoidCallback? pendingAction;
  bool showSavedToast = false;

  Future<void> init() async {
    if (groupId == null) return; // 새로 만들기는 로딩 불필요
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final res = await _repo.getFavoriteGroup(groupId: groupId!);
      if (res.groups.isNotEmpty) {
        menus = List<String>.from(res.groups.first.menu);
      }
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

  void setInput(String value) {
    input = value;
    notifyListeners();
  }

  void addMenu() {
    final text = input.trim();
    if (text.isEmpty) return;
    menus = [...menus, text];
    input = '';
    dirty = true;
    notifyListeners();
  }

  void removeMenu(int index) {
    menus = menus.asMap().entries.where((entry) => entry.key != index).map((entry) => entry.value).toList();
    dirty = true;
    notifyListeners();
  }

  Future<void> save() async {
    saving = true;
    errorMessage = null;
    notifyListeners();
    try {
      if (groupId == null) {
        await _repo.createFavorite(menus: menus);
      } else {
        await _repo.updateFavorite(groupId: groupId!, menus: menus);
      }
      dirty = false;
      showSavedToast = true;
      notifyListeners();
    } catch (e) {
      if (e is ApiException) {
        errorMessage = mapErrorToMessage(e, responseData: e.details);
      } else {
        errorMessage = '저장 실패';
      }
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  void hideToast() {
    showSavedToast = false;
    notifyListeners();
  }

  void setDirty(bool value) {
    dirty = value;
    notifyListeners();
  }

  void setShowConfirm(bool value) {
    showConfirm = value;
    notifyListeners();
  }

  void setPendingAction(VoidCallback? action) {
    pendingAction = action;
    notifyListeners();
  }
}
