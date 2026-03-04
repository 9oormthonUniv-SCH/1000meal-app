import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../common/dio/api_exception.dart';
import '../../../common/notification/fcm_notification_storage.dart';
import '../../../common/storage/login_preference_storage.dart';
import '../../../common/storage/token_storage.dart';
import '../../../common/utils/jwt_payload.dart';
import '../../users/models/me_response.dart';
import '../data/auth_api.dart';
import '../models/account_recovery_models.dart';
import '../models/login_models.dart';
import '../models/email_change_models.dart';
import '../models/role.dart';
import '../models/signup_models.dart';

class AuthRepository {
  final AuthApi _api;
  final TokenStorage _tokenStorage;
  final LoginPreferenceStorage? _loginPreferenceStorage;

  AuthRepository({
    required AuthApi api,
    required TokenStorage tokenStorage,
    LoginPreferenceStorage? loginPreferenceStorage,
  })  : _api = api,
        _tokenStorage = tokenStorage,
        _loginPreferenceStorage = loginPreferenceStorage;

  Future<Role> login({required Role role, required String userId, required String password}) async {
    final res = await _api.login(LoginRequest(role: role, userId: userId, password: password));
    if (res.accessToken.isEmpty) throw ApiException('로그인에 실패했습니다.');
    await _tokenStorage.setAccessToken(res.accessToken);
    if (res.refreshToken != null && res.refreshToken!.isNotEmpty) {
      await _tokenStorage.setRefreshToken(res.refreshToken!);
    }
    final accountKey = getAccountIdFromToken(res.accessToken);
    if (accountKey != null && accountKey.isNotEmpty) {
      await setCurrentAccountKeyForNotifications(accountKey);
    }
    final me = await _api.getMe(res.accessToken);
    await _registerFcmTokenIfAvailable(res.accessToken);
    return me.role;
  }

  /// FCM 토큰이 있으면 백엔드에 등록 (로그인 직후·앱 실행 시 호출).
  /// 앱 재시작 시 현재 계정 키가 없으면 토큰에서 복구.
  Future<void> registerFcmTokenIfLoggedIn() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) return;
    final currentKey = await getCurrentAccountKeyForNotifications();
    if (currentKey == null || currentKey.isEmpty) {
      final accountKey = getAccountIdFromToken(token);
      if (accountKey != null && accountKey.isNotEmpty) {
        await setCurrentAccountKeyForNotifications(accountKey);
      }
    }
    await _registerFcmTokenIfAvailable(token);
  }

  /// 푸시 알림 권한이 허용됐는지 (실제 시스템/FCM 상태)
  Future<bool> getPushPermissionStatus() async {
    try {
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      switch (settings.authorizationStatus) {
        case AuthorizationStatus.authorized:
        case AuthorizationStatus.provisional:
          return true;
        default:
          return false;
      }
    } catch (_) {
      return false;
    }
  }

  /// 푸시 알림 권한 요청. 허용되면 true.
  Future<bool> requestPushPermission() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (_) {
      return false;
    }
  }

  Future<void> _registerFcmTokenIfAvailable(String accessToken) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null && fcmToken.isNotEmpty) {
        final platform = Platform.isIOS ? 'IOS' : 'ANDROID';
        await _api.registerFcmToken(
          token: accessToken,
          fcmToken: fcmToken,
          platform: platform,
        );
      }
    } catch (_) {
      // 등록 실패해도 로그인/앱 흐름은 유지
    }
  }

  Future<String?> getAccessToken() => _tokenStorage.getAccessToken();

  /// Refresh Token으로 새 Access Token 발급 후 저장. 성공 시 새 accessToken 반환, 실패 시 예외.
  Future<String> refreshAccessToken() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      throw ApiException('로그인이 필요합니다.');
    }
    final res = await _api.refresh(refreshToken);
    if (res.accessToken.isEmpty) throw ApiException('토큰 갱신에 실패했습니다.');
    await _tokenStorage.setAccessToken(res.accessToken);
    return res.accessToken;
  }

  /// 토큰만 삭제 (로그인 설정·알림 키는 유지). 자동 로그인 테스트용.
  Future<void> clearTokensOnly() async {
    try {
      await _tokenStorage.clear().timeout(const Duration(seconds: 2));
    } catch (_) {
      // ignore
    }
  }

  /// Best-effort logout.
  /// Some platforms/plugins may hang on secure storage operations in edge cases.
  /// To prevent infinite loading UX, we harden this with timeout and ignore errors.
  Future<void> logout() async {
    try {
      await _tokenStorage.clear().timeout(const Duration(seconds: 2));
      await setCurrentAccountKeyForNotifications(null);
      await _loginPreferenceStorage?.setSkipAutoLoginOnce();
    } catch (_) {
      // ignore
    }
  }

  Future<MeResponse> getMe() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) throw ApiException('로그인이 필요합니다.');
    return _api.getMe(token);
  }

  Future<VerifyIdResponse> verifyId(String userId) => _api.verifyId(userId);

  Future<void> signUp(SignUpRequest request) => _api.signUp(request);

  Future<bool> getSignupEmailStatus(String email) => _api.getSignupEmailStatus(email);

  Future<void> sendEmailVerification(String email) => _api.sendEmailVerification(email);

  Future<void> verifyEmail({required String email, required String code}) => _api.verifyEmail(email: email, code: code);

  Future<FindUserIdResponse> findUserId({required String name, required String email}) =>
      _api.findUserId(FindUserIdRequest(name: name, email: email));

  Future<void> resetPasswordRequest(String email) => _api.resetPasswordRequest(email);

  Future<void> resetPasswordConfirm(ResetPasswordConfirmRequest request) => _api.resetPasswordConfirm(request);

  Future<void> deleteAccount({required String currentPassword, required bool agree}) async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) throw ApiException('로그인이 필요합니다.');
    await _api.deleteAccount(token: token, currentPassword: currentPassword, agree: agree);
  }

  Future<StartEmailChangeResponse> startEmailChange({required String currentEmail, required String password}) async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) throw ApiException('로그인이 필요합니다.');
    return _api.startEmailChange(
      token: token,
      request: StartEmailChangeRequest(currentEmail: currentEmail, password: password),
    );
  }

  Future<void> sendEmailChangeCode({required String changeId, required String newEmail}) async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) throw ApiException('로그인이 필요합니다.');
    await _api.sendEmailChangeCode(
      token: token,
      request: SendEmailChangeCodeRequest(changeId: changeId, newEmail: newEmail),
    );
  }

  Future<VerifyEmailChangeResponse> verifyEmailChange({required String changeId, required String code}) async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) throw ApiException('로그인이 필요합니다.');
    return _api.verifyEmailChange(
      token: token,
      request: VerifyEmailChangeRequest(changeId: changeId, code: code),
    );
  }
}


