import '../../core/constants/api_endpoints.dart';

class SpaceModel {
  final int id;
  final String namaSpace;
  final double hargaPerJam;
  final String tipe; // 'desk', 'meeting_room', 'private_office'
  final int kapasitas;
  final String deskripsi;
  final String? foto;
  final String? fotoUrl;
  final List<String> fasilitas;
  final bool isAvailable;

  SpaceModel({
    required this.id,
    required this.namaSpace,
    required this.hargaPerJam,
    required this.tipe,
    required this.kapasitas,
    required this.deskripsi,
    this.foto,
    this.fotoUrl,
    this.fasilitas = const [],
    this.isAvailable = true,
  });

  String get displayImageUrl {
    final raw = (foto != null && foto!.trim().isNotEmpty && foto != 'null')
        ? foto!.trim()
        : ((fotoUrl != null && fotoUrl!.trim().isNotEmpty && fotoUrl != 'null')
            ? fotoUrl!.trim()
            : null);

    if (raw != null && raw.isNotEmpty) {
      // 1. Jika URL eksternal selain server backend kita (misal Unsplash)
      if ((raw.startsWith('http://') || raw.startsWith('https://')) &&
          !raw.contains('learn.smktelkom-mlg.sch.id')) {
        return raw;
      }

      // 2. Ekstrak nama file bersih jika berupa URL atau path
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
        // Gunakan URL absolut yang valid dengan sub-path /coworking
        return '${ApiEndpoints.defaultBaseUrl}/uploads/spaces/$filename';
      }
    }

    switch (tipe.toLowerCase()) {
      case 'desk':
        return 'https://images.unsplash.com/photo-1527192491265-7e15c55b1ed2?q=80&w=800';
      case 'meeting_room':
        return 'https://images.unsplash.com/photo-1497366216548-37526070297c?q=80&w=800';
      case 'private_office':
        return 'https://images.unsplash.com/photo-1497215728101-856f4ea42174?q=80&w=800';
      default:
        return 'https://images.unsplash.com/photo-1497366216548-37526070297c?q=80&w=800';
    }
  }

  String get tipeFormatted {
    switch (tipe.toLowerCase()) {
      case 'desk':
        return 'Personal Desk';
      case 'meeting_room':
        return 'Meeting Room';
      case 'private_office':
        return 'Private Office';
      default:
        return tipe;
    }
  }

  String get title => namaSpace;

  factory SpaceModel.fromJson(Map<String, dynamic> raw) {
    // Un-wrap jika backend membungkus di dalam key 'space' atau 'data'
    Map<String, dynamic> json = raw;
    if (raw.containsKey('space') && raw['space'] is Map<String, dynamic>) {
      json = raw['space'] as Map<String, dynamic>;
    } else if (raw.containsKey('data') && raw['data'] is Map<String, dynamic>) {
      json = raw['data'] as Map<String, dynamic>;
    }

    // Parse fasilitas jika string comma-separated atau list
    List<String> fasilitasList = [];
    if (json['fasilitas'] is List) {
      fasilitasList = (json['fasilitas'] as List).map((e) => e.toString()).toList();
    } else if (json['fasilitas'] is String) {
      fasilitasList = (json['fasilitas'] as String)
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } else {
      // Default fasilitas berdasarkan tipe jika API belum menyertakan
      if (json['tipe'] == 'desk') {
        fasilitasList = ['High-Speed Wi-Fi', 'Stopkontak', 'Kursi Ergonomis', 'Free Flow Kopi/Teh'];
      } else if (json['tipe'] == 'meeting_room') {
        fasilitasList = ['Smart TV / Proyektor', 'Glass Whiteboard', 'AC Ruangan', 'Sound System', 'Kopi & Teh'];
      } else if (json['tipe'] == 'private_office') {
        fasilitasList = ['Akses Kunci Privat', 'Kapasitas Eksklusif', 'Dedicated LAN & Wi-Fi', 'Pantry & Lounge'];
      }
    }

    final rawHarga = json['harga_per_jam'] ?? json['harga'] ?? json['price'] ?? json['harga_jam'] ?? json['tarif'];
    double parsedHarga = 0.0;
    if (rawHarga is num) {
      parsedHarga = rawHarga.toDouble();
    } else if (rawHarga != null) {
      parsedHarga = double.tryParse(rawHarga.toString()) ?? 0.0;
    }

    final parsedTipe = json['tipe']?.toString() ?? json['tipe_space']?.toString() ?? 'desk';

    // Fallback harga default jika dari API bernilai 0
    if (parsedHarga <= 0) {
      final t = parsedTipe.toLowerCase();
      if (t == 'meeting_room') {
        parsedHarga = 75000.0;
      } else if (t == 'private_office') {
        parsedHarga = 150000.0;
      } else {
        parsedHarga = 25000.0;
      }
    }

    // Prioritaskan title sesuai data dari api backend
    String parsedNama = (json['title']?.toString() ??
        json['space_title']?.toString() ??
        json['nama_space']?.toString() ??
        json['space_name']?.toString() ??
        json['judul']?.toString() ??
        json['judul_space']?.toString() ??
        json['nama']?.toString() ??
        json['nama_ruangan']?.toString() ??
        json['name']?.toString() ??
        '').trim();

    // Jika kosong atau generic (misal 'Space #123'), beri nama default representatif
    final isGeneric = parsedNama.isEmpty ||
        parsedNama.toLowerCase().startsWith('space #') ||
        parsedNama.toLowerCase().startsWith('space#') ||
        RegExp(r'^space\s*#?\s*\d+$', caseSensitive: false).hasMatch(parsedNama) ||
        RegExp(r'^#\d+$').hasMatch(parsedNama);

    if (isGeneric) {
      final t = parsedTipe.toLowerCase();
      if (t.contains('meeting')) {
        parsedNama = 'Meeting Room';
      } else if (t.contains('office')) {
        parsedNama = 'Private Office';
      } else {
        parsedNama = 'Personal Desk';
      }
    }

    final parsedFoto = json['foto']?.toString() ??
        json['foto_space']?.toString() ??
        json['image']?.toString() ??
        json['gambar']?.toString();

    final parsedFotoUrl = json['foto_url']?.toString() ??
        json['image_url']?.toString() ??
        json['url_foto']?.toString();

    final parsedKapasitas = json['kapasitas'] is int
        ? json['kapasitas'] as int
        : (int.tryParse(json['kapasitas']?.toString() ?? '') ??
            (int.tryParse(json['capacity']?.toString() ?? '1') ?? 1));

    return SpaceModel(
      id: json['id'] is int ? json['id'] : (int.tryParse(json['id']?.toString() ?? '0') ?? 0),
      namaSpace: parsedNama,
      hargaPerJam: parsedHarga,
      tipe: parsedTipe,
      kapasitas: parsedKapasitas,
      deskripsi: json['deskripsi']?.toString() ?? json['description']?.toString() ?? '',
      foto: parsedFoto,
      fotoUrl: parsedFotoUrl,
      fasilitas: fasilitasList,
      isAvailable: json['is_available'] is bool ? json['is_available'] : true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nama_space': namaSpace,
      'harga_per_jam': hargaPerJam.round(),
      'tipe': tipe,
      'kapasitas': kapasitas,
      'deskripsi': deskripsi,
      if (foto != null && foto!.isNotEmpty) 'foto': foto,
      if (fotoUrl != null && fotoUrl!.isNotEmpty) 'foto_url': fotoUrl,
    };
  }
}
