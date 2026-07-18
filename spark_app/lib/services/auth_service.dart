import 'api_service.dart';
import '../models/user.dart';

class AuthService {
  // Email/password registration
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String role = 'driver',
  }) async {
    final response = await ApiService.post('/auth/register', body: {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
    }, auth: false);
    
    await ApiService.setToken(response['token']);
    return response;
  }

  // Email/password login
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await ApiService.post('/auth/login', body: {
      'email': email,
      'password': password,
    }, auth: false);
    
    await ApiService.setToken(response['token']);
    return response;
  }

  // Google login
  static Future<Map<String, dynamic>> googleLogin({
    required String googleId,
    required String email,
    required String name,
    String? avatarUrl,
  }) async {
    final response = await ApiService.post('/auth/google', body: {
      'google_id': googleId,
      'email': email,
      'name': name,
      'avatar_url': avatarUrl,
    }, auth: false);
    
    await ApiService.setToken(response['token']);
    return response;
  }

  // Get current profile
  static Future<User> getProfile() async {
    final response = await ApiService.get('/auth/profile');
    return User.fromJson(response['user']);
  }

  // Update profile
  static Future<User> updateProfile({String? name, String? avatarUrl, String? fcmToken}) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (avatarUrl != null) body['avatar_url'] = avatarUrl;
    if (fcmToken != null) body['fcm_token'] = fcmToken;
    
    final response = await ApiService.put('/auth/profile', body: body);
    return User.fromJson(response['user']);
  }

  // Logout
  static Future<void> logout() async {
    await ApiService.clearToken();
  }
}
