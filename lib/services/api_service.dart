import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // For mobile: Use PC's IP address
  // For web: Use 'localhost'
  static const String baseUrl = 'http://20.40.11.134:8080/api';
  final Dio _dio = Dio();
  final _storage = const FlutterSecureStorage();

  ApiService() {
    _dio.options.baseUrl = baseUrl;
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          // Only logout on 401 for auth-critical endpoints
          if (error.response?.statusCode == 401) {
            final path = error.requestOptions.path;
            // Don't auto-logout for session detail failures
            if (!path.contains('/sessions/')) {
              await _storage.delete(key: 'auth_token');
              await _storage.delete(key: 'user_id');
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<Map<String, dynamic>> register(
    String username, 
    String email, 
    String password, {
    String? empId,
    String? employmentType,
    String? designation,
    String? projectAssigned,
  }) async {
    final response = await _dio.post(
      '/auth/register',
      data: {
        'username': username,
        'email': email,
        'password': password,
        if (empId != null) 'empId': empId,
        if (employmentType != null) 'employmentType': employmentType,
        if (designation != null) 'designation': designation,
        if (projectAssigned != null) 'projectAssigned': projectAssigned,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> login(String username, String email, String password) async {
    final response = await _dio.post(
      '/auth/login',
      data: {
        'username': username,
        'email': email,
        'password': password,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> syncSession(Map<String, dynamic> sessionData) async {
    try {
      print('🌐 API: POST /sessions/full-sync');
      print('📤 Sending ${sessionData['routePoints']?.length ?? 0} points, ${sessionData['checkpoints']?.length ?? 0} checkpoints');
      
      final response = await _dio.post(
        '/sessions/full-sync',
        data: sessionData,
      );
      
      print('📥 Response status: ${response.statusCode}');
      print('📥 Response data: ${response.data}');
      
      return response.data;
    } catch (e) {
      print('❌ API Error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getSessions() async {
    try {
      print('🌐 API: GET /sessions');
      final response = await _dio.get('/sessions');
      print('📥 Response: ${response.data}');
      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    } catch (e) {
      print('❌ API Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getSessionById(String sessionId) async {
    final response = await _dio.get('/sessions/$sessionId');
    return response.data['data'];
  }

  Future<Map<String, dynamic>> getUser() async {
    try {
      final userId = await _storage.read(key: 'user_id');
      if (userId == null) throw Exception('Not logged in');
      final response = await _dio.get('/user?id=$userId');
      return response.data['data'] ?? {};
    } catch (e) {
      print('❌ API Error: $e');
      rethrow;
    }
  }

  Future<void> updateUser(Map<String, dynamic> data) async {
    try {
      final userId = await _storage.read(key: 'user_id');
      if (userId == null) throw Exception('Not logged in');
      await _dio.put('/user?id=$userId', data: data);
    } catch (e) {
      print('❌ API Error: $e');
      rethrow;
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      final userId = await _storage.read(key: 'user_id');
      if (userId == null) throw Exception('Not logged in');
      await _dio.put('/user/password?id=$userId', data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
    } catch (e) {
      print('❌ API Error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'user_id');
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<void> saveToken(String token, String userId) async {
    await _storage.write(key: 'auth_token', value: token);
    await _storage.write(key: 'user_id', value: userId);
  }

  Future<void> saveRole(String role) async {
    await _storage.write(key: 'user_role', value: role);
  }

  Future<String?> getRole() async {
    return await _storage.read(key: 'user_role');
  }

  Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final response = await _dio.get('/admin/stats');
      return response.data['data'] ?? {};
    } catch (e) {
      print('❌ API Error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAdminUsers() async {
    try {
      final response = await _dio.get('/admin/users');
      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    } catch (e) {
      print('❌ API Error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllSessions() async {
    try {
      print('🌐 API: GET /admin/sessions/all');
      final response = await _dio.get('/admin/sessions/all');
      print('📥 Response: ${response.data}');
      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    } catch (e) {
      print('❌ API Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> bulkImportUsers(List<Map<String, dynamic>> users) async {
    try {
      print('🌐 API: POST /auth/bulk-import');
      print('📤 Importing ${users.length} users');
      
      final response = await _dio.post(
        '/auth/bulk-import',
        data: {'users': users},
      );
      
      print('📥 Response: ${response.data}');
      return response.data['data'] ?? {};
    } catch (e) {
      print('❌ API Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAllUsers() async {
    try {
      print('🌐 API: GET /auth/users');
      final response = await _dio.get('/auth/users');
      return response.data;
    } catch (e) {
      print('❌ API Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteUser(String username) async {
    try {
      print('🌐 API: DELETE /auth/users/$username');
      final response = await _dio.delete('/auth/users/$username');
      return response.data;
    } catch (e) {
      print('❌ API Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteMultipleUsers(List<String> usernames) async {
    try {
      print('🌐 API: POST /auth/users/delete-multiple');
      print('📤 Deleting ${usernames.length} users');
      final response = await _dio.post(
        '/auth/users/delete-multiple',
        data: {'usernames': usernames},
      );
      return response.data;
    } catch (e) {
      print('❌ API Error: $e');
      rethrow;
    }
  }

  Future<List<int>> downloadExportAllUsers() async {
    try {
      print('🌐 API: GET /admin/export/all');
      final response = await _dio.get(
        '/admin/export/all',
        options: Options(responseType: ResponseType.bytes),
      );
      
      return List<int>.from(response.data);
    } catch (e) {
      print('❌ API Error: $e');
      rethrow;
    }
  }

  Future<List<int>> downloadExportUser(String userId) async {
    try {
      print('🌐 API: GET /admin/export/user/$userId');
      final response = await _dio.get(
        '/admin/export/user/$userId',
        options: Options(responseType: ResponseType.bytes),
      );
      
      return List<int>.from(response.data);
    } catch (e) {
      print('❌ API Error: $e');
      rethrow;
    }
  }
}
