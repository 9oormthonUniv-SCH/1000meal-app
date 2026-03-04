import '../../auth/models/role.dart';

class MeResponse {
  final int? accountId;
  final Role role;
  final String username;
  final String? name;
  final String email;
  final String? phoneNumber;
  final String? studentNumber;
  final int? storeId;
  final String? storeName;

  MeResponse({
    this.accountId,
    required this.role,
    required this.username,
    this.name,
    required this.email,
    this.phoneNumber,
    this.studentNumber,
    this.storeId,
    this.storeName,
  });

  /// 표시용 이름 (API name 우선, 없으면 username)
  String get displayName => (name != null && name!.isNotEmpty) ? name! : username;

  factory MeResponse.fromJson(Map<String, dynamic> json) {
    int? toInt(dynamic v) => v is int ? v : int.tryParse((v ?? '').toString());

    final studentNumber = json['studentNumber']?.toString() ??
        json['studentId']?.toString() ??
        json['userId']?.toString();

    return MeResponse(
      accountId: toInt(json['accountId']),
      role: RoleApi.fromApi((json['role'] ?? 'STUDENT').toString()),
      username: (json['username'] ?? json['userId'] ?? '').toString(),
      name: json['name']?.toString(),
      email: (json['email'] ?? '').toString(),
      phoneNumber: json['phoneNumber']?.toString(),
      studentNumber: studentNumber?.isNotEmpty == true ? studentNumber : null,
      storeId: toInt(json['storeId']),
      storeName: json['storeName']?.toString(),
    );
  }
}


