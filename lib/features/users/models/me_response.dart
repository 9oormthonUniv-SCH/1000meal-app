import '../../auth/models/role.dart';

class MeResponse {
  final Role role;

  MeResponse({required this.role});

  factory MeResponse.fromJson(Map<String, dynamic> json) {
    return MeResponse(role: RoleApi.fromApi((json['role'] ?? 'STUDENT').toString()));
  }
}


