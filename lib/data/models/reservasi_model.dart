import 'space_model.dart';
import 'user_model.dart';
import 'diskon_model.dart';

class ReservasiModel {
  final int id;
  final int idMember;
  final int idSpace;
  final String tanggalReservasi;
  final String jamMulai;
  final int durasiJam;
  final String? jamSelesai;
  final double totalBayar;
  final String status;
  final String? kodeReservasi;
  final String? checkInTime;
  final String? checkOutTime;
  final SpaceModel? space;
  final UserModel? member;
  final DiskonModel? diskon;
  final int? idDiskon;
  final String? kodePromo;
  final String? title;

  ReservasiModel({
    required this.id,
    required this.idMember,
    required this.idSpace,
    required this.tanggalReservasi,
    required this.jamMulai,
    required this.durasiJam,
    this.jamSelesai,
    required this.totalBayar,
    required this.status,
    this.kodeReservasi,
    this.checkInTime,
    this.checkOutTime,
    this.space,
    this.member,
    this.diskon,
    this.idDiskon,
    this.kodePromo,
    this.title,
  });

  // Pemeriksaan apakah sebuah judul berupa generic fallback id seperti 'Space #212', '#212', dll
  static bool isGenericTitle(String? s) {
    if (s == null) return true;
    final clean = s.trim().toLowerCase();
    if (clean.isEmpty) return true;
    if (clean.startsWith('space #') ||
        clean.startsWith('space#') ||
        clean.startsWith('space_#') ||
        clean.startsWith('space - #') ||
        RegExp(r'^space\s*#?\s*\d+$').hasMatch(clean) ||
        RegExp(r'^#\d+$').hasMatch(clean)) {
      return true;
    }
    return false;
  }

  // Cerdas mendeduksi nama space dari tipe atau rasio tarif per jam
  String deduceSpaceName() {
    if (space != null && space!.tipe.isNotEmpty) {
      return space!.tipeFormatted;
    }
    final durasi = durasiJam > 0 ? durasiJam : 1;
    final rate = totalBayar > 0 ? (totalBayar / durasi) : 0.0;
    if (rate >= 120000) {
      return 'Private Office';
    } else if (rate >= 50000) {
      return 'Meeting Room';
    } else {
      return 'Personal Desk';
    }
  }

  // Helper display untuk judul space yang tepat sesuai data dari api backend
  String get displayTitle {
    if (title != null && title!.trim().isNotEmpty && !isGenericTitle(title!)) {
      return title!.trim();
    }
    if (space != null && space!.namaSpace.trim().isNotEmpty && !isGenericTitle(space!.namaSpace)) {
      return space!.namaSpace.trim();
    }
    if (space != null && space!.tipeFormatted.isNotEmpty) {
      return space!.tipeFormatted;
    }
    return deduceSpaceName();
  }

  // Alias untuk kompatibilitas displayNamaSpace
  String get displayNamaSpace => displayTitle;

  // Helper display untuk tipe space
  String get displayTipeSpace {
    if (space != null && space!.tipe.isNotEmpty) {
      return space!.tipeFormatted;
    }
    final durasi = durasiJam > 0 ? durasiJam : 1;
    final rate = totalBayar > 0 ? (totalBayar / durasi) : 0.0;
    if (rate >= 120000) {
      return 'Private Office';
    } else if (rate >= 50000) {
      return 'Meeting Room';
    }
    return 'Personal Desk';
  }

  // Helper display untuk foto space
  String get displayFotoSpace {
    if (space != null && space!.displayImageUrl.isNotEmpty) {
      return space!.displayImageUrl;
    }
    final t = displayTipeSpace.toLowerCase();
    if (t.contains('meeting')) {
      return 'https://images.unsplash.com/photo-1497366216548-37526070297c?q=80&w=800';
    } else if (t.contains('office')) {
      return 'https://images.unsplash.com/photo-1497215728101-856f4ea42174?q=80&w=800';
    }
    return 'https://images.unsplash.com/photo-1527192491265-7e15c55b1ed2?q=80&w=800';
  }

