import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final String baseUrl = 'https://mobileapis.manpits.xyz/api';
  late final Dio _dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';

  AuthService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        headers: {'Accept': 'application/json'},
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    _dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true),
    );
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        // Extract token from response
        final token = response.data['data']['token'];

        // Save token to secure storage
        await _secureStorage.write(key: _tokenKey, value: token);

        return true;
      } else {
        return false;
      }
    } on DioException {
      return false;
    }
  }

  Future<bool> logout() async {
    try {
      // Get the token before deleting it
      final token = await getToken();

      if (token != null && token.isNotEmpty) {
        // Add Authorization header with Bearer token
        await _dio.get(
          '/logout',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      }

      // Delete the token from secure storage
      await _secureStorage.delete(key: _tokenKey);
      return true;
    } on DioException {
      // Still delete the token locally even if the API call fails
      await _secureStorage.delete(key: _tokenKey);
      return false;
    }
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
