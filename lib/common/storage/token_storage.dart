import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _accessTokenKey = 'access_token';

  final FlutterSecureStorage _storage;

  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> setAccessToken(String token) => _storage.write(key: _accessTokenKey, value: token);

  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);

  Future<void> clear() => _storage.delete(key: _accessTokenKey);
}


