class ApiEndpoints {
  // Base URL yang diberikan oleh penguji / panitia
  static const String defaultBaseUrl =
      'https://learn.smktelkom-mlg.sch.id/coworking';
  static const String defaultAppKey = 'mk_41bfa558160149fa8c39399e690ac8b5';

  // 0. Root & Health
  static const String root = '/';
  static const String health = '/health';

  // 1. App Maker (Multi-Tenancy)
  static const String makerRegister = '/api/maker/register';
  static const String makerLogin = '/api/maker/login';
  static const String makerMe = '/api/maker/me';
  static const String makerStats = '/api/maker/stats';
  static const String makerList = '/api/maker/list';

  // 2. Autentikasi User (Member & Admin Space)
  static const String registerMember = '/api/auth/register/member';
  static const String registerAdminSpace = '/api/auth/register/admin-space';
  static const String login = '/api/auth/login';
  static const String profile = '/api/auth/profile';

  // 3. Space Coworking
  static const String spaceTypes = '/api/spaces/types';
  static const String spaceAvailability = '/api/spaces/availability';
  static const String spaces = '/api/spaces';
  static String spaceDetail(int id) => '/api/spaces/$id';

  // 4. Diskon & Promo
  static const String activeDiskon = '/api/diskon/active';
  static const String checkDiskon = '/api/diskon/check';
  static String diskonDetail(int id) => '/api/diskon/$id';

  // 5. Reservasi Member
  static const String reservasi = '/api/reservasi';
  static const String myReservasi = '/api/reservasi/my';
  static const String myReservasiHistory = '/api/reservasi/my/history';
  static String reservasiETicket(int id) => '/api/reservasi/$id/e-ticket';
  static String reservasiDetail(int id) => '/api/reservasi/$id';
  static String cancelReservasi(int id) => '/api/reservasi/$id/cancel';

  // 6. Profil Lokasi Coworking (Admin)
  static const String adminProfile = '/api/admin/profile';

  // 7. Manajemen Member (Admin)
  static const String adminMembers = '/api/admin/members';
  static String adminMemberDetail(int id) => '/api/admin/members/$id';

  // 8. Manajemen Space (Admin)
  static const String adminSpaces = '/api/admin/spaces';
  static String adminSpaceDetail(int id) => '/api/admin/spaces/$id';

  // 9. Manajemen Diskon (Admin)
  static const String adminDiskon = '/api/admin/diskon';
  static String adminDiskonDetail(int id) => '/api/admin/diskon/$id';

  // 10. Reservasi & Check-In/Out (Admin)
  static const String adminReservasi = '/api/admin/reservasi';
  static String adminReservasiStatus(int id) =>
      '/api/admin/reservasi/$id/status';
  static String adminCheckIn(int id) => '/api/admin/reservasi/$id/check-in';
  static String adminCheckOut(int id) => '/api/admin/reservasi/$id/check-out';

  // 11. Laporan Pendapatan (Admin)
  static const String adminReportsMonthly = '/api/admin/reports/monthly';
  static const String adminReportsIncome = '/api/admin/reports/income';

  // 12. Upload Media
  static const String uploadImage = '/api/upload/image';
  static const String uploadSpaces = '/api/upload/spaces';
  static const String uploadMembers = '/api/upload/members';
}
