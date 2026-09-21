import '../../core/constants/api_endpoints.dart';

class UserModel {
  final int id;
  final String username;
  final String role; // 'member' or 'admin_space'
  final String? namaMember;
  final String? instansi;
  final String? alamat;
  final String? telp;
  final String? foto;
  final String? fotoUrl;

  // Khusus Admin Space
  final String? namaCoworking;
  final String? namaPemilik;

  UserModel({
    required this.id,
    required this.username,
    required this.role,
    this.namaMember,
    this.instansi,
    this.alamat,
    this.telp,
    this.foto,
    this.fotoUrl,
    this.namaCoworking,
    this.namaPemilik,
  });

  String get displayName {
    if (role == 'admin_space') {
      return namaCoworking ?? namaPemilik ?? username;
    }
    return namaMember ?? username;
  }

  bool get hasCustomFoto =>
      (foto != null && foto!.trim().isNotEmpty && foto != 'null') ||
      (fotoUrl != null && fotoUrl!.trim().isNotEmpty && fotoUrl != 'null');

  String get displayFotoUrl {
    final raw = (foto != null && foto!.trim().isNotEmpty && foto != 'null')
        ? foto!.trim()
        : ((fotoUrl != null && fotoUrl!.trim().isNotEmpty && fotoUrl != 'null')
            ? fotoUrl!.trim()
            : null);

    if (raw != null && raw.isNotEmpty) {
      if ((raw.startsWith('http://') || raw.startsWith('https://')) &&
          !raw.contains('learn.smktelkom-mlg.sch.id')) {
        return raw;
      }

      String filename = raw;
      if (filename.contains('?')) {
        filename = filename.split('?').first;
      }
      if (filename.contains('/')) {
        filename = filename.split('/').last;
      }
      if (filename.contains('\\')) {
        filename = filename.split('\\').last;
      }

      if (filename.isNotEmpty && filename != 'null') {
        return '${ApiEndpoints.defaultBaseUrl}/uploads/members/$filename';
      }
    }

    return 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=400';
  }

  factory UserModel.fromJson(Map<String, dynamic> json, {String? defaultRole}) {
    final roleVal = json['role']?.toString() ?? defaultRole ?? 'member';

    return UserModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      username: json['username']?.toString() ?? '',
      role: roleVal,
      namaMember: json['nama_member']?.toString(),
      instansi: json['instansi']?.toString(),
      alamat: json['alamat']?.toString(),
      telp: json['telp']?.toString(),
      foto: json['foto']?.toString(),
      fotoUrl: json['foto_url']?.toString(),
      namaCoworking: json['nama_coworking']?.toString(),
      namaPemilik: json['nama_pemilik']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'role': role,
      'nama_member': namaMember,
      'instansi': instansi,
      'alamat': alamat,
      'telp': telp,
      'foto': foto,
      'foto_url': fotoUrl,
      'nama_coworking': namaCoworking,
      'nama_pemilik': namaPemilik,
    };
  }
}

class AuthResponseData {
  final String token;
  final String role;
  final UserModel user;

  AuthResponseData({
    required this.token,
    required this.role,
    required this.user,
  });

  factory AuthResponseData.fromJson(Map<String, dynamic> json) {
    final role = json['role']?.toString() ?? 'member';
    final userJson = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : (json['member'] is Map<String, dynamic>
            ? json['member'] as Map<String, dynamic>
            : (json['space_owner'] is Map<String, dynamic>
                ? json['space_owner'] as Map<String, dynamic>
                : json));

    final tokenVal = json['access_token']?.toString() ?? json['token']?.toString() ?? '';

    return AuthResponseData(
      token: tokenVal,
      role: role,
      user: UserModel.fromJson(userJson, defaultRole: role),
    );
  }
}
