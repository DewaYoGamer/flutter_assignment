import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final String baseUrl = 'https://mobileapis.manpits.xyz/api';
  late final Dio _dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';
  static const String _emailKey = 'auth_email';
  static const String _passwordKey = 'auth_password';
  static const String _rememberMeKey = 'remember_me';

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
  Future<bool> login(
    String email,
    String password, {
    bool rememberMe = false,
    bool isTokenRefresh = false,
  }) async {
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

        // For normal logins (not token refresh), handle Remember Me
        if (!isTokenRefresh) {
          if (rememberMe) {
            await saveCredentials(email, password);
          } else {
            await clearCredentials();
          }
        }
        // For token refresh, we preserve existing Remember Me status

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

  // Register a new user
  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      final response = await _dio.post(
        '/register',
        data: {'name': name, 'email': email, 'password': password},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data['success'] == true) {
          // Registration successful
          return {
            'success': true,
            'message': response.data['message'] ?? 'Registration successful',
          };
        } else {
          // API returned success: false
          return {
            'success': false,
            'message': response.data['message'] ?? 'Registration failed',
          };
        }
      } else {
        // Non-200/201 status code
        return {
          'success': false,
          'message':
              'Registration failed with status code: ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      // Check for validation errors in response
      if (e.response != null && e.response?.data != null) {
        // Handle validation errors
        if (e.response?.data['errors'] != null) {
          final errors = e.response?.data['errors'] as Map;
          final errorMessages = errors.values
              .map((err) => (err as List).join(', '))
              .join('; ');
          return {'success': false, 'message': errorMessages};
        } else if (e.response?.data['message'] != null) {
          return {'success': false, 'message': e.response?.data['message']};
        }
      }

      // General error
      return {'success': false, 'message': 'Connection error: ${e.message}'};
    } catch (e) {
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  // Remember Me feature methods
  Future<void> saveCredentials(String email, String password) async {
    await _secureStorage.write(key: _emailKey, value: email);
    await _secureStorage.write(key: _passwordKey, value: password);
    await _secureStorage.write(key: _rememberMeKey, value: 'true');
  }

  Future<void> clearCredentials() async {
    await _secureStorage.delete(key: _emailKey);
    await _secureStorage.delete(key: _passwordKey);
    await _secureStorage.write(key: _rememberMeKey, value: 'false');
  }

  Future<bool> isRememberMeEnabled() async {
    final value = await _secureStorage.read(key: _rememberMeKey);
    return value == 'true';
  }

  Future<Map<String, String?>> getSavedCredentials() async {
    final email = await _secureStorage.read(key: _emailKey);
    final password = await _secureStorage.read(key: _passwordKey);
    return {'email': email, 'password': password};
  }

  // Debug method to check stored credentials
  Future<void> debugStoredData() async {
    final rememberMe = await _secureStorage.read(key: _rememberMeKey);
    final email = await _secureStorage.read(key: _emailKey);
    final password = await _secureStorage.read(key: _passwordKey);
    final token = await _secureStorage.read(key: _tokenKey);

    print('debug Remember Me: $rememberMe');
    print('debug Email: ${email != null ? '✓ (stored)' : '✗ (not stored)'}');
    print('debug Password: ${password != null ? '✓ (stored)' : '✗ (not stored)'}');
    print('debug Token: ${token != null ? '✓ (stored)' : '✗ (not stored)'}');
  } // Auto refresh token method

    // Check if remember me is enabled
  Future<bool> refreshToken() async {
    final isRemembered = await isRememberMeEnabled();
    if (!isRemembered) return false;

    // Get stored credentials
    final credentials = await getSavedCredentials();
    final email = credentials['email'];
    final password = credentials['password'];

    // Validate credentials
    if (email == null ||
        password == null ||
        email.isEmpty ||
        password.isEmpty) {
      return false;
    }

    // Try to login again with stored credentials
    // Use isTokenRefresh to tell login not to modify remember me settings
    return await login(email, password, rememberMe: true, isTokenRefresh: true);
  }
}
