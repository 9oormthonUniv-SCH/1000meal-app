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

/// POST /auth/refresh 응답 data
class RefreshResponse {
  final String accessToken;
  final int? expiresInSeconds;

  RefreshResponse({required this.accessToken, this.expiresInSeconds});

  factory RefreshResponse.fromJson(Map<String, dynamic> json) {
    return RefreshResponse(
      accessToken: (json['accessToken'] ?? '').toString(),
      expiresInSeconds: json['expiresInSeconds'] is int
          ? json['expiresInSeconds'] as int
          : int.tryParse((json['expiresInSeconds'] ?? '').toString()),
    );
  }
}


