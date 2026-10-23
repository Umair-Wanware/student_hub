import 'dart:io';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';

class ApiService {
  ApiService._();

  static final ApiService instance = ApiService._();

  static const String baseUrl = 'https://student-hub-dckn.onrender.com';

  late final Dio _dio;
  late final PersistCookieJar _cookieJar;

  String? _csrfToken;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    final Directory directory = await getApplicationSupportDirectory();

    _cookieJar = PersistCookieJar(
      storage: FileStorage('${directory.path}/student_hub_cookies/'),
    );

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 20),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(CookieManager(_cookieJar));
    _initialized = true;
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) await initialize();
  }

  Map<String, dynamic> _map(dynamic data) {
    if (data is Map<String, dynamic>) return data;

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return <String, dynamic>{};
  }

  String _messageFrom(dynamic data, String fallback) {
    final Map<String, dynamic> body = _map(data);

    for (final key in ['message', 'error']) {
      final value = body[key];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }

    return fallback;
  }

  String _errorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      final message = _messageFrom(
        data,
        error.response == null
            ? 'Could not connect to the server. Check your internet connection.'
            : 'Request failed (${error.response?.statusCode}).',
      );

      return message;
    }

    return error.toString();
  }

  Future<void> _refreshCsrfToken() async {
    await _ensureInitialized();

    final response = await _dio.get('/api/auth/csrf');
    final body = _map(response.data);

    final token = body['csrfToken'];

    if (token is! String || token.isEmpty) {
      throw Exception('The server did not provide a CSRF token.');
    }

    _csrfToken = token;
  }

  Future<Response<dynamic>> _protectedRequest(
    String method,
    String path, {
    dynamic data,
  }) async {
    await _ensureInitialized();

    if (_csrfToken == null) {
      await _refreshCsrfToken();
    }

    try {
      return await _dio.request(
        path,
        data: data,
        options: Options(
          method: method,
          headers: {'x-csrf-token': _csrfToken!},
        ),
      );
    } on DioException catch (error) {
      // Refresh the token once if the server reports a CSRF failure.
      final status = error.response?.statusCode;
      final message = _messageFrom(error.response?.data, '').toLowerCase();

      final isCsrfError = status == 403 &&
          (message.contains('csrf') || message.contains('token'));

      if (!isCsrfError) rethrow;

      await _refreshCsrfToken();

      return _dio.request(
        path,
        data: data,
        options: Options(
          method: method,
          headers: {'x-csrf-token': _csrfToken!},
        ),
      );
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    await _ensureInitialized();

    try {
      await _refreshCsrfToken();

      final response = await _protectedRequest(
        'POST',
        '/api/auth/login',
        data: {
          'email': email.trim(),
          'password': password,
        },
      );

      // Login may regenerate the session, so fetch its new CSRF token.
      await _refreshCsrfToken();

      return _map(response.data);
    } catch (error) {
      throw Exception(_errorMessage(error));
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    await _ensureInitialized();

    try {
      await _refreshCsrfToken();

      final response = await _protectedRequest(
        'POST',
        '/api/auth/register',
        data: {
          'name': name.trim(),
          'email': email.trim(),
          'password': password,
          'confirmPassword': confirmPassword,
        },
      );

      return _map(response.data);
    } catch (error) {
      throw Exception(_errorMessage(error));
    }
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    await _ensureInitialized();

    try {
      final response = await _dio.get('/api/auth/me');
      final body = _map(response.data);

      if (body['user'] is Map) {
        return _map(body['user']);
      }

      if (body['id'] != null || body['email'] != null) {
        return body;
      }

      return null;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401 ||
          error.response?.statusCode == 403) {
        return null;
      }

      throw Exception(_errorMessage(error));
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
  }) async {
    try {
      final response = await _protectedRequest(
        'PATCH',
        '/api/auth/profile',
        data: {
          'name': name.trim(),
          'email': email.trim(),
        },
      );

      return _map(response.data);
    } catch (error) {
      throw Exception(_errorMessage(error));
    }
  }

  Future<void> logout() async {
    await _ensureInitialized();

    try {
      await _protectedRequest('POST', '/api/auth/logout');
    } catch (_) {
      // Clear local cookies even if the server cannot be reached.
    } finally {
      await _cookieJar.deleteAll();
      _csrfToken = null;
    }
  }

  Future<void> clearLocalSession() async {
    await _ensureInitialized();
    await _cookieJar.deleteAll();
    _csrfToken = null;
  }
}
