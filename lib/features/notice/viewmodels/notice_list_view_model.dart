import 'package:flutter/foundation.dart';

import '../../../common/dio/api_error_mapper.dart';
import '../../../common/dio/api_exception.dart';
import '../../../common/utils/jwt_payload.dart';
import '../../auth/repositories/auth_repository.dart';
import '../models/notice_models.dart';
import '../repositories/notice_repository.dart';

class NoticeListViewModel extends ChangeNotifier {
  NoticeListViewModel(this._repo, this._authRepo);

  final NoticeRepository _repo;
  final AuthRepository _authRepo;

  bool loading = false;
  String? errorMessage;
  bool isAdmin = false;

  List<Notice> notices = const <Notice>[];
  bool _didLoadOnce = false;

  Future<void> _syncIsAdmin({bool notifyIfChanged = true}) async {
    final token = await _authRepo.getAccessToken();
    final nextIsAdmin = token != null && token.isNotEmpty && decodeJwtPayload(token)?.role == 'ADMIN';
    if (nextIsAdmin == isAdmin) return;
    isAdmin = nextIsAdmin;
    if (notifyIfChanged) notifyListeners();
  }

  Future<void> ensureLoaded() async {
    // VM is app-scoped; user can login/logout without recreating it.
    // Always re-sync admin flag from latest token to avoid stale UI.
    await _syncIsAdmin();
    if (_didLoadOnce) return;
    _didLoadOnce = true;
    await refresh();
  }

  Future<void> refresh() async {
    loading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final token = await _authRepo.getAccessToken();
      isAdmin = token != null && token.isNotEmpty && decodeJwtPayload(token)?.role == 'ADMIN';

      final res = await _repo.getNotices();
      final sorted = [...res]..sort(_noticeComparator);
      notices = sorted;
    } catch (e) {
      if (e is ApiException) {
        errorMessage = mapErrorToMessage(e, responseData: e.details);
      } else {
        errorMessage = '공지사항 불러오기 실패';
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  static int _noticeComparator(Notice a, Notice b) {
    // isPinned true 먼저
    if (a.isPinned != b.isPinned) return (b.isPinned ? 1 : 0) - (a.isPinned ? 1 : 0);

    // createdAt 최신순
    final ad = a.createdAtDateTime ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bd = b.createdAtDateTime ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bd.compareTo(ad);
  }
}