  // Kalkulasi Subtotal (Biaya Sewa Bersih: Tarif x Jam)
  double get calculatedSubtotal {
    final rate = (space?.hargaPerJam != null && space!.hargaPerJam > 0)
        ? space!.hargaPerJam
        : (space?.tipe.toLowerCase().contains('meeting') == true
            ? 75000.0
            : (space?.tipe.toLowerCase().contains('office') == true ? 150000.0 : 25000.0));
    final durasi = durasiJam > 0 ? durasiJam : 1;
    return rate * durasi;
  }

  // Kalkulasi Potongan Diskon
  double get calculatedDiscount {
    final sub = calculatedSubtotal;
    if (totalBayar > 0 && totalBayar < sub) {
      return sub - totalBayar;
    }
    if (diskon != null && diskon!.persentaseDiskon > 0) {
      final p = diskon!.persentaseDiskon;
      if (p > 0 && p <= 1) return sub * p;
      if (p > 1 && p <= 100) return sub * (p / 100.0);
      if (p > 100) return p;
    }
    return 0.0;
  }

  // Kalkulasi Total Pembayaran Final yang Sebenarnya
  double get calculatedTotalBayar {
    if (totalBayar > 0) {
      // Jika ada diskon tetapi backend mengembalikan harga subtotal kotor
      if (diskon != null && diskon!.persentaseDiskon > 0 && totalBayar >= calculatedSubtotal) {
        final disc = calculatedDiscount;
        if (disc > 0) {
          final res = calculatedSubtotal - disc;
          return res > 0 ? res : totalBayar;
        }
      }
      return totalBayar;
    }
    final sub = calculatedSubtotal;
    final disc = calculatedDiscount;
    final res = sub - disc;
    return res > 0 ? res : sub;
  }

