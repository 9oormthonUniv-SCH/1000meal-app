class StartEmailChangeRequest {
  final String currentEmail;
  final String password;

  StartEmailChangeRequest({required this.currentEmail, required this.password});

  Map<String, dynamic> toJson() => {
        'currentEmail': currentEmail,
        'password': password,
      };
}

class StartEmailChangeResponse {
  final String changeId;
  final int? expiresInSec;

  StartEmailChangeResponse({required this.changeId, this.expiresInSec});

  factory StartEmailChangeResponse.fromJson(Map<String, dynamic> json) {
    final expires = json['expiresInSec'];
    return StartEmailChangeResponse(
      changeId: (json['changeId'] ?? '').toString(),
      expiresInSec: expires is int ? expires : int.tryParse((expires ?? '').toString()),
    );
  }
}

class SendEmailChangeCodeRequest {
  final String changeId;
  final String newEmail;

  SendEmailChangeCodeRequest({required this.changeId, required this.newEmail});

  Map<String, dynamic> toJson() => {
        'changeId': changeId,
        'newEmail': newEmail,
      };
}

class VerifyEmailChangeRequest {
  final String changeId;
  final String code;

  VerifyEmailChangeRequest({required this.changeId, required this.code});

  Map<String, dynamic> toJson() => {
        'changeId': changeId,
        'code': code,
      };
}

class VerifyEmailChangeResponse {
  final String? updatedEmail;

  VerifyEmailChangeResponse({this.updatedEmail});

  factory VerifyEmailChangeResponse.fromJson(Map<String, dynamic> json) {
    return VerifyEmailChangeResponse(updatedEmail: json['updatedEmail']?.toString());
  }
}


