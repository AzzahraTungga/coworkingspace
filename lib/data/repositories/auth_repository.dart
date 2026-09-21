import 'dart:convert';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_response.dart';
import '../../core/network/dio_client.dart';
import '../../core/storage/secure_storage_service.dart';
import '../models/user_model.dart';

class AuthRepository {
  final DioClient _client = DioClient();
  final SecureStorageService _storage = SecureStorageService();

  // LOGIN USER (MEMBER / ADMIN)
  Future<AuthResponseData> login({
    required String username,
    required String password,
  }) async {
    final response = await _client.post(
      ApiEndpoints.login,
      data: {
        'username': username,
        'password': password,
      },
    );

    final apiResponse = ApiResponse<AuthResponseData>.fromJson(
      response.data,
      (json) => AuthResponseData.fromJson(json as Map<String, dynamic>),
    );

    if (!apiResponse.status || apiResponse.data == null) {
      throw Exception(apiResponse.message.isNotEmpty ? apiResponse.message : 'Login gagal');
    }

    final authData = apiResponse.data!;

    // Simpan ke Secure Storage
    await _storage.saveToken(authData.token);
    await _storage.saveRole(authData.role);
    await _storage.saveUserData(jsonEncode(authData.user.toJson()));

    return authData;
  }

  // REGISTER MEMBER
  Future<ApiResponse<dynamic>> registerMember({
    required String username,
    required String password,
    required String namaMember,
    required String instansi,
    required String alamat,
    required String telp,
    String? foto,
  }) async {
    final response = await _client.post(
      ApiEndpoints.registerMember,
      data: {
        'username': username,
        'password': password,
        'nama_member': namaMember,
        'instansi': instansi,
        'alamat': alamat,
        'telp': telp,
        if (foto != null && foto.isNotEmpty) 'foto': foto,
      },
    );

    return ApiResponse.fromJson(response.data, (json) => json);
  }

  // REGISTER ADMIN SPACE
  Future<ApiResponse<dynamic>> registerAdminSpace({
    required String username,
    required String password,
    required String namaCoworking,
    required String namaPemilik,
    required String telp,
  }) async {
    final response = await _client.post(
      ApiEndpoints.registerAdminSpace,
      data: {
        'username': username,
        'password': password,
        'nama_coworking': namaCoworking,
        'nama_pemilik': namaPemilik,
        'telp': telp,
      },
    );

    return ApiResponse.fromJson(response.data, (json) => json);
  }

  // GET MY PROFILE
  Future<UserModel> getProfile() async {
    final response = await _client.get(ApiEndpoints.profile);
    final apiResponse = ApiResponse<UserModel>.fromJson(
      response.data,
      (json) => UserModel.fromJson(json as Map<String, dynamic>),
    );

    if (apiResponse.data != null) {
      await _storage.saveUserData(jsonEncode(apiResponse.data!.toJson()));
      return apiResponse.data!;
    }
    throw Exception(apiResponse.message);
  }

  // LOGOUT
  Future<void> logout() async {
    await _storage.clearSession();
  }
}
