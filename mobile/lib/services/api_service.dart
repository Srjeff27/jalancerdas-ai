import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  late Dio _dio;
  String _baseUrl = 'http://localhost:8000/api';
  String? _authToken;

  Dio get dio => _dio;
  String get baseUrl => _baseUrl;

  ApiService({String? baseUrl}) {
    if (baseUrl != null) {
      _baseUrl = baseUrl;
    }
    _initDio();
  }

  void _initDio() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptors
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Add auth token if available
        if (_authToken != null) {
          options.headers['Authorization'] = 'Bearer $_authToken';
        }
        debugPrint('ApiService: ${options.method} ${options.path}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint('ApiService: ${response.statusCode} ${response.requestOptions.path}');
        handler.next(response);
      },
      onError: (error, handler) {
        debugPrint('ApiService: ERROR ${error.response?.statusCode} ${error.requestOptions.path}');
        handler.next(error);
      },
    ));
  }

  /// Update base URL
  void setBaseUrl(String url) {
    _baseUrl = url;
    _dio.options.baseUrl = url;
  }

  /// Set authentication token
  void setAuthToken(String? token) {
    _authToken = token;
  }

  /// GET request
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return _dio.get(path, queryParameters: queryParameters);
  }

  /// POST request
  Future<Response> post(String path, {dynamic data}) async {
    return _dio.post(path, data: data);
  }

  /// PUT request
  Future<Response> put(String path, {dynamic data}) async {
    return _dio.put(path, data: data);
  }

  /// DELETE request
  Future<Response> delete(String path) async {
    return _dio.delete(path);
  }

  /// Upload file
  Future<Response> upload(String path, FormData formData) async {
    return _dio.post(
      path,
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
      ),
    );
  }

  /// Check API health
  Future<bool> healthCheck() async {
    try {
      final response = await get('/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
