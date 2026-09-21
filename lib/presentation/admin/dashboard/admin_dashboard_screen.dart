import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../utils/formatters.dart';
import '../../shared/providers/admin_provider.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/widgets/server_config_dialog.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  void _loadDashboardData() async {
    final admin = context.read<AdminProvider>();
    admin.fetchProfile();
    admin.fetchSpaces();
    admin.fetchMembers();
    admin.fetchDiskon();
    await admin.fetchReservations();
    await admin.fetchMonthlyReport();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final admin = context.watch<AdminProvider>();

    final profile = admin.coworkingProfile ?? auth.currentUser;
    final pendingCount = admin.reservations
        .where((r) => r.status.toLowerCase() == 'belum_dikonfirm' || r.status.toLowerCase() == 'pending')
        .length;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _loadDashboardData(),
          color: AppColors.primaryYellow,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Info Admin & Lokasi
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile?.namaCoworking ?? 'Moklet Coworking Space',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primaryNavy,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Pengelola: ${profile?.namaPemilik ?? auth.currentUser?.username ?? "Admin"}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton.filledTonal(
                          style: IconButton.styleFrom(backgroundColor: AppColors.yellowLight),
                          onPressed: () => ServerConfigDialog.show(context),
                          icon: const Icon(Icons.tune_rounded, color: AppColors.primaryYellow, size: 20),
                          tooltip: 'Konfigurasi Server & Maker Key',
                        ),
                        const SizedBox(width: 6),
                        IconButton.filledTonal(
                          style: IconButton.styleFrom(backgroundColor: AppColors.errorLight),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Keluar dari Admin?'),
                                content: const Text('Apakah Anda yakin ingin logout?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                    child: const Text('Keluar', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true && context.mounted) {
                              await auth.logout();
                              if (context.mounted) {
                                context.go('/login');
                              }
                            }
                          },
                          icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
                          tooltip: 'Keluar',
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 2. Banner Perhatian: Reservasi Pending
                if (pendingCount > 0)
                  InkWell(
                    onTap: () => context.go('/admin/reservasi'),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.warningLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.notification_important_rounded, color: AppColors.warning, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$pendingCount Pesanan Menunggu Konfirmasi!',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF92400E),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Klik di sini untuk menyetujui pemesanan member sekarang.',
                                  style: TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF92400E)),
                        ],
                      ),
                    ),
                  ),

                // 3. Kartu Statistik Utama
                const Text(
                  'Ringkasan Operasional',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: 'Total Space',
                        value: '${admin.spaces.length}',
                        icon: Icons.desk_rounded,
                        color: AppColors.info,
                        bgColor: AppColors.infoLight,
                        onTap: () => context.push('/admin/space-crud'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        title: 'Total Member',
                        value: '${admin.members.length}',
                        icon: Icons.people_alt_rounded,
                        color: AppColors.primaryYellow,
                        bgColor: AppColors.yellowLight,
                        onTap: () => context.push('/admin/member-crud'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: 'Pending Approval',
                        value: '$pendingCount',
                        icon: Icons.pending_actions_rounded,
                        color: AppColors.warning,
                        bgColor: AppColors.warningLight,
                        onTap: () => context.go('/admin/reservasi'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        title: 'Promo Aktif',
                        value: '${admin.diskonList.length}',
                        icon: Icons.local_offer_rounded,
                        color: AppColors.success,
                        bgColor: AppColors.successLight,
                        onTap: () => context.push('/admin/diskon-crud'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 4. Kartu Pendapatan Bulan Berjalan
                InkWell(
                  onTap: () => context.go('/admin/reports'),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryNavy, AppColors.navyLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryNavy.withValues(alpha: 0.25),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Pendapatan Bulan Ini',
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Bulan ${DateTime.now().month}/${DateTime.now().year}',
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          Formatters.rupiah(admin.monthlyReport?.totalPendapatan ?? 0),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryYellow,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Reservasi Berhasil: ${admin.monthlyReport?.totalReservasi ?? 0} Transaksi',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            const Row(
                              children: [
                                Text(
                                  'Lihat Rekap',
                                  style: TextStyle(color: AppColors.primaryYellow, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.primaryYellow),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 5. Menu Cepat (Quick Access)
                const Text(
                  'Aksi Cepat Pengelola',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                ),
                const SizedBox(height: 12),

                _buildQuickActionTile(
                  icon: Icons.edit_note_rounded,
                  title: 'Edit Profil Coworking',
                  subtitle: 'Nama space, pemilik, nomor telepon hotline',
                  onTap: () => context.push('/admin/profile-edit'),
                ),
                _buildQuickActionTile(
                  icon: Icons.add_business_rounded,
                  title: 'Tambah Space Baru',
                  subtitle: 'Tambah meja kerja, meeting room, private office',
                  onTap: () => context.push('/admin/space-crud'),
                ),
                _buildQuickActionTile(
                  icon: Icons.group_add_rounded,
                  title: 'Kelola Data Member',
                  subtitle: 'Daftar, edit, atau daftarkan pelanggan baru',
                  onTap: () => context.push('/admin/member-crud'),
                ),
                _buildQuickActionTile(
                  icon: Icons.discount_rounded,
                  title: 'Kelola Kode Promo / Diskon',
                  subtitle: 'Buat kode diskon promosi untuk member',
                  onTap: () => context.push('/admin/diskon-crud'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.yellowPale,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primaryYellow, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
      ),
    );
  }
}
