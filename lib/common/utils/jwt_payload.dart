import 'dart:convert';

class JwtPayload {
  final String? sub;
  final String? role;
  final int? storeId;
  final int? exp;

  const JwtPayload({
    required this.sub,
    required this.role,
    required this.storeId,
    required this.exp,
  });

  factory JwtPayload.fromJson(Map<String, dynamic> json) {
    int? asInt(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '');

    return JwtPayload(
      sub: json['sub']?.toString(),
      role: json['role']?.toString(),
      storeId: asInt(json['storeId']),
      exp: asInt(json['exp']),
    );
  }
}

/// Decodes JWT payload without verifying signature.
///
/// Returns null when token is malformed or payload isn't JSON.
JwtPayload? decodeJwtPayload(String token) {
  final parts = token.split('.');
  if (parts.length < 2) return null;

  final payload = parts[1];
  try {
    final normalized = base64Url.normalize(payload);
    final bytes = base64Url.decode(normalized);
    final map = json.decode(utf8.decode(bytes));
    if (map is Map<String, dynamic>) return JwtPayload.fromJson(map);
    return null;
  } catch (_) {
    return null;
  }
}

int? getStoreIdFromToken(String? token) => token == null ? null : decodeJwtPayload(token)?.storeId;

