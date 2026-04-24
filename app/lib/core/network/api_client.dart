import 'package:dio/dio.dart';
import '../errors/app_exception.dart';
import '../constants/api_config.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: apiBaseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          final data = error.response?.data;
          final message = data is Map
              ? data['error'] ?? 'Ein Fehler ist aufgetreten'
              : 'Ein Fehler ist aufgetreten';
          final statusCode = error.response?.statusCode ?? 500;
          handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              error: AppException.fromStatusCode(statusCode, message),
            ),
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.post(path, data: body);
    return response.data;
  }

  Future<dynamic> get(String path) async {
    final response = await _dio.get(path);
    return response.data;
  }
}
