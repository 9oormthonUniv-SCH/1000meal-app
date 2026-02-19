import '../../auth/models/role.dart';

class MeResponse {
  final int? accountId;
  final Role role;
  final String username;
  final String email;
  final String? studentNumber;
  final int? storeId;
  final String? storeName;

  MeResponse({
    this.accountId,
    required this.role,
    required this.username,
    required this.email,
    this.studentNumber,
    this.storeId,
    this.storeName,
  });

  factory MeResponse.fromJson(Map<String, dynamic> json) {
    int? toInt(dynamic v) => v is int ? v : int.tryParse((v ?? '').toString());

    final studentNumber = json['studentNumber']?.toString() ??
        json['studentId']?.toString() ??
        json['userId']?.toString();

    return MeResponse(
      accountId: toInt(json['accountId']),
      role: RoleApi.fromApi((json['role'] ?? 'STUDENT').toString()),
      username: (json['username'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      studentNumber: studentNumber?.isNotEmpty == true ? studentNumber : null,
      storeId: toInt(json['storeId']),
      storeName: json['storeName']?.toString(),
    );
  }
}


