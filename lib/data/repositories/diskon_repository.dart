import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_response.dart';
import '../../core/network/dio_client.dart';
import '../models/diskon_model.dart';

class DiskonRepository {
  final DioClient _client = DioClient();

  // GET ACTIVE DISKON
  Future<List<DiskonModel>> getActiveDiskon() async {
    try {
      final response = await _client.get(ApiEndpoints.activeDiskon);
      final raw = response.data;
      if (raw is Map<String, dynamic>) {
        final list = raw['data'];
        if (list is List) {
          return list.map((item) => DiskonModel.fromJson(item as Map<String, dynamic>)).toList();
        }
      } else if (raw is List) {
        return raw.map((item) => DiskonModel.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // CHECK PROMO CODE
  Future<DiskonModel> checkPromo(String namaDiskon) async {
    final clean = namaDiskon.trim();
    final cleanUpper = clean.toUpperCase();

    // 1. Coba request ke POST /api/diskon/check
    try {
      final response = await _client.post(
        ApiEndpoints.checkDiskon,
        data: {
          'nama_diskon': cleanUpper,
          'kode_promo': cleanUpper,
        },
      );

      final raw = response.data;
      if (raw is Map<String, dynamic>) {
        final isSuccess = raw['status'] == true || raw['statusCode'] == 200;
        final dataField = raw['data'];
        if (dataField is Map<String, dynamic>) {
          return DiskonModel.fromJson(dataField);
        } else if (dataField is List && dataField.isNotEmpty && dataField.first is Map<String, dynamic>) {
          return DiskonModel.fromJson(dataField.first as Map<String, dynamic>);
        } else if (raw['diskon'] is Map<String, dynamic>) {
          return DiskonModel.fromJson(raw['diskon'] as Map<String, dynamic>);
        } else if (isSuccess) {
          return DiskonModel.fromJson(raw);
        }
      }
    } catch (e) {
      // Jika POST gagal (misal 400/404), lanjut coba cari di daftar diskon aktif
    }

    // 2. Fallback: Cari di daftar active diskon (GET /api/diskon/active)
    try {
      final activeList = await getActiveDiskon();
      final match = activeList.where(
        (d) => d.namaDiskon.trim().toUpperCase() == cleanUpper,
      );
      if (match.isNotEmpty) {
        return match.first;
      }
    } catch (_) {}

    throw Exception('Kode promo "$cleanUpper" tidak valid atau sudah kedaluwarsa');
  }

  // GET DISKON DETAIL
  Future<DiskonModel> getDiskonDetail(int id) async {
    final response = await _client.get(ApiEndpoints.diskonDetail(id));
    final apiResponse = ApiResponse<DiskonModel>.fromJson(
      response.data,
      (json) => DiskonModel.fromJson(json as Map<String, dynamic>),
    );

    if (apiResponse.data != null) {
      return apiResponse.data!;
    }
    throw Exception(apiResponse.message);
  }
}
