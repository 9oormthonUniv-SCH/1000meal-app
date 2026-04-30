import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// secure_storage가 일부 단말/상황(키체인 락 등)에서 무한 대기로 빠지는 사례가 있어,
/// 모든 호출에 5초 타임아웃을 걸어 실패는 빠르게 노출시킨다(무한 로딩 UX 방지).
class TokenStorage {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _ioTimeout = Duration(seconds: 5);

  final FlutterSecureStorage _storage;

  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> setAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token).timeout(_ioTimeout, onTimeout: () {});

  Future<String?> getAccessToken() => _storage
      .read(key: _accessTokenKey)
      .timeout(_ioTimeout, onTimeout: () => null);

  Future<void> setRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token).timeout(_ioTimeout, onTimeout: () {});

  Future<String?> getRefreshToken() => _storage
      .read(key: _refreshTokenKey)
      .timeout(_ioTimeout, onTimeout: () => null);

  Future<void> clear() async {
    try {
      await _storage.delete(key: _accessTokenKey).timeout(_ioTimeout, onTimeout: () {});
    } catch (_) {}
    try {
      await _storage.delete(key: _refreshTokenKey).timeout(_ioTimeout, onTimeout: () {});
    } catch (_) {}
  }
}
