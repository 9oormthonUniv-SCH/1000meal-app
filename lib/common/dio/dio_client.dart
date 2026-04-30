import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import 'api_error_mapper.dart';
import 'api_exception.dart';

class DioClient {
  final Dio _dio;
  final List<Future<String?> Function()?> _on401RefreshRef;
  final List<Future<void> Function(ApiException err)?> _onSessionExpiredRef;

  DioClient._(this._dio, this._on401RefreshRef, this._onSessionExpiredRef);

  /// 401 발생 시 Refresh Token으로 재발급 후 재시도할 콜백 등록. main에서 AuthRepository 생성 후 호출.
  void setOn401Refresh(Future<String?> Function() callback) {
    _on401RefreshRef[0] = callback;
  }

  /// refresh도 실패해 세션이 끝났음을 외부(전역 상태)에 알리는 콜백 등록.
  /// 토큰 정리, AuthProvider.notifySessionExpired() 호출 등을 여기에 위임.
  void setOnSessionExpired(Future<void> Function(ApiException err) callback) {
    _onSessionExpiredRef[0] = callback;
  }

  factory DioClient.create() {
    final options = BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      headers: const {'Content-Type': 'application/json'},
      connectTimeout: const Duration(milliseconds: 20000),
      sendTimeout: const Duration(milliseconds: 20000),
      receiveTimeout: const Duration(milliseconds: 20000),
      responseType: ResponseType.json,
    );

    final dio = Dio(options);
    final on401Ref = <Future<String?> Function()?>[null];
    final onSessionExpiredRef = <Future<void> Function(ApiException err)?>[null];

    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: false,
        requestBody: true,
        responseHeader: false,
        responseBody: false, // 전문 출력은 _FullResponseLogInterceptor에서 처리
        error: true,
      ),
    );
    dio.interceptors.add(_FullResponseLogInterceptor());
    dio.interceptors.add(_Auth401Interceptor(dio, on401Ref, onSessionExpiredRef));

    return DioClient._(dio, on401Ref, onSessionExpiredRef);
  }

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final res = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );
      return res.data as T;
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final msg = _exceptionMessage(e, code);
      throw ApiException(msg, statusCode: code, details: e.response?.data);
    }
  }

  Future<T> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final res = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );
      return res.data as T;
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final msg = _exceptionMessage(e, code);
      throw ApiException(msg, statusCode: code, details: e.response?.data);
    }
  }

  /// 서버 응답 body의 message가 있으면 사용, 없으면 상태코드별 기본 문구 사용.
  static String _exceptionMessage(DioException e, int? statusCode) {
    final serverMsg = mapErrorToMessage(e, responseData: e.response?.data);
    if (serverMsg != '요청 처리 중 오류가 발생했습니다.') return serverMsg;
    return _userFriendlyMessage(e, statusCode, e.message);
  }

  static String _userFriendlyMessage(DioException e, int? statusCode, String? dioMessage) {
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
        return '인터넷 연결을 확인해주세요.';
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return '연결 시간이 초과되었습니다. 인터넷 연결을 확인해주세요.';
      default:
        break;
    }
    if (statusCode == 404) {
      return '요청한 정보를 찾을 수 없습니다.';
    }
    if (statusCode != null && statusCode >= 500) {
      return '서버 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.';
    }
    return dioMessage ?? '네트워크 오류가 발생했습니다.';
  }

  Future<T> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final res = await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );
      return res.data as T;
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final msg = _exceptionMessage(e, code);
      throw ApiException(msg, statusCode: code, details: e.response?.data);
    }
  }

  Future<T> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final res = await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );
      return res.data as T;
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final msg = _exceptionMessage(e, code);
      throw ApiException(msg, statusCode: code, details: e.response?.data);
    }
  }

  Future<T> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final res = await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );
      return res.data as T;
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final msg = _exceptionMessage(e, code);
      throw ApiException(msg, statusCode: code, details: e.response?.data);
    }
  }
}

