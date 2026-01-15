import '../../../common/dio/api_exception.dart';
import '../../../common/storage/token_storage.dart';
import '../../users/models/me_response.dart';
import '../data/auth_api.dart';
import '../models/login_models.dart';
import '../models/role.dart';
import '../models/signup_models.dart';

class AuthRepository {
  final AuthApi _api;
  final TokenStorage _tokenStorage;

  AuthRepository({required AuthApi api, required TokenStorage tokenStorage})
      : _api = api,
        _tokenStorage = tokenStorage;

  Future<Role> login({required Role role, required String userId, required String password}) async {
    final res = await _api.login(LoginRequest(role: role, userId: userId, password: password));
    if (res.accessToken.isEmpty) throw ApiException('로그인에 실패했습니다.');
    await _tokenStorage.setAccessToken(res.accessToken);
    final me = await _api.getMe(res.accessToken);
    return me.role;
  }

  Future<String?> getAccessToken() => _tokenStorage.getAccessToken();

  Future<void> logout() => _tokenStorage.clear();

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
}


