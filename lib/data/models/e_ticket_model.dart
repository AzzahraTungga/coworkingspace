class ETicketModel {
  final String kodeReservasi;
  final String qrCodePayload;
  final String status;
  final String namaMember;
  final String instansi;
  final String namaSpace;
  final String tipeSpace;
  final String tanggalReservasi;
  final String jamMulai;
  final int durasiJam;
  final String? jamSelesai;
  final double totalBayar;

  ETicketModel({
    required this.kodeReservasi,
    required this.qrCodePayload,
    required this.status,
    required this.namaMember,
    required this.instansi,
    required this.namaSpace,
    required this.tipeSpace,
    required this.tanggalReservasi,
    required this.jamMulai,
    required this.durasiJam,
    this.jamSelesai,
    required this.totalBayar,
  });

  factory ETicketModel.fromJson(Map<String, dynamic> json) {
    final member = json['member'] as Map<String, dynamic>?;
    final space = json['space'] as Map<String, dynamic>?;

    final rawTotal = json['total_bayar'] ??
        json['total_harga'] ??
        json['total'] ??
        json['harga_total'] ??
        json['harga'] ??
        json['amount'] ??
        (space?['harga_per_jam'] != null ? ((space!['harga_per_jam'] as num).toDouble() * (json['durasi_jam'] ?? 1)) : null);

    double totalBayar = 0.0;
    if (rawTotal is num) {
      totalBayar = rawTotal.toDouble();
    } else if (rawTotal != null) {
      totalBayar = double.tryParse(rawTotal.toString()) ?? 0.0;
    }

    final durasi = json['durasi_jam'] is int
        ? json['durasi_jam'] as int
        : (int.tryParse(json['durasi_jam']?.toString() ?? '1') ?? 1);

    if (totalBayar <= 0.0) {
      final tipe = (space?['tipe'] ?? json['tipe'] ?? '').toString().toLowerCase();
      double fallbackRate = 25000.0;
      if (tipe.contains('meeting')) {
        fallbackRate = 75000.0;
      } else if (tipe.contains('office')) {
        fallbackRate = 150000.0;
      }
      totalBayar = fallbackRate * (durasi > 0 ? durasi : 1);
    }

    final rawTipe = (space?['tipe'] ?? json['tipe_space'] ?? json['tipe'] ?? '').toString().toLowerCase();
    String tipeSpace = 'Personal Desk';
    if (rawTipe.contains('meeting')) {
      tipeSpace = 'Meeting Room';
    } else if (rawTipe.contains('office')) {
      tipeSpace = 'Private Office';
    }

    String namaSpace = (space?['title'] ??
            space?['space_title'] ??
            space?['nama_space'] ??
            space?['space_name'] ??
            space?['name'] ??
            json['title'] ??
            json['space_title'] ??
            json['nama_space'] ??
            json['space_name'] ??
            json['nama_ruangan'] ??
            '')
        .toString()
        .trim();

    final isGeneric = namaSpace.isEmpty ||
        namaSpace.toLowerCase().startsWith('space #') ||
        namaSpace.toLowerCase().startsWith('space#') ||
        RegExp(r'^space\s*#?\s*\d+$', caseSensitive: false).hasMatch(namaSpace) ||
        RegExp(r'^#\d+$').hasMatch(namaSpace);

    if (isGeneric) {
      namaSpace = tipeSpace;
    }

    return ETicketModel(
      kodeReservasi: json['kode_reservasi']?.toString() ?? '',
      qrCodePayload: json['qr_code_payload']?.toString() ?? json['kode_reservasi']?.toString() ?? '',
      status: json['status']?.toString() ?? 'disetujui',
      namaMember: member?['nama_member']?.toString() ?? json['nama_member']?.toString() ?? '',
      instansi: member?['instansi']?.toString() ?? json['instansi']?.toString() ?? '',
      namaSpace: namaSpace,
      tipeSpace: tipeSpace,
      tanggalReservasi: json['tanggal_reservasi']?.toString() ?? '',
      jamMulai: json['jam_mulai']?.toString() ?? '',
      durasiJam: durasi,
      jamSelesai: json['jam_selesai']?.toString(),
      totalBayar: totalBayar,
    );
  }
}
