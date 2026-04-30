import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl = 'http://20.40.5.66:8080/api';
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
          if (error.response?.statusCode == 401) {
            await _storage.delete(key: 'auth_token');
            await _storage.delete(key: 'user_id');
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<Map<String, dynamic>> register(String username, String email, String password) async {
    final response = await _dio.post(
      '/auth/register',
      data: {
        'username': username,
        'email': email,
        'password': password,
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
}
