import 'package:flutter/foundation.dart';

import '../../auth/repositories/auth_repository.dart';
import '../../users/models/me_response.dart';

class AdminHomeViewModel extends ChangeNotifier {
  AdminHomeViewModel(this._repo);

  final AuthRepository _repo;

  bool loading = false;
  String? errorMessage;
  MeResponse? me;

  Future<void> load() async {
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      me = await _repo.getMe();
    } catch (_) {
      errorMessage = '불러오기에 실패했습니다.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}


