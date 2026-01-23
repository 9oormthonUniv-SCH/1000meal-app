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
      throw ApiException(
        e.message ?? '네트워크 오류가 발생했습니다.',
        statusCode: e.response?.statusCode,
        details: e.response?.data,
      );
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
      throw ApiException(
        e.message ?? '네트워크 오류가 발생했습니다.',
        statusCode: e.response?.statusCode,
        details: e.response?.data,
      );
    }
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
      throw ApiException(
        e.message ?? '네트워크 오류가 발생했습니다.',
        statusCode: e.response?.statusCode,
        details: e.response?.data,
      );
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
      throw ApiException(
        e.message ?? '네트워크 오류가 발생했습니다.',
        statusCode: e.response?.statusCode,
        details: e.response?.data,
      );
    }
  }
}


