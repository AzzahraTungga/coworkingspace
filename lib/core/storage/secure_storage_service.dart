import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_endpoints.dart';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _keyToken = 'access_token';
  static const String _keyRole = 'user_role';
  static const String _keyAppKey = 'app_key';
  static const String _keyUserData = 'user_data';
  static const String _keyBaseUrl = 'base_url';

  // Base URL
  Future<void> saveBaseUrl(String url) async {
    await _storage.write(key: _keyBaseUrl, value: url);
  }

  Future<String> getBaseUrl() async {
    final url = await _storage.read(key: _keyBaseUrl);
    return (url != null && url.isNotEmpty) ? url : ApiEndpoints.defaultBaseUrl;
  }

  // Token
  Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _keyToken);
  }

  // Role
  Future<void> saveRole(String role) async {
    await _storage.write(key: _keyRole, value: role);
  }

  Future<String?> getRole() async {
    return await _storage.read(key: _keyRole);
  }

  Future<void> deleteRole() async {
    await _storage.delete(key: _keyRole);
  }

  // App Key (Multi-Tenancy)
  Future<void> saveAppKey(String appKey) async {
    await _storage.write(key: _keyAppKey, value: appKey);
  }

  Future<String?> getAppKey() async {
    final key = await _storage.read(key: _keyAppKey);
    return (key != null && key.isNotEmpty) ? key : ApiEndpoints.defaultAppKey;
  }

  Future<void> deleteAppKey() async {
    await _storage.delete(key: _keyAppKey);
  }

  // User Data Cache
  Future<void> saveUserData(String userDataJson) async {
    await _storage.write(key: _keyUserData, value: userDataJson);
  }

  Future<String?> getUserData() async {
    return await _storage.read(key: _keyUserData);
  }

  Future<void> deleteUserData() async {
    await _storage.delete(key: _keyUserData);
  }

  // Clear Session (Logout) - Note: Preserves appKey and baseUrl!
  Future<void> clearSession() async {
    await deleteToken();
    await deleteRole();
    await deleteUserData();
  }

  // Clear All
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
