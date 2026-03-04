import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'api_exception.dart';

class DioClient {
  final Dio _dio;

  DioClient._(this._dio);

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

    return DioClient._(dio);
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
      final msg = _userFriendlyMessage(e, code, e.message);
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
      final msg = _userFriendlyMessage(e, code, e.message);
      throw ApiException(msg, statusCode: code, details: e.response?.data);
    }
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
      final msg = _userFriendlyMessage(e, code, e.message);
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
      final msg = _userFriendlyMessage(e, code, e.message);
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
      final msg = _userFriendlyMessage(e, code, e.message);
      throw ApiException(msg, statusCode: code, details: e.response?.data);
    }
  }
}


