import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';

import '../../../common/dio/api_error_mapper.dart';
import '../../../common/dio/api_exception.dart';
import '../repositories/admin_repository.dart';

class AdminFrequentMenuEditViewModel extends ChangeNotifier {
  AdminFrequentMenuEditViewModel(
    this._repo, {
    required this.groupId,
    this.presetId,
  });

  final AdminRepository _repo;
  final int groupId; // 일일 메뉴 그룹 ID
  final int? presetId; // null이면 새로 만들기, 있으면 수정(로드 후 저장 시 삭제+생성)

  bool loading = false;
  bool saving = false;
  String? errorMessage;
  List<String> menus = [];
  List<String> _initialMenus = []; // 서버에서 불러온 초기 메뉴 (dirty 비교용)
  String input = '';
  bool dirty = false;
  bool showConfirm = false;
  VoidCallback? pendingAction;
  bool showSavedToast = false;

  Future<void> init() async {
    if (presetId == null) return; // 새로 만들기는 로딩 불필요
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final detail = await _repo.getMenuPresetDetail(
        groupId: groupId,
        presetId: presetId!,
      );
      menus = List<String>.from(detail.menus);
      _initialMenus = List<String>.from(menus); //서버에서 받은 메뉴를 초기 상태로 저장
      dirty = false;
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

  // menus와 _initialMenus를 비교해서 dirty 상태 업데이트
  void _updateDirty() {
    dirty = !const ListEquality<String>().equals(menus, _initialMenus);
  }

  void addMenu() {
    // 기존에는 dirty = true로 바로 바꿨지만, _updateDirty()로 변경해서 menus와 _initialMenus를 비교하도록 수정.
    final text = input.trim();
    if (text.isEmpty) return;
    menus = [...menus, text];
    input = '';
    _updateDirty();
    notifyListeners();
  }

  void removeMenu(int index) {
    // 기존에는 dirty = true로 바로 바꿨지만, _updateDirty()로 변경해서 menus와 _initialMenus를 비교하도록 수정.
    menus = menus
        .asMap()
        .entries
        .where((entry) => entry.key != index)
        .map((entry) => entry.value)
        .toList();
    _updateDirty();
    notifyListeners();
  }

  Future<void> save() async {
    saving = true;
    errorMessage = null;
    notifyListeners();
    try {
      if (menus.isEmpty && presetId != null) {
        // 기존 프리셋에서 메뉴를 전부 삭제한 경우 -> 빈 배열 post (X) 프리셋 자체 삭제 (O)
        await _repo.deleteMenuPreset(groupId: groupId, presetId: presetId!);
      } else if (menus.isNotEmpty) {
        // 메뉴 1개 이상 있는 경우
        if (presetId != null) {
          // 수정 모드 -> 기존 프리셋 delete 후 새로 만들기
          await _repo.deleteMenuPreset(groupId: groupId, presetId: presetId!);
        }
        //새로 만들기 모드에서는 post
        await _repo.createMenuPreset(groupId: groupId, menus: menus);
      }
      // 저장 후 현재 메뉴를 새로운 초기 상태로 갱신하고 dirty 상태 업데이트
      _initialMenus = List<String>.from(menus);
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
