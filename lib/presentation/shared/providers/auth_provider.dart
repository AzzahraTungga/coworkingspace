import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/maker_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepo = AuthRepository();
  final MakerRepository _makerRepo = MakerRepository();
  final SecureStorageService _storage = SecureStorageService();

  UserModel? _currentUser;
  String? _token;
  String? _role;
  String? _appKey;
  String _baseUrl = ApiEndpoints.defaultBaseUrl;

  bool _isInitialized = false;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  String? get role => _role;
  String? get appKey => _appKey;
  String get baseUrl => _baseUrl;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  bool get isMember => _role == 'member';
  bool get isAdmin => _role == 'admin_space';
  bool get hasAppKey => _appKey != null && _appKey!.isNotEmpty;

  // INISIALISASI SESI SAAT APLIKASI DIJALANKAN
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _baseUrl = await _storage.getBaseUrl();
      _appKey = await _storage.getAppKey();
      _token = await _storage.getToken();
      _role = await _storage.getRole();

      final userJson = await _storage.getUserData();
      if (userJson != null && userJson.isNotEmpty) {
        try {
          _currentUser = UserModel.fromJson(
            jsonDecode(userJson) as Map<String, dynamic>,
            defaultRole: _role,
          );
        } catch (_) {}
      }

      // Jika ada token, coba sync profile terbaru
      if (_token != null && _token!.isNotEmpty) {
        try {
          _currentUser = await _authRepo.getProfile();
        } catch (_) {
          // Token expired atau jaringan offline, biarkan cache
        }
      }
    } finally {
      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
    }
  }

  // LOGIN USER
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final authData = await _authRepo.login(
        username: username.trim(),
        password: password,
      );

      _token = authData.token;
      _role = authData.role;
      _currentUser = authData.user;
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // REGISTER MEMBER
  Future<bool> registerMember({
    required String username,
    required String password,
    required String namaMember,
    required String instansi,
    required String alamat,
    required String telp,
    String? foto,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepo.registerMember(
        username: username.trim(),
        password: password,
        namaMember: namaMember.trim(),
        instansi: instansi.trim(),
        alamat: alamat.trim(),
        telp: telp.trim(),
        foto: foto,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // REGISTER ADMIN SPACE
  Future<bool> registerAdminSpace({
    required String username,
    required String password,
    required String namaCoworking,
    required String namaPemilik,
    required String telp,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepo.registerAdminSpace(
        username: username.trim(),
        password: password,
        namaCoworking: namaCoworking.trim(),
        namaPemilik: namaPemilik.trim(),
        telp: telp.trim(),
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // SET APP KEY MANUAL / HASIL MAKER REGISTER
  Future<void> setAppKey(String key) async {
    final cleanKey = key.trim();
    await _storage.saveAppKey(cleanKey);
    _appKey = cleanKey;
    notifyListeners();
  }

  // SET BASE URL DINAMIS
  Future<void> setBaseUrl(String url) async {
    final cleanUrl = url.trim();
    await _storage.saveBaseUrl(cleanUrl);
    _baseUrl = cleanUrl;
    notifyListeners();
  }

  // AUTO REGISTER APP MAKER (JIKA BELUM MEMILIKI APP KEY)
  Future<bool> autoRegisterMaker({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final maker = await _makerRepo.register(
        name: name.trim(),
        username: username.trim(),
        email: email.trim(),
        password: password,
      );
      _appKey = maker.appKey;
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // LOGOUT
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _authRepo.logout();
    _token = null;
    _role = null;
    _currentUser = null;

    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
