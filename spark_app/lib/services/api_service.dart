import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/constants.dart';

class ApiService {
  static const _storage = FlutterSecureStorage();
  static String? _token;

  static Future<String?> getToken() async {
    _token ??= await _storage.read(key: 'auth_token');
    return _token;
  }

  static Future<void> setToken(String token) async {
    _token = token;
    await _storage.write(key: 'auth_token', value: token);
  }

  static Future<void> clearToken() async {
    _token = null;
    await _storage.delete(key: 'auth_token');
  }

  static Map<String, String> _headers({bool auth = false, String? token}) {
    final headers = {'Content-Type': 'application/json'};
    final t = token ?? _token;
    if (auth && t != null) {
      headers['Authorization'] = 'Bearer $t';
    }
    return headers;
  }

  // GET request
  static Future<Map<String, dynamic>> get(String endpoint, {bool auth = true, Map<String, String>? queryParams}) async {
    if (auth) await getToken();
    
    var uri = Uri.parse('${AppConstants.apiBaseUrl}$endpoint');
    if (queryParams != null) {
      uri = uri.replace(queryParameters: queryParams);
    }
    
    final response = await http.get(uri, headers: _headers(auth: auth));
    return _handleResponse(response);
  }

  // POST request
  static Future<Map<String, dynamic>> post(String endpoint, {Map<String, dynamic>? body, bool auth = true}) async {
    if (auth) await getToken();
    
    final response = await http.post(
      Uri.parse('${AppConstants.apiBaseUrl}$endpoint'),
      headers: _headers(auth: auth),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  // PUT request
  static Future<Map<String, dynamic>> put(String endpoint, {Map<String, dynamic>? body, bool auth = true}) async {
    if (auth) await getToken();
    
    final response = await http.put(
      Uri.parse('${AppConstants.apiBaseUrl}$endpoint'),
      headers: _headers(auth: auth),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  // DELETE request
  static Future<Map<String, dynamic>> delete(String endpoint, {bool auth = true}) async {
    if (auth) await getToken();
    
    final response = await http.delete(
      Uri.parse('${AppConstants.apiBaseUrl}$endpoint'),
      headers: _headers(auth: auth),
    );
    return _handleResponse(response);
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    final body = jsonDecode(response.body);
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    
    throw ApiException(
      statusCode: response.statusCode,
      message: body['error'] ?? 'An error occurred',
    );
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  
  ApiException({required this.statusCode, required this.message});
  
  @override
  String toString() => message;
}
