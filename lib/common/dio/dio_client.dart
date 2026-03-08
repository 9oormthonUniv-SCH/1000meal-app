import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'api_error_mapper.dart';
import 'api_exception.dart';

class DioClient {
  final Dio _dio;
  final List<Future<String?> Function()?> _on401RefreshRef;

  DioClient._(this._dio, this._on401RefreshRef);

  /// 401 발생 시 Refresh Token으로 재발급 후 재시도할 콜백 등록. main에서 AuthRepository 생성 후 호출.
  void setOn401Refresh(Future<String?> Function() callback) {
    _on401RefreshRef[0] = callback;
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

    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: false,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
      ),
    );

    dio.interceptors.add(_Auth401Interceptor(dio, on401Ref));

    return DioClient._(dio, on401Ref);
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

class _Auth401Interceptor extends QueuedInterceptor {
  _Auth401Interceptor(this._dio, this._on401Ref);

  final Dio _dio;
  final List<Future<String?> Function()?> _on401Ref;

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
    if (opts.path.contains('/auth/refresh')) {
      handler.next(err);
      return;
    }
    final refreshCb = _on401Ref.isNotEmpty ? _on401Ref[0] : null;
    if (refreshCb == null) {
      handler.next(err);
      return;
    }
    try {
      final newToken = await refreshCb();
      if (newToken == null || newToken.isEmpty) {
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
      handler.next(err);
    }
  }
}


