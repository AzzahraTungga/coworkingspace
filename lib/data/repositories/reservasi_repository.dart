import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_response.dart';
import '../../core/network/dio_client.dart';
import '../models/reservasi_model.dart';
import '../models/e_ticket_model.dart';

class ReservasiRepository {
  final DioClient _client = DioClient();

  // CREATE RESERVASI
  Future<ReservasiModel> createReservasi(CreateReservasiDto dto) async {
    final response = await _client.post(
      ApiEndpoints.reservasi,
      data: dto.toJson(),
    );

    final apiResponse = ApiResponse<ReservasiModel>.fromJson(
      response.data,
      (json) => ReservasiModel.fromJson(json as Map<String, dynamic>),
    );

    if (apiResponse.data != null) {
      return apiResponse.data!;
    }
    throw Exception(apiResponse.message.isNotEmpty ? apiResponse.message : 'Gagal membuat reservasi');
  }

  // Helper parser yang dapat menangani berbagai format respon backend
  List<ReservasiModel> _parseReservasiList(dynamic rawData) {
    if (rawData == null) return [];

    // Jika berupa ApiResponse map, ambil target data di dalamnya
    dynamic target = rawData;
    if (rawData is Map<String, dynamic>) {
      if (rawData.containsKey('data')) {
        target = rawData['data'];
      }
    }

    if (target is List) {
      return target
          .whereType<Map<String, dynamic>>()
          .map((item) => ReservasiModel.fromJson(item))
          .toList();
    }

    if (target is Map<String, dynamic>) {
      // Cek kemungkinan list dibungkus key tertentu
      for (final key in [
        'reservasi',
        'my_reservasi',
        'history',
        'reservations',
        'data',
        'list',
        'items',
        'rows'
      ]) {
        if (target[key] is List) {
          return (target[key] as List)
              .whereType<Map<String, dynamic>>()
              .map((item) => ReservasiModel.fromJson(item))
              .toList();
        }
      }
      // Jika ternyata berupa single object reservasi
      if (target.containsKey('id') || target.containsKey('kode_reservasi')) {
        return [ReservasiModel.fromJson(target)];
      }
    }

    return [];
  }

  // GET MY ACTIVE / LATEST RESERVASI
  Future<List<ReservasiModel>> getMyReservasi() async {
    try {
      final response = await _client.get(ApiEndpoints.myReservasi);
      final list = _parseReservasiList(response.data);
      if (list.isNotEmpty) return list;

      if (response.data is Map<String, dynamic>) {
        final apiResponse = ApiResponse<List<ReservasiModel>>.fromJson(
          response.data,
          (json) => _parseReservasiList(json),
        );
        if (apiResponse.data != null && apiResponse.data!.isNotEmpty) {
          return apiResponse.data!;
        }
      }
      return list;
    } catch (e) {
      // Fallback: coba endpoint /api/reservasi jika /api/reservasi/my 404
      try {
        final fallbackResp = await _client.get(ApiEndpoints.reservasi);
        return _parseReservasiList(fallbackResp.data);
      } catch (_) {}
      return [];
    }
  }

  // GET MY RESERVASI HISTORY (FILTER MONTH & YEAR)
  Future<List<ReservasiModel>> getMyReservasiHistory({int? month, int? year}) async {
    final query = <String, dynamic>{};
    if (month != null) query['month'] = month;
    if (year != null) query['year'] = year;

    try {
      final response = await _client.get(
        ApiEndpoints.myReservasiHistory,
        queryParameters: query.isNotEmpty ? query : null,
      );

      final list = _parseReservasiList(response.data);
      if (list.isNotEmpty) return list;

      if (response.data is Map<String, dynamic>) {
        final apiResponse = ApiResponse<List<ReservasiModel>>.fromJson(
          response.data,
          (json) => _parseReservasiList(json),
        );
        if (apiResponse.data != null && apiResponse.data!.isNotEmpty) {
          return apiResponse.data!;
        }
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  // GET E-TICKET
  Future<ETicketModel> getETicket(int id) async {
    final response = await _client.get(ApiEndpoints.reservasiETicket(id));
    final apiResponse = ApiResponse<ETicketModel>.fromJson(
      response.data,
      (json) => ETicketModel.fromJson(json as Map<String, dynamic>),
    );

    if (apiResponse.data != null) {
      return apiResponse.data!;
    }
    throw Exception(apiResponse.message.isNotEmpty ? apiResponse.message : 'Gagal memuat e-ticket');
  }

  // GET RESERVASI DETAIL
  Future<ReservasiModel> getReservasiDetail(int id) async {
    final response = await _client.get(ApiEndpoints.reservasiDetail(id));
    final apiResponse = ApiResponse<ReservasiModel>.fromJson(
      response.data,
      (json) => ReservasiModel.fromJson(json as Map<String, dynamic>),
    );

    if (apiResponse.data != null) {
      return apiResponse.data!;
    }
    throw Exception(apiResponse.message);
  }

  // CANCEL RESERVASI
  Future<ApiResponse<dynamic>> cancelReservasi(int id) async {
    final response = await _client.patch(ApiEndpoints.cancelReservasi(id));
    return ApiResponse.fromJson(response.data, (json) => json);
  }
}
