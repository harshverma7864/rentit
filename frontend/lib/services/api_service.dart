import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Change this to your server URL
  static const String baseUrl = 'https://rentit-kappa.vercel.app/api'; // Android emulator
  // static const String baseUrl = 'http://localhost:3000/api'; // iOS simulator / web

  // Base URL for images hosted on shared hosting
  static const String imageBaseUrl = 'https://rentpe.store/uploads/images';

  String? _token;

  Future<String?> get token async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    return _token;
  }

  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Future<Map<String, String>> _headers() async {
    final t = await token;
    return {
      'Content-Type': 'application/json',
      if (t != null) 'Authorization': 'Bearer $t',
    };
  }

  Future<Map<String, String>> _authHeader() async {
    final t = await token;
    return {
      if (t != null) 'Authorization': 'Bearer $t',
    };
  }

  Future<Map<String, dynamic>> get(String endpoint,
      {Map<String, String>? queryParams}) async {
    final uri =
        Uri.parse('$baseUrl$endpoint').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: await _headers());
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(String endpoint,
      {Map<String, dynamic>? body}) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> multipartPost(
    String endpoint, {
    required Map<String, String> fields,
    List<String> filePaths = const [],
    String fileField = 'images',
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl$endpoint'),
    );
    request.headers.addAll(await _authHeader());
    request.fields.addAll(fields);
    for (final path in filePaths) {
      request.files.add(await http.MultipartFile.fromPath(
        fileField,
        path,
        contentType: MediaType('image', 'jpeg'),
      ));
    }
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> multipartPatch(
    String endpoint, {
    required Map<String, String> fields,
    List<String> filePaths = const [],
    String fileField = 'images',
  }) async {
    final request = http.MultipartRequest(
      'PATCH',
      Uri.parse('$baseUrl$endpoint'),
    );
    request.headers.addAll(await _authHeader());
    request.fields.addAll(fields);
    for (final path in filePaths) {
      request.files.add(await http.MultipartFile.fromPath(
        fileField,
        path,
        contentType: MediaType('image', 'jpeg'),
      ));
    }
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> patch(String endpoint,
      {Map<String, dynamic>? body}) async {
    final response = await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _headers(),
    );
    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      throw ApiException(
        data['error'] ?? 'Something went wrong',
        response.statusCode,
      );
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}