/// 디버그 빌드에서 응답 전문을 콘솔에 출력.
class _FullResponseLogInterceptor extends Interceptor {
  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    if (kDebugMode) {
      final path = response.requestOptions.uri.toString();
      final status = response.statusCode;
      final data = response.data;
      String body;
      if (data is Map || data is List) {
        try {
          body = const JsonEncoder.withIndent('  ').convert(data);
        } catch (_) {
          body = data.toString();
        }
      } else {
        body = data?.toString() ?? '';
      }
      debugPrint('━━━ Dio Response [${response.requestOptions.method} $path] $status ━━━');
      debugPrint(body);
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode && err.response != null) {
      final path = err.requestOptions.uri.toString();
      final status = err.response?.statusCode;
      final data = err.response?.data;
      String body;
      if (data is Map || data is List) {
        try {
          body = const JsonEncoder.withIndent('  ').convert(data);
        } catch (_) {
          body = data.toString();
        }
      } else {
        body = data?.toString() ?? err.response.toString();
      }
      debugPrint('━━━ Dio Error Response [${err.requestOptions.method} $path] $status ━━━');
      debugPrint(body);
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
    handler.next(err);
  }
}

class _Auth401Interceptor extends QueuedInterceptor {
  _Auth401Interceptor(this._dio, this._on401Ref, this._onSessionExpiredRef);

  final Dio _dio;
  final List<Future<String?> Function()?> _on401Ref;
  final List<Future<void> Function(ApiException err)?> _onSessionExpiredRef;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _handle401(err, handler);
  }

  Future<void> _handle401(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }
    final opts = err.requestOptions;
    if (opts.extra['_retried401'] == true) {
      handler.next(err);
      return;
    }
    // refresh API 자체가 401 — refresh token이 만료/무효/철회된 상태.
    // 토큰 정리 + 전역 세션 만료 신호 → 로그인 화면으로 이동시켜야 함.
    if (opts.path.contains('/auth/refresh')) {
      await _notifySessionExpired(err);
      handler.next(err);
      return;
    }
    // Authorization 헤더가 없는 요청(로그인/회원가입/비번찾기 등 비인증 API)이 401인 경우는
    // 비즈니스 에러로 그대로 던진다. refresh 시도하면 잘못된 세션 만료 흐름을 유발.
    if (!_hasBearerAuthHeader(opts.headers)) {
      handler.next(err);
      return;
    }
    final refreshCb = _on401Ref.isNotEmpty ? _on401Ref[0] : null;
    if (refreshCb == null) {
      handler.next(err);
      return;
    }
    try {
      final newToken = await refreshCb().timeout(
        const Duration(seconds: 15),
        onTimeout: () => null,
      );
      if (newToken == null || newToken.isEmpty) {
        // refresh 실패: 토큰 정리 + 세션 만료 신호.
        await _notifySessionExpired(err);
        handler.next(err);
        return;
      }
      final newHeaders = Map<String, dynamic>.from(opts.headers)
        ..['Authorization'] = 'Bearer $newToken';
      final newOpts = opts.copyWith(
        headers: newHeaders,
        extra: {...opts.extra, '_retried401': true},
      );
      try {
        final response = await _dio.fetch(newOpts);
        handler.resolve(response);
      } catch (_) {
        handler.next(err);
      }
    } catch (_) {
      await _notifySessionExpired(err);
      handler.next(err);
    }
  }

  Future<void> _notifySessionExpired(DioException err) async {
    final cb = _onSessionExpiredRef.isNotEmpty ? _onSessionExpiredRef[0] : null;
    if (cb == null) return;
    final apiErr = ApiException(
      _messageFromResponse(err.response?.data) ?? '세션이 만료되었습니다.',
      statusCode: err.response?.statusCode,
      details: err.response?.data,
    );
    try {
      await cb(apiErr).timeout(const Duration(seconds: 3));
    } catch (_) {
      // 절대 무한 대기로 빠지지 않도록 무시
    }
  }

  String? _messageFromResponse(Object? data) {
    if (data is Map) {
      final result = data['result'];
      if (result is Map && result['message'] is String) {
        return result['message'] as String;
      }
    }
    return null;
  }

  bool _hasBearerAuthHeader(Map<String, dynamic> headers) {
    final v = headers['Authorization'] ?? headers['authorization'];
    if (v is! String) return false;
    return v.startsWith('Bearer ') && v.length > 'Bearer '.length;
  }
}


