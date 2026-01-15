import '../../../common/dio/dio_client.dart';
import '../../users/models/me_response.dart';
import '../models/login_models.dart';

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
}


