import 'package:flutter/material.dart';

/// 앱 전역 인증 상태. refresh 만료 등 세션이 끊긴 시점을 알려서
/// 라우터/홈에서 로그인 화면으로 강제 이동시키는 신호로 사용.
class AuthProvider extends ChangeNotifier {
  bool _sessionExpired = false;
  String? _expiredReasonMessage;

  bool get sessionExpired => _sessionExpired;
  String? get expiredReasonMessage => _expiredReasonMessage;

  /// refresh 실패(만료/무효/철회) 등으로 세션이 끊겼음을 알린다.
  void notifySessionExpired({String? message}) {
    if (_sessionExpired) return;
    _sessionExpired = true;
    _expiredReasonMessage = message ?? '세션이 만료되었습니다. 다시 로그인해주세요.';
    notifyListeners();
  }

  /// 로그인 화면 이동 후 사용자가 다시 로그인했거나, 안내 처리가 끝난 뒤 리셋.
  void consume() {
    if (!_sessionExpired) return;
    _sessionExpired = false;
    _expiredReasonMessage = null;
    notifyListeners();
  }
}
