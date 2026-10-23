import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';

class ApiService {
  ApiService._();

  static final ApiService instance = ApiService._();

  static const String baseUrl =
      'https://student-hub-dckn.onrender.com';

  late Dio _dio;
  late PersistCookieJar _cookieJar;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    final directory = await getApplicationSupportDirectory();

    _cookieJar = PersistCookieJar(
      storage: FileStorage(
        '${directory.path}/student_hub_cookies/',
      ),
    );

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
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

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  String _errorMessage(Object error) {
    if (error is DioException) {
      final responseData = error.response?.data;

      if (responseData is Map) {
        final message =
            responseData['message'] ?? responseData['error'];
        if (message != null) return message.toString();
      }

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return 'Request timed out. Please try again.';
      }

      if (error.type == DioExceptionType.connectionError) {
        return 'Cannot connect to the server. Check your internet connection.';
      }

      if (error.response?.statusCode == 401) {
        return 'Your session has expired. Please log in again.';
      }

      return error.message ?? 'A network error occurred.';
    }

    return error.toString().replaceFirst('Exception: ', '');
  }

  // CSRF

  Future<String> getCsrfToken() async {
    await _ensureInitialized();

    try {
      final response =
          await _dio.get<dynamic>('/api/auth/csrf');
      final data = _map(response.data);

      final token = data['csrfToken'] ??
          data['csrfTokenValue'] ??
          data['token'];

      if (token == null || token.toString().isEmpty) {
        throw Exception('The server did not return a CSRF token.');
      }

      return token.toString();
    } catch (error) {
      throw Exception(_errorMessage(error));
    }
  }

  // Shared request handler. All write requests fetch a CSRF token.

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    await _ensureInitialized();

    final requestMethod = method.toUpperCase();

    try {
      final requestHeaders = <String, dynamic>{...?headers};

      const writeMethods = {'POST', 'PUT', 'PATCH', 'DELETE'};

      if (writeMethods.contains(requestMethod)) {
        requestHeaders['X-CSRF-Token'] = await getCsrfToken();
      }

      final response = await _dio.request<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          method: requestMethod,
          headers: requestHeaders,
        ),
      );

      return _map(response.data);
    } catch (error) {
      throw Exception(_errorMessage(error));
    }
  }

  List<Map<String, dynamic>> _extractList(
    Map<String, dynamic> response,
  ) {
    dynamic items = response['data'] ??
        response['items'] ??
        response['tasks'] ??
        response['notes'] ??
        response['sessions'] ??
        response['attendance'];

    if (items is Map) {
      items = items['items'] ??
          items['tasks'] ??
          items['notes'] ??
          items['sessions'] ??
          items['attendance'];
    }

    if (items is List) {
      return items
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    return [];
  }

  // Authentication

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    await _ensureInitialized();

    try {
      final token = await getCsrfToken();

      final response = await _dio.post<dynamic>(
        '/api/auth/login',
        data: {
          'email': email.trim(),
          'password': password,
        },
        options: Options(
          headers: {'X-CSRF-Token': token},
        ),
      );

      return _map(response.data);
    } catch (error) {
      throw Exception(_errorMessage(error));
    }
  }

  Future<Map<String, dynamic>> register({
    String? username,
    String? name,
    required String email,
    required String password,
    String? confirmPassword,
  }) async {
    final resolvedName = (name ?? username ?? '').trim();
    final confirmation = confirmPassword ?? password;

    if (resolvedName.isEmpty) {
      throw Exception('Please enter your name.');
    }

    if (password != confirmation) {
      throw Exception('Passwords do not match.');
    }

    return _request(
      'POST',
      '/api/auth/register',
      data: {
        'name': resolvedName,
        'email': email.trim(),
        'password': password,
        'confirmPassword': confirmation,
      },
    );
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    return _request('GET', '/api/auth/me');
  }

  Future<void> logout() async {
    await _ensureInitialized();

    try {
      await _request('POST', '/api/auth/logout');
    } finally {
      await _cookieJar.deleteAll();
    }
  }

  // Profile

  Future<Map<String, dynamic>> updateProfile({
    String? username,
    String? name,
    String? email,
  }) async {
    final data = <String, dynamic>{};
    final resolvedName = name ?? username;

    if (resolvedName != null) {
      data['name'] = resolvedName.trim();
    }

    if (email != null) {
      data['email'] = email.trim();
    }

    if (data.isEmpty) {
      throw Exception('No profile changes were provided.');
    }

    return _request(
      'PATCH',
      '/api/auth/profile',
      data: data,
    );
  }

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    String? confirmPassword,
  }) async {
    final confirmation = confirmPassword ?? newPassword;

    if (newPassword != confirmation) {
      throw Exception('Passwords do not match.');
    }

    return _request(
      'PATCH',
      '/api/auth/password',
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmation,
      },
    );
  }

  // Tasks

  Future<List<Map<String, dynamic>>> getTasks({
    String? search,
    bool? completed,
  }) async {
    final query = <String, dynamic>{'limit': 100};

    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }

    if (completed != null) query['completed'] = completed;

    final response = await _request(
      'GET',
      '/api/tasks/',
      queryParameters: query,
    );

    return _extractList(response);
  }

  Future<Map<String, dynamic>> createTask({
    String? title,
    String? subject,
    String? description,
    String? dueDate,
    String? priority,
    bool? completed,
  }) async {
    final cleanTitle = (title ?? '').trim();
    final cleanSubject = (subject ?? '').trim();
    final cleanPriority = priority ?? 'Medium';

    if (cleanTitle.isEmpty) {
      throw Exception('Please enter a task title.');
    }

    if (cleanSubject.isEmpty) {
      throw Exception('Please enter a subject.');
    }

    if (dueDate == null || dueDate.trim().isEmpty) {
      throw Exception('Please select a due date.');
    }

    // Normalize dates to YYYY-MM-DD for the backend.
    final cleanDate = dueDate.trim();
    final dateMatch =
        RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(cleanDate);

    if (dateMatch == null) {
      throw Exception('Due date must use YYYY-MM-DD format.');
    }

    final year = int.parse(dateMatch.group(1)!);
    final month = int.parse(dateMatch.group(2)!);
    final day = int.parse(dateMatch.group(3)!);
    final parsedDate = DateTime.tryParse(cleanDate);

    if (parsedDate == null ||
        parsedDate.year != year ||
        parsedDate.month != month ||
        parsedDate.day != day) {
      throw Exception('Please select a valid due date.');
    }

    if (!const {'High', 'Medium', 'Low'}.contains(cleanPriority)) {
      throw Exception('Please select a valid priority.');
    }

    return _request(
      'POST',
      '/api/tasks/',
      data: {
        'title': cleanTitle,
        'subject': cleanSubject,
        'dueDate': cleanDate,
        'priority': cleanPriority,
        'completed': completed ?? false,
      },
    );
  }

  Future<Map<String, dynamic>> updateTask(
    String id, {
    String? title,
    String? subject,
    String? description,
    String? dueDate,
    String? priority,
    bool? completed,
  }) async {
    final data = <String, dynamic>{};

    if (title != null) data['title'] = title.trim();
    if (subject != null) data['subject'] = subject.trim();
    if (dueDate != null) data['dueDate'] = dueDate;
    if (priority != null) data['priority'] = priority;
    if (completed != null) data['completed'] = completed;

    return _request(
      'PATCH',
      '/api/tasks/$id',
      data: data,
    );
  }

  Future<void> deleteTask(String id) async {
    await _request('DELETE', '/api/tasks/$id');
  }

  // Attendance

  Future<List<Map<String, dynamic>>> getAttendance({
    String? search,
  }) async {
    final query = <String, dynamic>{'limit': 100};

    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }

    final response = await _request(
      'GET',
      '/api/attendance/',
      queryParameters: query,
    );

    return _extractList(response);
  }

  Future<Map<String, dynamic>> createAttendance({
    required String subject,
    required int attended,
    required int total,
  }) async {
    return _request(
      'POST',
      '/api/attendance/',
      data: {
        'subject': subject.trim(),
        'attended': attended,
        'total': total,
      },
    );
  }

  Future<Map<String, dynamic>> updateAttendance(
    String id, {
    required String subject,
    required int attended,
    required int total,
  }) async {
    return _request(
      'PATCH',
      '/api/attendance/$id',
      data: {
        'subject': subject.trim(),
        'attended': attended,
        'total': total,
      },
    );
  }

  Future<void> deleteAttendance(String id) async {
    await _request('DELETE', '/api/attendance/$id');
  }

  // Focus sessions

  Future<List<Map<String, dynamic>>> getFocusSessions({
    String? date,
  }) async {
    final query = <String, dynamic>{'limit': 100};

    if (date != null && date.isNotEmpty) query['date'] = date;

    final response = await _request(
      'GET',
      '/api/focus-sessions',
      queryParameters: query,
    );

    return _extractList(response);
  }

  Future<Map<String, dynamic>> saveFocusSession({
    required int durationMinutes,
    DateTime? completedAt,
  }) async {
    return _request(
      'POST',
      '/api/focus-sessions',
      data: {
        'durationMinutes': durationMinutes,
        if (completedAt != null)
          'completedAt': completedAt.toUtc().toIso8601String(),
      },
    );
  }

  Future<void> deleteFocusSession(String id) async {
    await _request('DELETE', '/api/focus-sessions/$id');
  }

  // Notes

  Future<List<Map<String, dynamic>>> getNotes({
    String? search,
  }) async {
    final query = <String, dynamic>{'limit': 100};

    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }

    final response = await _request(
      'GET',
      '/api/notes/',
      queryParameters: query,
    );

    return _extractList(response);
  }

  Future<Map<String, dynamic>> createNote({
    required String title,
    required String content,
    String? date,
  }) async {
    return _request(
      'POST',
      '/api/notes/',
      data: {
        'title': title.trim(),
        'content': content.trim(),
        if (date != null && date.isNotEmpty) 'date': date,
      },
    );
  }

  Future<Map<String, dynamic>> updateNote(
    String id, {
    required String title,
    required String content,
    String? date,
  }) async {
    return _request(
      'PATCH',
      '/api/notes/$id',
      data: {
        'title': title.trim(),
        'content': content.trim(),
        if (date != null && date.isNotEmpty) 'date': date,
      },
    );
  }

  Future<void> deleteNote(String id) async {
    await _request('DELETE', '/api/notes/$id');
  }
}