  factory ReservasiModel.fromJson(Map<String, dynamic> raw) {
    // Un-wrap jika backend membungkus di dalam key 'reservasi' atau 'data'
    Map<String, dynamic> json = raw;
    if (raw.containsKey('reservasi') && raw['reservasi'] is Map<String, dynamic>) {
      json = raw['reservasi'] as Map<String, dynamic>;
    } else if (raw.containsKey('data') && raw['data'] is Map<String, dynamic>) {
      json = raw['data'] as Map<String, dynamic>;
    }

    final id = json['id'] is int
        ? json['id'] as int
        : (int.tryParse(json['id']?.toString() ?? '') ??
            (int.tryParse(json['id_reservasi']?.toString() ?? '') ??
                (int.tryParse(json['reservasi_id']?.toString() ?? '0') ?? 0)));

    final idMember = json['id_member'] is int
        ? json['id_member'] as int
        : (int.tryParse(json['id_member']?.toString() ?? '') ??
            (int.tryParse(json['member_id']?.toString() ?? '') ??
                (int.tryParse(json['id_user']?.toString() ?? '') ??
                    (int.tryParse(json['user_id']?.toString() ?? '0') ?? 0))));

    final idSpace = json['id_space'] is int
        ? json['id_space'] as int
        : (int.tryParse(json['id_space']?.toString() ?? '') ??
            (int.tryParse(json['space_id']?.toString() ?? '') ??
                (int.tryParse(json['id_ruangan']?.toString() ?? '') ??
                    (json['space'] is Map ? (int.tryParse(json['space']['id']?.toString() ?? '0') ?? 0) : 0))));

    final tanggal = json['tanggal_reservasi']?.toString() ??
        json['tanggal']?.toString() ??
        json['tgl_reservasi']?.toString() ??
        json['date']?.toString() ??
        json['booking_date']?.toString() ??
        '';

    final jamMulai = json['jam_mulai']?.toString() ??
        json['jam']?.toString() ??
        json['waktu_mulai']?.toString() ??
        json['start_time']?.toString() ??
        json['jam_booking']?.toString() ??
        '';

    final durasi = json['durasi_jam'] is int
        ? json['durasi_jam'] as int
        : (int.tryParse(json['durasi_jam']?.toString() ?? '') ??
            (int.tryParse(json['durasi']?.toString() ?? '') ??
                (int.tryParse(json['duration']?.toString() ?? '1') ?? 1)));

    // 1. Parsing space object jika disediakan backend
    SpaceModel? spaceObj;
    if (json['space'] != null && json['space'] is Map<String, dynamic>) {
      spaceObj = SpaceModel.fromJson(json['space'] as Map<String, dynamic>);
    } else if (json['space_detail'] != null && json['space_detail'] is Map<String, dynamic>) {
      spaceObj = SpaceModel.fromJson(json['space_detail'] as Map<String, dynamic>);
    } else if (json['ruangan'] != null && json['ruangan'] is Map<String, dynamic>) {
      spaceObj = SpaceModel.fromJson(json['ruangan'] as Map<String, dynamic>);
    }

    // 2. Ekstrak title & nama space secara komprehensif dari API backend (prioritas 'title')
    final rawTitle = json['title']?.toString() ??
        json['space_title']?.toString() ??
        json['nama_space']?.toString() ??
        json['space_name']?.toString() ??
        json['judul']?.toString() ??
        json['judul_space']?.toString() ??
        json['nama_ruangan']?.toString() ??
        json['room_name']?.toString() ??
        json['nama']?.toString() ??
        json['name']?.toString() ??
        (json['space'] is Map
            ? (json['space']['title'] ??
                    json['space']['space_title'] ??
                    json['space']['nama_space'] ??
                    json['space']['space_name'] ??
                    json['space']['judul'] ??
                    json['space']['name'] ??
                    json['space']['nama'])
                ?.toString()
            : null) ??
        (json['space'] is String && (json['space'] as String).trim().isNotEmpty ? json['space'] as String : null);

    final parsedTitle = (rawTitle != null && !isGenericTitle(rawTitle)) ? rawTitle.trim() : null;
    final flatNamaSpace = parsedTitle;

    final flatTipeSpace = json['tipe_space']?.toString() ??
        json['tipe']?.toString() ??
        json['type']?.toString() ??
        json['space_type']?.toString();

    final flatFoto = json['foto_space']?.toString() ??
        json['foto']?.toString() ??
        json['image']?.toString() ??
        json['gambar']?.toString();

    final flatFotoUrl = json['foto_url']?.toString() ??
        json['image_url']?.toString() ??
        json['url_foto']?.toString();

    final flatKapasitas = json['kapasitas'] is int
        ? json['kapasitas'] as int
        : int.tryParse(json['kapasitas']?.toString() ?? '');

    final flatHarga = json['harga_per_jam'] ??
        json['harga_space'] ??
        json['harga'] ??
        json['tarif'] ??
        json['rate'];

    double? parsedFlatHarga;
    if (flatHarga is num) {
      parsedFlatHarga = flatHarga.toDouble();
    } else if (flatHarga != null) {
      parsedFlatHarga = double.tryParse(flatHarga.toString());
    }

    if (spaceObj != null) {
      // Jika spaceObj ada tapi nama atau fotonya belum ada / generic, lengkapi dari flat fields
      String nama = spaceObj.namaSpace.trim();
      if (nama.isEmpty || isGenericTitle(nama)) {
        nama = (flatNamaSpace != null && !isGenericTitle(flatNamaSpace)) ? flatNamaSpace.trim() : '';
      }
      final foto = (spaceObj.foto != null && spaceObj.foto!.isNotEmpty) ? spaceObj.foto : flatFoto;
      final fotoUrl = (spaceObj.fotoUrl != null && spaceObj.fotoUrl!.isNotEmpty) ? spaceObj.fotoUrl : flatFotoUrl;
      final tipe = spaceObj.tipe.isNotEmpty ? spaceObj.tipe : (flatTipeSpace ?? 'desk');
      final harga = spaceObj.hargaPerJam > 0 ? spaceObj.hargaPerJam : (parsedFlatHarga ?? 25000.0);
      final kapasitas = spaceObj.kapasitas > 0 ? spaceObj.kapasitas : (flatKapasitas ?? 1);

      if (nama.isEmpty || isGenericTitle(nama)) {
        final t = tipe.toLowerCase();
        if (t.contains('meeting')) {
          nama = 'Meeting Room';
        } else if (t.contains('office')) {
          nama = 'Private Office';
        } else {
          nama = 'Personal Desk';
        }
      }

      spaceObj = SpaceModel(
        id: spaceObj.id > 0 ? spaceObj.id : idSpace,
        namaSpace: nama,
        hargaPerJam: harga,
        tipe: tipe,
        kapasitas: kapasitas,
        deskripsi: spaceObj.deskripsi.isNotEmpty ? spaceObj.deskripsi : (json['deskripsi']?.toString() ?? ''),
        foto: foto,
        fotoUrl: fotoUrl,
        fasilitas: spaceObj.fasilitas,
        isAvailable: spaceObj.isAvailable,
      );
    } else if (flatNamaSpace != null && flatNamaSpace.trim().isNotEmpty && !isGenericTitle(flatNamaSpace)) {
      // Buat SpaceModel langsung dari flat fields hasil SQL join
      spaceObj = SpaceModel(
        id: idSpace,
        namaSpace: flatNamaSpace.trim(),
        hargaPerJam: parsedFlatHarga ??
            (flatTipeSpace?.toLowerCase().contains('meeting') == true
                ? 75000.0
                : (flatTipeSpace?.toLowerCase().contains('office') == true ? 150000.0 : 25000.0)),
        tipe: flatTipeSpace ?? 'desk',
        kapasitas: flatKapasitas ?? 1,
        deskripsi: json['deskripsi']?.toString() ?? json['description']?.toString() ?? '',
        foto: flatFoto,
        fotoUrl: flatFotoUrl,
      );
    }

    final memberObj = json['member'] != null && json['member'] is Map<String, dynamic>
        ? UserModel.fromJson(json['member'] as Map<String, dynamic>, defaultRole: 'member')
        : (json['nama_member'] != null || json['username'] != null
            ? UserModel(
                id: idMember,
                username: json['username']?.toString() ?? json['nama_member']?.toString() ?? 'member',
                role: 'member',
                namaMember: json['nama_member']?.toString() ?? json['nama']?.toString(),
                instansi: json['instansi']?.toString(),
                telp: json['telp']?.toString() ?? json['telepon']?.toString() ?? json['no_telp']?.toString(),
              )
            : null);

    final diskonObj = json['diskon'] != null && json['diskon'] is Map<String, dynamic>
        ? DiskonModel.fromJson(json['diskon'] as Map<String, dynamic>)
        : null;

    final idDiskon = json['id_diskon'] is int
        ? json['id_diskon'] as int
        : (int.tryParse(json['id_diskon']?.toString() ?? '') ??
            (int.tryParse(json['diskon_id']?.toString() ?? '') ??
                (json['diskon'] is Map ? (int.tryParse(json['diskon']['id']?.toString() ?? '') ?? 0) : null)));

    final kodePromo = json['kode_promo']?.toString() ??
        json['promo_code']?.toString() ??
        json['diskon_kode']?.toString() ??
        (json['diskon'] is Map ? json['diskon']['nama_diskon']?.toString() : null);

    // Parsing total_bayar dengan berbagai variasi penamaan dari backend
    final rawTotal = json['total_bayar'] ??
        json['total_harga'] ??
        json['total'] ??
        json['harga_total'] ??
        json['harga'] ??
        json['amount'] ??
        json['grand_total'] ??
        json['biaya'] ??
        (json['payment'] is Map ? (json['payment']['total_bayar'] ?? json['payment']['amount'] ?? json['payment']['total']) : null) ??
        (json['pembayaran'] is Map ? (json['pembayaran']['total_bayar'] ?? json['pembayaran']['nominal']) : null);

    double total = 0.0;
    if (rawTotal is num) {
      total = rawTotal.toDouble();
    } else if (rawTotal != null) {
      total = double.tryParse(rawTotal.toString()) ?? 0.0;
    }

    // Fallback cerdas: Jika total 0, hitung otomatis dari durasi & harga space
    if (total <= 0.0) {
      double rate = spaceObj?.hargaPerJam ?? 0.0;
      if (rate <= 0.0) {
        final t = (flatTipeSpace ?? json['tipe'] ?? json['tipe_space'] ?? '').toString().toLowerCase();
        if (t.contains('meeting')) {
          rate = 75000.0;
        } else if (t.contains('office')) {
          rate = 150000.0;
        } else {
          rate = 25000.0;
        }
      }

      final subtotal = rate * (durasi > 0 ? durasi : 1);
      double potongan = 0.0;
      if (diskonObj != null) {
        final p = diskonObj.persentaseDiskon;
        if (p > 0 && p <= 1) {
          potongan = subtotal * p;
        } else if (p > 1 && p <= 100) {
          potongan = subtotal * (p / 100.0);
        } else if (p > 100) {
          potongan = p > subtotal ? subtotal : p;
        }
      }
      final computed = subtotal - potongan;
      total = computed > 0 ? computed : subtotal;
    }

    final kodeReservasi = json['kode_reservasi']?.toString() ??
        json['kode']?.toString() ??
        json['code']?.toString() ??
        json['booking_code']?.toString() ??
        json['no_reservasi']?.toString() ??
        json['nomor_reservasi']?.toString();

    return ReservasiModel(
      id: id,
      idMember: idMember,
      idSpace: idSpace,
      tanggalReservasi: tanggal,
      jamMulai: jamMulai,
      durasiJam: durasi,
      jamSelesai: json['jam_selesai']?.toString() ?? json['waktu_selesai']?.toString() ?? json['end_time']?.toString(),
      totalBayar: total,
      status: json['status']?.toString() ?? json['status_reservasi']?.toString() ?? 'belum_dikonfirm',
      kodeReservasi: kodeReservasi,
      checkInTime: json['check_in_time']?.toString() ?? json['check_in']?.toString(),
      checkOutTime: json['check_out_time']?.toString() ?? json['check_out']?.toString(),
      space: spaceObj,
      member: memberObj,
      diskon: diskonObj,
      idDiskon: idDiskon,
      kodePromo: kodePromo,
      title: parsedTitle,
    );
  }

