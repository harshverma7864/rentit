import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final SocketService _socket = SocketService();

  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  String? get error => _error;

  Future<void> init() async {
    final token = await _api.token;
    if (token != null) {
      await fetchProfile();
    }
  }

  Future<bool> register(String name, String email, String password, String phone) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.post('/auth/register', body: {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
      });
      await _api.setToken(data['token']);
      _user = UserModel.fromJson(data['user']);
      _connectSocket();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.post('/auth/login', body: {
        'email': email,
        'password': password,
      });
      await _api.setToken(data['token']);
      _user = UserModel.fromJson(data['user']);
      _connectSocket();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchProfile() async {
    try {
      final data = await _api.get('/auth/profile');
      _user = UserModel.fromJson(data['user']);
      _connectSocket();
      notifyListeners();
    } catch (e) {
      await logout();
    }
  }

  Future<void> updateLocation(double lat, double lng, String address, String city) async {
    try {
      final data = await _api.patch('/auth/location', body: {
        'latitude': lat,
        'longitude': lng,
        'address': address,
        'city': city,
      });
      _user = UserModel.fromJson(data['user']);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> updateProfile({String? name, String? phone, String? avatarPath}) async {
    try {
      if (avatarPath != null) {
        // Use multipart upload when avatar file is provided
        final fields = <String, String>{};
        if (name != null) fields['name'] = name;
        if (phone != null) fields['phone'] = phone;

        final data = await _api.multipartPatch('/auth/profile',
          fields: fields,
          filePaths: [avatarPath],
          fileField: 'avatar',
        );
        _user = UserModel.fromJson(data['user']);
      } else {
        final body = <String, dynamic>{};
        if (name != null) body['name'] = name;
        if (phone != null) body['phone'] = phone;

        final data = await _api.patch('/auth/profile', body: body);
        _user = UserModel.fromJson(data['user']);
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _socket.disconnect();
    await _api.clearToken();
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }

  void _connectSocket() {
    if (_user != null) {
      _socket.connect(_user!.id);
    }
  }

  SocketService get socketService => _socket;
}
