class FindUserIdRequest {
  final String name;
  final String email;

  FindUserIdRequest({required this.name, required this.email});

  Map<String, dynamic> toJson() => {'name': name, 'email': email};
}

class FindUserIdResponse {
  final String userId;

  FindUserIdResponse({required this.userId});

  factory FindUserIdResponse.fromJson(Map<String, dynamic> json) {
    return FindUserIdResponse(userId: (json['userId'] ?? '').toString());
  }
}

class ResetPasswordConfirmRequest {
  final String email;
  final String token;
  final String newPassword;
  final String confirmPassword;

  ResetPasswordConfirmRequest({
    required this.email,
    required this.token,
    required this.newPassword,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'token': token,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      };
}


