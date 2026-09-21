import '../../core/constants/api_endpoints.dart';
import '../../core/errors/app_exception.dart';
import '../../core/network/api_response.dart';
import '../../core/network/dio_client.dart';
import '../models/space_model.dart';

class SpaceRepository {
  final DioClient _client = DioClient();

  // GET ALL SPACES
  Future<List<SpaceModel>> getSpaces({
    String? tipe,
    String? search,
  }) async {
    final query = <String, dynamic>{};
    if (tipe != null && tipe.isNotEmpty && tipe.toLowerCase() != 'all') {
      query['tipe'] = tipe;
    }
    if (search != null && search.isNotEmpty) {
      query['search'] = search;
    }

    final response = await _client.get(
      ApiEndpoints.spaces,
      queryParameters: query.isNotEmpty ? query : null,
    );

    final list = _parseSpaceList(response.data);
    if (list.isNotEmpty) return list;

    if (response.data is Map<String, dynamic>) {
      final apiResponse = ApiResponse<List<SpaceModel>>.fromJson(
        response.data,
        (json) => _parseSpaceList(json),
      );
      if (apiResponse.data != null) return apiResponse.data!;
    }

    return list;
  }

  List<SpaceModel> _parseSpaceList(dynamic rawData) {
    if (rawData == null) return [];
    dynamic target = rawData;
    if (rawData is Map<String, dynamic> && rawData.containsKey('data')) {
      target = rawData['data'];
    }
    if (target is List) {
      return target
          .whereType<Map<String, dynamic>>()
          .map((item) => SpaceModel.fromJson(item))
          .toList();
    }
    if (target is Map<String, dynamic>) {
      for (final key in ['spaces', 'space', 'data', 'list', 'items', 'rows']) {
        if (target[key] is List) {
          return (target[key] as List)
              .whereType<Map<String, dynamic>>()
              .map((item) => SpaceModel.fromJson(item))
              .toList();
        }
      }
      if (target.containsKey('id') || target.containsKey('nama_space') || target.containsKey('title')) {
        return [SpaceModel.fromJson(target)];
      }
    }
    return [];
  }

  // GET SPACE DETAIL
  Future<SpaceModel> getSpaceDetail(int id) async {
    final response = await _client.get(ApiEndpoints.spaceDetail(id));
    dynamic target = response.data;
    if (target is Map<String, dynamic> && target.containsKey('data')) {
      target = target['data'];
    }
    if (target is Map<String, dynamic>) {
      if (target.containsKey('space') && target['space'] is Map<String, dynamic>) {
        target = target['space'];
      }
      return SpaceModel.fromJson(target as Map<String, dynamic>);
    }
    throw Exception('Gagal memuat detail space');
  }

  // GET SPACE TYPES
  Future<List<String>> getSpaceTypes() async {
    final response = await _client.get(ApiEndpoints.spaceTypes);
    final apiResponse = ApiResponse<List<String>>.fromJson(
      response.data,
      (json) {
        if (json is List) {
          return json.map((e) => e.toString()).toList();
        }
        return ['desk', 'meeting_room', 'private_office'];
      },
    );

    return apiResponse.data ?? ['desk', 'meeting_room', 'private_office'];
  }

  // CHECK AVAILABILITY DETAIL
  Future<Map<String, dynamic>> checkAvailabilityDetail({
    required int idSpace,
    required String tanggal,
    required String jamMulai,
    required int durasiJam,
  }) async {
    try {
      final response = await _client.get(
        ApiEndpoints.spaceAvailability,
        queryParameters: {
          'id_space': idSpace,
          'tanggal': tanggal,
          'tanggal_reservasi': tanggal,
          'jam_mulai': jamMulai,
          'durasi_jam': durasiJam,
          'durasi': durasiJam,
        },
      );

      final apiResponse = ApiResponse<dynamic>.fromJson(response.data, (json) => json);

      if (apiResponse.data is Map<String, dynamic>) {
        final map = apiResponse.data as Map<String, dynamic>;
        final val = map['is_available'] ?? map['available'] ?? map['status'];
        if (val != null) {
          final s = val.toString().toLowerCase();
          final isAvail = (s == 'true' || s == '1' || s == 'available' || s == 'tersedia');
          final msg = map['message']?.toString() ??
              (isAvail
                  ? 'Slot waktu tersedia! Belum ada bookingan pada jam ini.'
                  : 'Slot waktu sudah ada bookingan lain pada jam tersebut.');
          return {'available': isAvail, 'message': msg};
        }
      }

      if (apiResponse.data is bool) {
        final isAvail = apiResponse.data as bool;
        return {
          'available': isAvail,
          'message': isAvail
              ? 'Slot waktu tersedia! Belum ada bookingan pada jam ini.'
              : 'Slot waktu sudah ada bookingan lain pada jam tersebut.',
        };
      }

      final msg = apiResponse.message.toLowerCase();
      if (msg.contains('tidak tersedia') ||
          msg.contains('sudah terisi') ||
          msg.contains('penuh') ||
          msg.contains('bentrok') ||
          msg.contains('booked') ||
          msg.contains('sudah ada bookingan')) {
        return {
          'available': false,
          'message': apiResponse.message.isNotEmpty
              ? apiResponse.message
              : 'Slot waktu sudah ada bookingan lain pada jam tersebut.',
        };
      }

      final isAvail = apiResponse.status;
      return {
        'available': isAvail,
        'message': apiResponse.message.isNotEmpty
            ? apiResponse.message
            : (isAvail
                ? 'Slot waktu tersedia! Belum ada bookingan pada jam ini.'
                : 'Slot waktu sudah terisi atau tidak tersedia.'),
      };
    } on AppException catch (e) {
      return {
        'available': false,
        'message': e.message.isNotEmpty
            ? e.message
            : 'Slot waktu sudah ada bookingan lain pada jam tersebut.',
      };
    } catch (e) {
      return {
        'available': false,
        'message': 'Gagal memeriksa ketersediaan slot waktu.',
      };
    }
  }

  // CHECK AVAILABILITY
  Future<bool> checkAvailability({
    required int idSpace,
    required String tanggal,
    required String jamMulai,
    required int durasiJam,
  }) async {
    final result = await checkAvailabilityDetail(
      idSpace: idSpace,
      tanggal: tanggal,
      jamMulai: jamMulai,
      durasiJam: durasiJam,
    );
    return result['available'] == true;
  }
}