  ReservasiModel copyWith({
    int? id,
    int? idMember,
    int? idSpace,
    String? tanggalReservasi,
    String? jamMulai,
    int? durasiJam,
    String? jamSelesai,
    double? totalBayar,
    String? status,
    String? kodeReservasi,
    String? checkInTime,
    String? checkOutTime,
    SpaceModel? space,
    UserModel? member,
    DiskonModel? diskon,
    int? idDiskon,
    String? kodePromo,
    String? title,
  }) {
    return ReservasiModel(
      id: id ?? this.id,
      idMember: idMember ?? this.idMember,
      idSpace: idSpace ?? this.idSpace,
      tanggalReservasi: tanggalReservasi ?? this.tanggalReservasi,
      jamMulai: jamMulai ?? this.jamMulai,
      durasiJam: durasiJam ?? this.durasiJam,
      jamSelesai: jamSelesai ?? this.jamSelesai,
      totalBayar: totalBayar ?? this.totalBayar,
      status: status ?? this.status,
      kodeReservasi: kodeReservasi ?? this.kodeReservasi,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      space: space ?? this.space,
      member: member ?? this.member,
      diskon: diskon ?? this.diskon,
      idDiskon: idDiskon ?? this.idDiskon,
      kodePromo: kodePromo ?? this.kodePromo,
      title: title ?? this.title,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_member': idMember,
      'id_space': idSpace,
      'tanggal_reservasi': tanggalReservasi,
      'jam_mulai': jamMulai,
      'durasi_jam': durasiJam,
      'total_bayar': totalBayar,
      'status': status,
      if (title != null) 'title': title,
      if (kodeReservasi != null) 'kode_reservasi': kodeReservasi,
      if (idDiskon != null) 'id_diskon': idDiskon,
      if (kodePromo != null) 'kode_promo': kodePromo,
    };
  }
}

class CreateReservasiDto {
  final int idSpace;
  final String tanggalReservasi;
  final String jamMulai;
  final int durasiJam;
  final double? totalBayar;
  final int? idDiskon;
  final String? kodePromo;

  CreateReservasiDto({
    required this.idSpace,
    required this.tanggalReservasi,
    required this.jamMulai,
    required this.durasiJam,
    this.totalBayar,
    this.idDiskon,
    this.kodePromo,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id_space': idSpace,
      'tanggal_reservasi': tanggalReservasi,
      'jam_mulai': jamMulai,
      'durasi_jam': durasiJam,
    };
    if (totalBayar != null && totalBayar! > 0) {
      map['total_bayar'] = totalBayar!.round();
      map['total_harga'] = totalBayar!.round();
      map['total'] = totalBayar!.round();
    }
    if (idDiskon != null && idDiskon! > 0) map['id_diskon'] = idDiskon;
    if (kodePromo != null && kodePromo!.isNotEmpty) map['kode_promo'] = kodePromo;
    return map;
  }
}
