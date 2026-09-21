class ReportBreakdownModel {
  final String tipe;
  final int totalReservasi;
  final double totalPendapatan;

  ReportBreakdownModel({
    required this.tipe,
    required this.totalReservasi,
    required this.totalPendapatan,
  });

  String get tipeFormatted {
    final lower = tipe.toLowerCase();
    if (lower.contains('meeting')) {
      return 'Meeting Room';
    } else if (lower.contains('office')) {
      return 'Private Office';
    } else {
      return 'Personal Desk';
    }
  }

  factory ReportBreakdownModel.fromJson(Map<String, dynamic> json) {
    final rawType = json['tipe'] ?? json['type'] ?? json['nama_tipe'] ?? json['tipe_space'] ?? '';
    final rawCount = json['total_reservasi'] ?? json['total_booking'] ?? json['count'] ?? json['total'] ?? 0;
    final rawIncome = json['total_pendapatan'] ?? json['total_income'] ?? json['pendapatan'] ?? json['income'] ?? json['total'] ?? 0;

    return ReportBreakdownModel(
      tipe: rawType.toString(),
      totalReservasi: rawCount is int ? rawCount : (int.tryParse(rawCount.toString()) ?? 0),
      totalPendapatan: rawIncome is num
          ? rawIncome.toDouble()
          : (double.tryParse(rawIncome.toString()) ?? 0.0),
    );
  }
}

class MonthlyReportModel {
  final int bulan;
  final int tahun;
  final double totalPendapatan;
  final int totalReservasi;
  final List<ReportBreakdownModel> breakdown;

  MonthlyReportModel({
    required this.bulan,
    required this.tahun,
    required this.totalPendapatan,
    required this.totalReservasi,
    required this.breakdown,
  });

  MonthlyReportModel copyWith({
    int? bulan,
    int? tahun,
    double? totalPendapatan,
    int? totalReservasi,
    List<ReportBreakdownModel>? breakdown,
  }) {
    return MonthlyReportModel(
      bulan: bulan ?? this.bulan,
      tahun: tahun ?? this.tahun,
      totalPendapatan: totalPendapatan ?? this.totalPendapatan,
      totalReservasi: totalReservasi ?? this.totalReservasi,
      breakdown: breakdown ?? this.breakdown,
    );
  }

  factory MonthlyReportModel.fromJson(Map<String, dynamic> json) {
    List<ReportBreakdownModel> list = [];
    final rawBreakdown = json['breakdown_per_tipe'] ??
        json['breakdown'] ??
        json['details'] ??
        json['per_tipe'] ??
        json['spaces'];

    if (rawBreakdown is List) {
      list = rawBreakdown
          .whereType<Map<String, dynamic>>()
          .map((item) => ReportBreakdownModel.fromJson(item))
          .toList();
    }

    final rawIncome = json['total_pendapatan'] ??
        json['total_income'] ??
        json['pendapatan'] ??
        json['income'] ??
        json['total'] ??
        json['revenue'] ??
        json['total_bayar'] ??
        json['total_harga'] ??
        json['omzet'] ??
        json['omset'] ??
        (json['summary'] is Map ? (json['summary']['total_pendapatan'] ?? json['summary']['total_income'] ?? json['summary']['total']) : null);

    double income = 0.0;
    if (rawIncome is num) {
      income = rawIncome.toDouble();
    } else if (rawIncome != null) {
      income = double.tryParse(rawIncome.toString()) ?? 0.0;
    }

    final rawReservasi = json['total_reservasi'] ??
        json['total_booking'] ??
        json['total_transaksi'] ??
        json['reservasi'] ??
        json['total'] ??
        json['count'];

    int reservasiCount = 0;
    if (rawReservasi is int) {
      reservasiCount = rawReservasi;
    } else if (rawReservasi != null) {
      reservasiCount = int.tryParse(rawReservasi.toString()) ?? 0;
    }

    final rawBulan = json['bulan'] ?? json['month'] ?? DateTime.now().month;
    final rawTahun = json['tahun'] ?? json['year'] ?? DateTime.now().year;

    return MonthlyReportModel(
      bulan: rawBulan is int ? rawBulan : (int.tryParse(rawBulan.toString()) ?? DateTime.now().month),
      tahun: rawTahun is int ? rawTahun : (int.tryParse(rawTahun.toString()) ?? DateTime.now().year),
      totalPendapatan: income,
      totalReservasi: reservasiCount,
      breakdown: list,
    );
  }
}
