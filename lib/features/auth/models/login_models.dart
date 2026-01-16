import 'role.dart';

class LoginRequest {
  final Role role;
  final String userId;
  final String password;

  LoginRequest({required this.role, required this.userId, required this.password});

  Map<String, dynamic> toJson() => {
        'role': role.toApi(),
        // 웹 payload 키와 동일
        'user_id': userId,
        'password': password,
      };
}

class LoginResponse {
  final String accessToken;
  final String? refreshToken;

  LoginResponse({required this.accessToken, this.refreshToken});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: (json['accessToken'] ?? '').toString(),
      refreshToken: json['refreshToken']?.toString(),
    );
  }
}


