import 'dart:io';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_response.dart';
import '../../core/network/dio_client.dart';
import '../models/user_model.dart';
import '../models/space_model.dart';
import '../models/diskon_model.dart';
import '../models/reservasi_model.dart';
import '../models/report_model.dart';

class AdminRepository {
  final DioClient _client = DioClient();

  // 1. PROFIL LOKASI COWORKING
  Future<UserModel> getProfile() async {
    final response = await _client.get(ApiEndpoints.adminProfile);
    final apiResponse = ApiResponse<UserModel>.fromJson(
      response.data,
      (json) => UserModel.fromJson(json as Map<String, dynamic>, defaultRole: 'admin_space'),
    );
    if (apiResponse.data != null) return apiResponse.data!;
    throw Exception(apiResponse.message);
  }

  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    final response = await _client.put(ApiEndpoints.adminProfile, data: data);
    final apiResponse = ApiResponse<UserModel>.fromJson(
      response.data,
      (json) => UserModel.fromJson(json as Map<String, dynamic>, defaultRole: 'admin_space'),
    );
    if (apiResponse.data != null) return apiResponse.data!;
    throw Exception(apiResponse.message);
  }

  // 2. MANAJEMEN MEMBER
  Future<List<UserModel>> getMembers({String? search}) async {
    final query = <String, dynamic>{};
    if (search != null && search.isNotEmpty) query['search'] = search;

    final response = await _client.get(
      ApiEndpoints.adminMembers,
      queryParameters: query.isNotEmpty ? query : null,
    );

    final apiResponse = ApiResponse<List<UserModel>>.fromJson(
      response.data,
      (json) {
        if (json is List) {
          return json.map((e) => UserModel.fromJson(e as Map<String, dynamic>, defaultRole: 'member')).toList();
        }
        return [];
      },
    );
    return apiResponse.data ?? [];
  }

  Future<UserModel> createMember(Map<String, dynamic> data) async {
    final response = await _client.post(ApiEndpoints.adminMembers, data: data);
    final apiResponse = ApiResponse<UserModel>.fromJson(
      response.data,
      (json) => UserModel.fromJson(json as Map<String, dynamic>, defaultRole: 'member'),
    );
    if (apiResponse.data != null) return apiResponse.data!;
    throw Exception(apiResponse.message);
  }

  Future<UserModel> getMemberDetail(int id) async {
    final response = await _client.get(ApiEndpoints.adminMemberDetail(id));
    final apiResponse = ApiResponse<UserModel>.fromJson(
      response.data,
      (json) => UserModel.fromJson(json as Map<String, dynamic>, defaultRole: 'member'),
    );
    if (apiResponse.data != null) return apiResponse.data!;
    throw Exception(apiResponse.message);
  }

  Future<UserModel> updateMember(int id, Map<String, dynamic> data) async {
    final response = await _client.put(ApiEndpoints.adminMemberDetail(id), data: data);
    final apiResponse = ApiResponse<UserModel>.fromJson(
      response.data,
      (json) => UserModel.fromJson(json as Map<String, dynamic>, defaultRole: 'member'),
    );
    if (apiResponse.data != null) return apiResponse.data!;
    throw Exception(apiResponse.message);
  }

  Future<bool> deleteMember(int id) async {
    final response = await _client.delete(ApiEndpoints.adminMemberDetail(id));
    final apiResponse = ApiResponse.fromJson(response.data, (json) => json);
    return apiResponse.status;
  }

  // 3. MANAJEMEN SPACE
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

  Future<List<SpaceModel>> getSpaces() async {
    try {
      final response = await _client.get(ApiEndpoints.adminSpaces);
      final list = _parseSpaceList(response.data);
      if (list.isNotEmpty) return list;

      if (response.data is Map<String, dynamic>) {
        final apiResponse = ApiResponse<List<SpaceModel>>.fromJson(
          response.data,
          (json) => _parseSpaceList(json),
        );
        if (apiResponse.data != null && apiResponse.data!.isNotEmpty) {
          return apiResponse.data!;
        }
      }
    } catch (_) {}

    // Fallback: Jika /api/admin/spaces gagal/unauthorized, gunakan endpoint /api/spaces
    try {
      final pubResponse = await _client.get(ApiEndpoints.spaces);
      final list = _parseSpaceList(pubResponse.data);
      if (list.isNotEmpty) return list;
    } catch (_) {}

    return [];
  }

  Future<SpaceModel> createSpace(Map<String, dynamic> data, {File? file}) async {
    // 1. Jika ada file langsung dan foto belum di-upload, upload dulu
    final map = Map<String, dynamic>.from(data);
    if (file != null && (map['foto'] == null || map['foto'].toString().isEmpty)) {
      final photoName = await uploadSpacePhoto(file);
      if (photoName.isNotEmpty) {
        map['foto'] = photoName;
      }
    }
    // Hapus key yang tidak valid di schema backend DTO
    map.remove('foto_url');

    final response = await _client.post(ApiEndpoints.adminSpaces, data: map);
    final apiResponse = ApiResponse<SpaceModel>.fromJson(
      response.data,
      (json) => SpaceModel.fromJson(json as Map<String, dynamic>),
    );
    if (apiResponse.data != null) return apiResponse.data!;
    if (apiResponse.status) {
      return SpaceModel.fromJson(map);
    }
    throw Exception(apiResponse.message.isNotEmpty ? apiResponse.message : 'Gagal membuat space');
  }

  Future<SpaceModel> getSpaceDetail(int id) async {
    try {
      final response = await _client.get(ApiEndpoints.adminSpaceDetail(id));
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
    } catch (_) {}

    // Fallback ke endpoint publik
    try {
      final pubResponse = await _client.get(ApiEndpoints.spaceDetail(id));
      dynamic target = pubResponse.data;
      if (target is Map<String, dynamic> && target.containsKey('data')) {
        target = target['data'];
      }
      if (target is Map<String, dynamic>) {
        if (target.containsKey('space') && target['space'] is Map<String, dynamic>) {
          target = target['space'];
        }
        return SpaceModel.fromJson(target as Map<String, dynamic>);
      }
    } catch (_) {}

    throw Exception('Gagal memuat detail space');
  }

  Future<SpaceModel> updateSpace(int id, Map<String, dynamic> data, {File? file}) async {
    final map = Map<String, dynamic>.from(data);
    // 1. Jika ada file baru, pastikan di-upload ke backend /api/upload/spaces
    if (file != null) {
      final photoName = await uploadSpacePhoto(file);
      if (photoName.isNotEmpty) {
        map['foto'] = photoName;
      }
    }
    // Hapus key yang tidak valid di schema backend DTO
    map.remove('foto_url');

    final response = await _client.put(ApiEndpoints.adminSpaceDetail(id), data: map);
    final apiResponse = ApiResponse<SpaceModel>.fromJson(
      response.data,
      (json) => SpaceModel.fromJson(json as Map<String, dynamic>),
    );
    if (apiResponse.data != null) return apiResponse.data!;
    if (apiResponse.status) {
      return SpaceModel.fromJson(Map<String, dynamic>.from(map)..['id'] = id);
    }
    throw Exception(apiResponse.message.isNotEmpty ? apiResponse.message : 'Gagal memperbarui space');
  }

  Future<bool> deleteSpace(int id) async {
    final response = await _client.delete(ApiEndpoints.adminSpaceDetail(id));
    final apiResponse = ApiResponse.fromJson(response.data, (json) => json);
    return apiResponse.status;
  }

  Future<String> uploadSpacePhoto(File file) async {
    String extractFilename(String raw) {
      String clean = raw.trim();
      if (clean.contains('?')) clean = clean.split('?').first;
      if (clean.contains('/')) clean = clean.split('/').last;
      if (clean.contains('\\')) clean = clean.split('\\').last;
      return clean;
    }

    try {
      final response = await _client.uploadFile(
        ApiEndpoints.uploadSpaces,
        file: file,
        fileKey: 'file',
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final inner = data['data'];
        String raw = '';
        if (inner is Map<String, dynamic>) {
          raw = inner['filename']?.toString() ??
              inner['foto']?.toString() ??
              inner['url']?.toString() ??
              inner['path']?.toString() ??
              inner['foto_url']?.toString() ??
              inner['file']?.toString() ??
              '';
        } else if (inner is String) {
          raw = inner;
        } else {
          raw = data['filename']?.toString() ??
              data['foto']?.toString() ??
              data['url']?.toString() ??
              data['path']?.toString() ??
              '';
        }
        if (raw.isNotEmpty) {
          return extractFilename(raw);
        }
      }
      return '';
    } catch (_) {
      // Fallback ke upload general image jika uploadSpaces spesifik error
      try {
        final response = await _client.uploadFile(
          ApiEndpoints.uploadImage,
          file: file,
          fileKey: 'file',
        );
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final inner = data['data'];
          String raw = '';
          if (inner is Map<String, dynamic>) {
            raw = inner['filename']?.toString() ??
                inner['foto']?.toString() ??
                inner['url']?.toString() ??
                inner['path']?.toString() ??
                '';
          } else if (inner is String) {
            raw = inner;
          } else {
            raw = data['filename']?.toString() ?? data['url']?.toString() ?? '';
          }
          if (raw.isNotEmpty) {
            return extractFilename(raw);
          }
        }
      } catch (_) {}
      return '';
    }
  }

  // 4. MANAJEMEN DISKON
  Future<List<DiskonModel>> getDiskon() async {
    try {
      final response = await _client.get(ApiEndpoints.adminDiskon);
      final raw = response.data;
      if (raw is Map<String, dynamic>) {
        final list = raw['data'];
        if (list is List) {
          return list.map((e) => DiskonModel.fromJson(e as Map<String, dynamic>)).toList();
        }
      } else if (raw is List) {
        return raw.map((e) => DiskonModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<DiskonModel> createDiskon(Map<String, dynamic> data) async {
    final response = await _client.post(ApiEndpoints.adminDiskon, data: data);
    final raw = response.data;
    if (raw is Map<String, dynamic>) {
      final isSuccess = raw['status'] == true || raw['statusCode'] == 200 || raw['statusCode'] == 201;
      if (isSuccess) {
        final inner = raw['data'];
        if (inner is Map<String, dynamic>) {
          return DiskonModel.fromJson(inner);
        }
        return DiskonModel.fromJson(data);
      }
      throw Exception(raw['message'] ?? 'Gagal membuat diskon');
    }
    return DiskonModel.fromJson(data);
  }

  Future<DiskonModel> getDiskonDetail(int id) async {
    final response = await _client.get(ApiEndpoints.adminDiskonDetail(id));
    final raw = response.data;
    if (raw is Map<String, dynamic>) {
      final inner = raw['data'];
      if (inner is Map<String, dynamic>) {
        return DiskonModel.fromJson(inner);
      }
    }
    throw Exception('Diskon tidak ditemukan');
  }

  Future<DiskonModel> updateDiskon(int id, Map<String, dynamic> data) async {
    final response = await _client.put(ApiEndpoints.adminDiskonDetail(id), data: data);
    final raw = response.data;
    if (raw is Map<String, dynamic>) {
      final isSuccess = raw['status'] == true || raw['statusCode'] == 200 || raw['statusCode'] == 201;
      if (isSuccess) {
        final inner = raw['data'];
        if (inner is Map<String, dynamic>) {
          return DiskonModel.fromJson(inner);
        }
        return DiskonModel.fromJson(data);
      }
      throw Exception(raw['message'] ?? 'Gagal memperbarui diskon');
    }
    return DiskonModel.fromJson(data);
  }

  Future<bool> deleteDiskon(int id) async {
    final response = await _client.delete(ApiEndpoints.adminDiskonDetail(id));
    final raw = response.data;
    if (raw is Map<String, dynamic>) {
      return raw['status'] == true || raw['statusCode'] == 200;
    }
    return true;
  }

  // 5. RESERVASI & OPERASIONAL
  List<ReservasiModel> _parseReservasiList(dynamic rawData) {
    if (rawData == null) return [];
    dynamic target = rawData;
    if (rawData is Map<String, dynamic> && rawData.containsKey('data')) {
      target = rawData['data'];
    }
    if (target is List) {
      return target
          .whereType<Map<String, dynamic>>()
          .map((item) => ReservasiModel.fromJson(item))
          .toList();
    }
    if (target is Map<String, dynamic>) {
      for (final key in [
        'reservasi',
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
      if (target.containsKey('id') || target.containsKey('kode_reservasi')) {
        return [ReservasiModel.fromJson(target)];
      }
    }
    return [];
  }

  Future<List<ReservasiModel>> getReservasi({
    int? month,
    int? year,
    String? status,
    int? idSpace,
    String? tanggal,
  }) async {
    final query = <String, dynamic>{};
    if (month != null) query['month'] = month;
    if (year != null) query['year'] = year;
    if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') {
      query['status'] = status;
    }
    if (idSpace != null) query['id_space'] = idSpace;
    if (tanggal != null && tanggal.isNotEmpty) query['tanggal'] = tanggal;

    try {
      final response = await _client.get(
        ApiEndpoints.adminReservasi,
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
      // Fallback: jika /api/admin/reservasi gagal, coba endpoint /api/reservasi
      try {
        final fallbackResp = await _client.get(
          ApiEndpoints.reservasi,
          queryParameters: query.isNotEmpty ? query : null,
        );
        return _parseReservasiList(fallbackResp.data);
      } catch (_) {}
      return [];
    }
  }

  Future<ReservasiModel> updateReservasiStatus(int id, String status) async {
    final response = await _client.patch(
      ApiEndpoints.adminReservasiStatus(id),
      data: {'status': status},
    );
    final apiResponse = ApiResponse<ReservasiModel>.fromJson(
      response.data,
      (json) => ReservasiModel.fromJson(json as Map<String, dynamic>),
    );
    if (apiResponse.data != null) return apiResponse.data!;
    throw Exception(apiResponse.message);
  }

  Future<ReservasiModel> checkIn(int id) async {
    final response = await _client.post(ApiEndpoints.adminCheckIn(id));
    final apiResponse = ApiResponse<ReservasiModel>.fromJson(
      response.data,
      (json) => ReservasiModel.fromJson(json as Map<String, dynamic>),
    );
    if (apiResponse.data != null) return apiResponse.data!;
    throw Exception(apiResponse.message);
  }

  Future<ReservasiModel> checkOut(int id) async {
    final response = await _client.post(ApiEndpoints.adminCheckOut(id));
    final apiResponse = ApiResponse<ReservasiModel>.fromJson(
      response.data,
      (json) => ReservasiModel.fromJson(json as Map<String, dynamic>),
    );
    if (apiResponse.data != null) return apiResponse.data!;
    throw Exception(apiResponse.message);
  }

  // 6. LAPORAN PENDAPATAN
  Future<MonthlyReportModel> getMonthlyReport({int? month, int? year}) async {
    final query = <String, dynamic>{};
    if (month != null) {
      query['month'] = month;
      query['bulan'] = month;
    }
    if (year != null) {
      query['year'] = year;
      query['tahun'] = year;
    }

    // Coba endpoint utama: /api/admin/reports/monthly
    try {
      final response = await _client.get(
        ApiEndpoints.adminReportsMonthly,
        queryParameters: query.isNotEmpty ? query : null,
      );

      final apiResponse = ApiResponse<MonthlyReportModel>.fromJson(
        response.data,
        (json) => MonthlyReportModel.fromJson(json as Map<String, dynamic>),
      );

      if (apiResponse.data != null) return apiResponse.data!;
    } catch (_) {
      // Coba endpoint alternatif: /api/admin/reports/income
      try {
        final altResponse = await _client.get(
          ApiEndpoints.adminReportsIncome,
          queryParameters: query.isNotEmpty ? query : null,
        );
        final altApiResponse = ApiResponse<MonthlyReportModel>.fromJson(
          altResponse.data,
          (json) => MonthlyReportModel.fromJson(json as Map<String, dynamic>),
        );
        if (altApiResponse.data != null) return altApiResponse.data!;
      } catch (_) {}
    }

    return MonthlyReportModel(
      bulan: month ?? DateTime.now().month,
      tahun: year ?? DateTime.now().year,
      totalPendapatan: 0.0,
      totalReservasi: 0,
      breakdown: [],
    );
  }
}
