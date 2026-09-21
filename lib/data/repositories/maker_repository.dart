import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_response.dart';
import '../../core/network/dio_client.dart';
import '../../core/storage/secure_storage_service.dart';
import '../models/maker_model.dart';

class MakerRepository {
  final DioClient _client = DioClient();
  final SecureStorageService _storage = SecureStorageService();

  // Register App Maker
  Future<MakerModel> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      ApiEndpoints.makerRegister,
      data: {
        'name': name,
        'username': username,
        'email': email,
        'password': password,
      },
    );

    final apiResponse = ApiResponse<MakerModel>.fromJson(
      response.data,
      (json) => MakerModel.fromJson(json as Map<String, dynamic>),
    );

    if (apiResponse.data != null) {
      await _storage.saveAppKey(apiResponse.data!.appKey);
      return apiResponse.data!;
    }
    throw Exception(apiResponse.message);
  }

  // Login App Maker
  Future<MakerModel> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    final response = await _client.post(
      ApiEndpoints.makerLogin,
      data: {
        'usernameOrEmail': usernameOrEmail,
        'password': password,
      },
    );

    final apiResponse = ApiResponse<MakerModel>.fromJson(
      response.data,
      (json) => MakerModel.fromJson(json as Map<String, dynamic>),
    );

    if (apiResponse.data != null) {
      await _storage.saveAppKey(apiResponse.data!.appKey);
      return apiResponse.data!;
    }
    throw Exception(apiResponse.message);
  }

  // List Makers (Guru/Penguji)
  Future<List<MakerModel>> listMakers() async {
    final response = await _client.get(ApiEndpoints.makerList);
    final apiResponse = ApiResponse<List<MakerModel>>.fromJson(
      response.data,
      (json) {
        if (json is List) {
          return json.map((e) => MakerModel.fromJson(e as Map<String, dynamic>)).toList();
        }
        return [];
      },
    );

    return apiResponse.data ?? [];
  }
}
