import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final SocketService _socket = SocketService();
  final fb.FirebaseAuth _firebaseAuth = fb.FirebaseAuth.instance;

  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  // Firebase OTP state
  String? _verificationId;
  int? _resendToken;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  String? get error => _error;

  Future<void> init() async {
    try {
      final token = await _api.token;
      if (token != null) {
        await fetchProfile().timeout(
          const Duration(seconds: 8),
          onTimeout: () => logout(),
        );
      }
    } catch (_) {
      // Fail silently — go to welcome screen
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

  // ---- Firebase Phone OTP Auth ----

  Future<void> sendOtp(String phoneNumber) async {
    _error = null;
    notifyListeners();

    debugPrint('📱 Sending OTP to: $phoneNumber');

    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      forceResendingToken: _resendToken,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (fb.PhoneAuthCredential credential) async {
        debugPrint('✅ Auto-verification completed');
        // Auto-verification on Android
        await _signInWithCredential(credential);
      },
      verificationFailed: (fb.FirebaseAuthException e) {
        debugPrint('❌ Verification failed: ${e.code} - ${e.message}');
        _error = e.message ?? 'Verification failed';
        notifyListeners();
        throw Exception(_error);
      },
      codeSent: (String verificationId, int? resendToken) {
        debugPrint('📨 OTP code sent! verificationId: $verificationId');
        _verificationId = verificationId;
        _resendToken = resendToken;
        notifyListeners();
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        debugPrint('⏰ Auto-retrieval timeout');
        _verificationId = verificationId;
      },
    );
  }

  Future<bool> verifyOtpAndLogin(String otp) async {
    if (_verificationId == null) {
      _error = 'No verification in progress';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final credential = fb.PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      return await _signInWithCredential(credential);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> _signInWithCredential(fb.PhoneAuthCredential credential) async {
    try {
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) throw Exception('Firebase sign-in returned no user');
      final idToken = await user.getIdToken();

      // Send Firebase token to backend
      final data = await _api.post('/auth/firebase-auth', body: {
        'firebaseToken': idToken,
      });

      await _api.setToken(data['token']);
      _user = UserModel.fromJson(data['user']);
      _connectSocket();
      _isLoading = false;
      notifyListeners();
      return true;
    } on fb.FirebaseAuthException catch (e) {
      _error = e.message ?? 'Authentication failed';
      _isLoading = false;
      notifyListeners();
      return false;
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

  Future<bool> updateProfile({String? name, String? email, String? phone, String? avatarPath}) async {
    try {
      if (avatarPath != null) {
        // Use multipart upload when avatar file is provided
        final fields = <String, String>{};
        if (name != null) fields['name'] = name;
        if (email != null) fields['email'] = email;
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
        if (email != null) body['email'] = email;
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

  // ---- Become Seller ----

  Future<bool> becomeSeller() async {
    try {
      final data = await _api.patch('/auth/become-seller', body: {});
      _user = UserModel.fromJson(data['user']);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ---- Address Management ----

  Future<bool> addAddress(Map<String, dynamic> addressData) async {
    try {
      await _api.post('/auth/address', body: addressData);
      await fetchProfile();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAddress(String addressId, Map<String, dynamic> addressData) async {
    try {
      await _api.patch('/auth/address/$addressId', body: addressData);
      await fetchProfile();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAddress(String addressId) async {
    try {
      await _api.delete('/auth/address/$addressId');
      await fetchProfile();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> setDefaultAddress(String addressId) async {
    try {
      await _api.patch('/auth/address/$addressId/default', body: {});
      await fetchProfile();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
