import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static const List<String> _namaHari = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  static const List<String> _namaBulan = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static const List<String> _namaBulanSingkat = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  static String rupiah(dynamic amount) {
    if (amount == null) return 'Rp 0';
    final num numAmount = amount is num ? amount : (num.tryParse(amount.toString()) ?? 0);
    return _currencyFormat.format(numAmount);
  }

  /// Helper untuk mem-parsing berbagai format tanggal dari backend maupun UI secara aman
  static DateTime? parseDate(dynamic dateValue) {
    if (dateValue == null) return null;
    if (dateValue is DateTime) return dateValue;
    final str = dateValue.toString().trim();
    if (str.isEmpty || str == '-' || str == 'null') return null;

    // 1. Coba standard ISO-8601 (yyyy-MM-dd, yyyy-MM-ddTHH:mm:ss)
    final iso = DateTime.tryParse(str);
    if (iso != null) return iso;

    // 2. Coba format DD-MM-YYYY atau DD/MM/YYYY atau YYYY/MM/DD
    if (str.contains('-') || str.contains('/')) {
      final delimiter = str.contains('-') ? '-' : '/';
      final parts = str.split(delimiter);
      if (parts.length == 3) {
        if (parts[0].length == 4) {
          final y = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          final d = int.tryParse(parts[2].split(' ')[0]);
          if (y != null && m != null && d != null) {
            return DateTime(y, m, d);
          }
        } else if (parts[2].length >= 4) {
          final d = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          final y = int.tryParse(parts[2].split(' ')[0]);
          if (y != null && m != null && d != null) {
            return DateTime(y, m, d);
          }
        }
      }
    }
    return null;
  }

  /// Format Tanggal Standar Bahasa Indonesia yang Rapi & Indah: "19 September 2026"
  static String date(dynamic dateValue) {
    final dt = parseDate(dateValue);
    if (dt == null) return dateValue?.toString() ?? '-';
    final hari = dt.day;
    final bulan = _namaBulan[(dt.month - 1).clamp(0, 11)];
    final tahun = dt.year;
    return '$hari $bulan $tahun';
  }

  /// Format Tanggal Lengkap Beserta Hari: "Sabtu, 19 September 2026"
  static String dateWithDay(dynamic dateValue) {
    final dt = parseDate(dateValue);
    if (dt == null) return dateValue?.toString() ?? '-';
    final namaHari = _namaHari[(dt.weekday - 1).clamp(0, 6)];
    final hari = dt.day;
    final bulan = _namaBulan[(dt.month - 1).clamp(0, 11)];
    final tahun = dt.year;
    return '$namaHari, $hari $bulan $tahun';
  }

  /// Format Tanggal Ringkas: "19 Sep 2026"
  static String dateShort(dynamic dateValue) {
    final dt = parseDate(dateValue);
    if (dt == null) return dateValue?.toString() ?? '-';
    final hari = dt.day;
    final bulan = _namaBulanSingkat[(dt.month - 1).clamp(0, 11)];
    final tahun = dt.year;
    return '$hari $bulan $tahun';
  }

  /// Format Tanggal Ringkas Beserta Hari Singkat: "Sab, 19 Sep 2026"
  static String dateShortWithDay(dynamic dateValue) {
    final dt = parseDate(dateValue);
    if (dt == null) return dateValue?.toString() ?? '-';
    final namaHari = _namaHari[(dt.weekday - 1).clamp(0, 6)].substring(0, 3);
    final hari = dt.day;
    final bulan = _namaBulanSingkat[(dt.month - 1).clamp(0, 11)];
    final tahun = dt.year;
    return '$namaHari, $hari $bulan $tahun';
  }

  /// Format Bulan & Tahun: "September 2026"
  static String monthYear(int month, int year) {
    final bulan = _namaBulan[(month - 1).clamp(0, 11)];
    return '$bulan $year';
  }

  /// Format untuk parameter API backend: "2026-09-19"
  static String dateApi(DateTime dt) {
    return DateFormat('yyyy-MM-dd').format(dt);
  }

  static String time(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '-';
    // e.g. 09:00:00 -> 09:00 WIB
    final parts = timeStr.split(':');
    if (parts.length >= 2) {
      return '${parts[0]}:${parts[1]} WIB';
    }
    return '$timeStr WIB';
  }

  static String timeOnly(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '09:00';
    final parts = timeStr.split(':');
    if (parts.length >= 2) {
      return '${parts[0]}:${parts[1]}';
    }
    return timeStr;
  }
}
