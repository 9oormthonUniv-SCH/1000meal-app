class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Object? details;

  ApiException(this.message, {this.statusCode, this.details});

  /// 백엔드 응답의 `result.code` 값. 예: "AUTH_401", "AUTH_401_REFRESH_EXPIRED"
  String? get errorCode {
    final body = details;
    if (body is Map) {
      final result = body['result'];
      if (result is Map) {
        final code = result['code'];
        if (code is String && code.isNotEmpty) return code;
      }
      final code = body['code'];
      if (code is String && code.isNotEmpty) return code;
    }
    return null;
  }

  /// refresh token이 무효(만료/잘못됨/철회)되어 재로그인이 필요한 상태인지.
  bool get isRefreshExpired {
    final code = errorCode;
    return code == 'AUTH_401_REFRESH_EXPIRED' ||
        code == 'AUTH_401_REFRESH_INVALID' ||
        code == 'AUTH_401_REFRESH_REVOKED';
  }

  @override
  String toString() => 'ApiException(statusCode=$statusCode, code=$errorCode, message=$message)';
}
