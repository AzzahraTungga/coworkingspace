import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primaryNavy = Color(0xFF0F2C41);
  static const Color navyDark = Color(0xFF091B28);
  static const Color navyLight = Color(0xFF1E3E59);
  static const Color primaryYellow = Color(0xFFE59B24);
  static const Color yellowLight = Color(0xFFFFF3D6);
  static const Color yellowPale = Color(0xFFFFF8ED);

  // Neutral Colors
  static const Color bgLight = Color(0xFFFAF8F5);
  static const Color cardBg = Colors.white;
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);

  // Status & Feedback Colors
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFECFDF5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEF2F2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFEFF6FF);

  // Reservation Status Mapping
  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'belum_dikonfirm':
      case 'pending':
        return warning;
      case 'disetujui':
      case 'approved':
        return info;
      case 'aktif':
      case 'active':
        return success;
      case 'selesai':
      case 'completed':
        return const Color(0xFF8B5CF6); // Purple
      case 'dibatalkan':
      case 'cancelled':
        return error;
      default:
        return textSecondary;
    }
  }

  static Color statusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'belum_dikonfirm':
      case 'pending':
        return warningLight;
      case 'disetujui':
      case 'approved':
        return infoLight;
      case 'aktif':
      case 'active':
        return successLight;
      case 'selesai':
      case 'completed':
        return const Color(0xFFF3E8FF);
      case 'dibatalkan':
      case 'cancelled':
        return errorLight;
      default:
        return divider;
    }
  }

  static String statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'belum_dikonfirm':
        return 'Belum Dikonfirmasi';
      case 'disetujui':
        return 'Disetujui';
      case 'aktif':
        return 'Sedang Aktif';
      case 'selesai':
        return 'Selesai';
      case 'dibatalkan':
        return 'Dibatalkan';
      default:
        return status;
    }
  }
}
