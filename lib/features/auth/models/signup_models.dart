import 'role.dart';

class VerifyIdResponse {
  final bool valid;
  final String message;

  VerifyIdResponse({required this.valid, required this.message});

  factory VerifyIdResponse.fromJson(Map<String, dynamic> json) {
    return VerifyIdResponse(
      valid: json['valid'] == true,
      message: (json['message'] ?? '').toString(),
    );
  }
}

class SignUpRequest {
  final Role role;
  final String userId;
  final String name;
  final String email;
  final String password;

  SignUpRequest({
    required this.role,
    required this.userId,
    required this.name,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'role': role.toApi(),
        'userId': userId,
        'name': name,
        'email': email,
        'password': password,
      };
}


