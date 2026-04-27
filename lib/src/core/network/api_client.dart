import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../storage/auth_token_storage.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient(this._tokenStorage)
      : _dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.apiBaseUrl,
            connectTimeout: AppConfig.connectTimeout,
            receiveTimeout: AppConfig.receiveTimeout,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          final session = await _tokenStorage.loadSession();
          if (session != null && session.accessToken.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer ${session.accessToken}';
          }
          handler.next(options);
        },
      ),
    );
  }

  final AuthTokenStorage _tokenStorage;
  final Dio _dio;

  Future<Map<String, dynamic>> getMap(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _guard(
      () => _dio.get<dynamic>(path, queryParameters: queryParameters),
    );
    return _asMap(response.data);
  }

  Future<List<dynamic>> getList(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _guard(
      () => _dio.get<dynamic>(path, queryParameters: queryParameters),
    );
    return _asList(response.data);
  }

  Future<Map<String, dynamic>> postMap(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _guard(
      () => _dio.post<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
      ),
    );
    return _asMap(response.data);
  }

  Future<void> postVoid(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    await _guard(
      () => _dio.post<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
      ),
    );
  }

  Future<Map<String, dynamic>> putMap(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _guard(
      () => _dio.put<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
      ),
    );
    return _asMap(response.data);
  }

  Future<void> deleteVoid(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    await _guard(
      () => _dio.delete<dynamic>(path, queryParameters: queryParameters),
    );
  }

  Future<Response<dynamic>> _guard(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      return await request();
    } on DioException catch (error) {
      throw _mapException(error);
    }
  }

  ApiException _mapException(DioException error) {
    final response = error.response;
    final statusCode = response?.statusCode;
    final data = response?.data;

    if (data is Map<String, dynamic>) {
      final message = data['message'] ?? data['error'];
      if (message is String && message.isNotEmpty) {
        return ApiException(message, statusCode: statusCode);
      }
    }

    if (data is Map) {
      final message = data['message'] ?? data['error'];
      if (message is String && message.isNotEmpty) {
        return ApiException(message, statusCode: statusCode);
      }
    }

    if (statusCode == 401) {
      return const ApiException('Sessao invalida ou expirada.', statusCode: 401);
    }

    return ApiException(
      'Falha ao se comunicar com o servidor.',
      statusCode: statusCode,
    );
  }

  Map<String, dynamic> _asMap(Object? data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    throw const ApiException('Resposta invalida do servidor.');
  }

  List<dynamic> _asList(Object? data) {
    if (data is List<dynamic>) {
      return data;
    }
    if (data is List) {
      return List<dynamic>.from(data);
    }
    throw const ApiException('Resposta invalida do servidor.');
  }
}
