import 'package:dio/dio.dart';
import 'auth_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  final Dio _dio = Dio();

  factory ApiService() {
    return _instance;
  }
  ApiService._internal() {
    // Configure Dio instance
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    _dio.options.headers['Accept'] = 'application/json';

    // Add interceptor for token refresh
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          // Check if error is due to token expiration (status code 406)
          if (error.response?.statusCode == 406) {
            // Try to refresh token
            final authService = AuthService();
            final refreshSuccess = await authService.refreshToken();

            if (refreshSuccess) {
              // If token refresh is successful, retry the original request
              // Get the new token
              final newToken = await authService.getToken();

              // Update the Authorization header with the new token
              error.requestOptions.headers['Authorization'] =
                  'Bearer $newToken';

              // Create a new request with the updated token
              final opts = Options(
                method: error.requestOptions.method,
                headers: error.requestOptions.headers,
              );

              // Retry the request with the new token
              final newRequest = await _dio.request(
                error.requestOptions.path,
                options: opts,
                data: error.requestOptions.data,
                queryParameters: error.requestOptions.queryParameters,
              );

              // Return the response of the retry request
              return handler.resolve(newRequest);
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  Dio get dio => _dio;

  // Base URL for API
  static const String baseUrl = 'https://mobileapis.manpits.xyz/api';

  // Helper method to get headers with authentication
  Future<Map<String, dynamic>> getHeaders() async {
    final token = await AuthService().getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // POST method with authentication
  Future<Response> post(String endpoint, Map<String, dynamic> data) async {
    final headers = await getHeaders();
    final url = '$baseUrl/$endpoint';

    return _dio.post(url, options: Options(headers: headers), data: data);
  }

  // GET method with authentication
  Future<Response> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final headers = await getHeaders();
    final url = '$baseUrl/$endpoint';

    return _dio.get(
      url,
      options: Options(headers: headers),
      queryParameters: queryParameters,
    );
  }

  // PUT method with authentication
  Future<Response> put(String endpoint, Map<String, dynamic> data) async {
    final headers = await getHeaders();
    final url = '$baseUrl/$endpoint';

    return _dio.put(url, options: Options(headers: headers), data: data);
  }

  // DELETE method with authentication
  Future<Response> delete(String endpoint) async {
    final headers = await getHeaders();
    final url = '$baseUrl/$endpoint';

    return _dio.delete(url, options: Options(headers: headers));
  }

  // PATCH method with authentication
  Future<Response> patch(String endpoint, Map<String, dynamic> data) async {
    final headers = await getHeaders();
    final url = '$baseUrl/$endpoint';

    return _dio.patch(url, options: Options(headers: headers), data: data);
  }
}
