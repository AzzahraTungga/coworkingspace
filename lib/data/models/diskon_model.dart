class DiskonModel {
  final int id;
  final String namaDiskon;
  final double persentaseDiskon;
  final String? tanggalAwal;
  final String? tanggalAkhir;
  final bool isActive;

  DiskonModel({
    required this.id,
    required this.namaDiskon,
    required this.persentaseDiskon,
    this.tanggalAwal,
    this.tanggalAkhir,
    this.isActive = true,
  });

  factory DiskonModel.fromJson(Map<String, dynamic> json) {
    final map = (json['diskon'] is Map<String, dynamic>)
        ? json['diskon'] as Map<String, dynamic>
        : json;

    final rawId = map['id'] ?? map['id_diskon'] ?? 0;
    final rawName = map['nama_diskon'] ??
        map['kode_diskon'] ??
        map['kode_promo'] ??
        map['kode'] ??
        '';
    final rawPercent = map['persentase_diskon'] ??
        map['persentase'] ??
        map['persen'] ??
        map['diskon'] ??
        map['potongan'] ??
        map['nilai'] ??
        0;
    final rawActive = map['is_active'] ?? map['active'] ?? map['status'];

    final parsedId = rawId is int ? rawId : (int.tryParse(rawId.toString()) ?? 0);
    final parsedPercent = rawPercent is num
        ? rawPercent.toDouble()
        : (double.tryParse(rawPercent.toString()) ?? 0.0);

    bool parsedActive = true;
    if (rawActive is bool) {
      parsedActive = rawActive;
    } else if (rawActive != null) {
      final s = rawActive.toString().toLowerCase();
      parsedActive = s == '1' || s == 'true' || s == 'aktif' || s == 'active';
    }

    return DiskonModel(
      id: parsedId,
      namaDiskon: rawName.toString(),
      persentaseDiskon: parsedPercent,
      tanggalAwal: map['tanggal_awal']?.toString(),
      tanggalAkhir: map['tanggal_akhir']?.toString(),
      isActive: parsedActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nama_diskon': namaDiskon,
      'persentase_diskon': persentaseDiskon,
      if (tanggalAwal != null) 'tanggal_awal': tanggalAwal,
      if (tanggalAkhir != null) 'tanggal_akhir': tanggalAkhir,
    };
  }
}
