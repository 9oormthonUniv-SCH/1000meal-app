import '../../../common/dio/dio_client.dart';
import '../../users/models/me_response.dart';
import '../models/login_models.dart';
import '../models/account_recovery_models.dart';
import '../models/email_change_models.dart';
import '../models/signup_models.dart';

class AuthApi {
  final DioClient _client;

  AuthApi(this._client);

  Map<String, dynamic> _unwrapData(Map<String, dynamic> root) {
    // 서버가 { data: {...}, result: {...}, errors: ... } 형태로 감싸서 내려주는 케이스 대응
    final inner = root['data'];
    if (inner is Map<String, dynamic>) return inner;
    return root;
  }

  Future<LoginResponse> login(LoginRequest request) async {
    final root = await _client.post<Map<String, dynamic>>(
      '/auth/login',
      data: request.toJson(),
    );
    return LoginResponse.fromJson(_unwrapData(root));
  }

  Future<MeResponse> getMe(String token) async {
    final root = await _client.get<Map<String, dynamic>>(
      '/auth/me',
      headers: {'Authorization': 'Bearer $token'},
    );
    return MeResponse.fromJson(_unwrapData(root));
  }

  Future<VerifyIdResponse> verifyId(String userId) async {
    final root = await _client.post<Map<String, dynamic>>(
      '/signup/user/validate-id',
      data: {'userId': userId},
    );
    return VerifyIdResponse.fromJson(_unwrapData(root));
  }

  Future<void> signUp(SignUpRequest request) async {
    await _client.post<Object>(
      '/auth/signup',
      data: request.toJson(),
    );
  }

  Future<bool> getSignupEmailStatus(String email) async {
    final root = await _client.get<Map<String, dynamic>>(
      '/auth/email/status',
      queryParameters: {'email': email},
    );
    // 서버가 data에 bool을 주거나, data에 { verified: bool } 형태를 줄 수 있음
    final data = root['data'];
    if (data is bool) return data;
    if (data is String) return data.toLowerCase() == 'true';

    final unwrapped = _unwrapData(root);
    final v = unwrapped['verified'];
    if (v is bool) return v;
    if (v is String) return v.toLowerCase() == 'true';
    return false;
  }

  Future<void> sendEmailVerification(String email) async {
    await _client.post<Object>(
      '/auth/email/send',
      data: {'email': email},
    );
  }

  Future<void> verifyEmail({required String email, required String code}) async {
    await _client.post<Object>(
      '/auth/email/verify',
      data: {'email': email, 'code': code},
    );
  }

  Future<FindUserIdResponse> findUserId(FindUserIdRequest request) async {
    final root = await _client.post<Map<String, dynamic>>(
      '/auth/find-id',
      data: request.toJson(),
    );
    return FindUserIdResponse.fromJson(_unwrapData(root));
  }

  Future<void> resetPasswordRequest(String email) async {
    await _client.post<Object>(
      '/auth/password/reset/request',
      data: {'email': email},
    );
  }

  Future<void> resetPasswordConfirm(ResetPasswordConfirmRequest request) async {
    await _client.post<Object>(
      '/auth/password/reset/confirm',
      data: request.toJson(),
    );
  }

  Future<void> deleteAccount({required String token, required String currentPassword, required bool agree}) async {
    await _client.post<Object>(
      '/auth/delete-account',
      headers: {'Authorization': 'Bearer $token'},
      data: {
        'currentPassword': currentPassword,
        'agree': agree,
      },
    );
  }

  Future<StartEmailChangeResponse> startEmailChange({
    required String token,
    required StartEmailChangeRequest request,
  }) async {
    final root = await _client.post<Map<String, dynamic>>(
      '/account/email/start',
      headers: {'Authorization': 'Bearer $token'},
      data: request.toJson(),
    );
    return StartEmailChangeResponse.fromJson(_unwrapData(root));
  }

  Future<void> sendEmailChangeCode({
    required String token,
    required SendEmailChangeCodeRequest request,
  }) async {
    await _client.post<Object>(
      '/account/email/code',
      headers: {'Authorization': 'Bearer $token'},
      data: request.toJson(),
    );
  }

  Future<VerifyEmailChangeResponse> verifyEmailChange({
    required String token,
    required VerifyEmailChangeRequest request,
  }) async {
    final root = await _client.post<Map<String, dynamic>>(
      '/account/email/verify',
      headers: {'Authorization': 'Bearer $token'},
      data: request.toJson(),
    );
    return VerifyEmailChangeResponse.fromJson(_unwrapData(root));
  }
}


