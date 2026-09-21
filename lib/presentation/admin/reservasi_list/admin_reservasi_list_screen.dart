import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/reservasi_model.dart';
import '../../../utils/formatters.dart';
import '../../shared/providers/admin_provider.dart';
import '../../shared/widgets/status_badge.dart';

class AdminReservasiListScreen extends StatefulWidget {
  const AdminReservasiListScreen({super.key});

  @override
  State<AdminReservasiListScreen> createState() => _AdminReservasiListScreenState();
}

class _AdminReservasiListScreenState extends State<AdminReservasiListScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  String _selectedStatus = 'All';

  final List<String> _months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReservations();
    });
  }

  void _loadReservations() {
    context.read<AdminProvider>().fetchReservations(
      month: _selectedMonth,
      year: _selectedYear,
      status: _selectedStatus,
    );
  }

  void _handleStatusUpdate(int id, String newStatus, String actionName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$actionName Reservasi?'),
        content: Text('Apakah Anda yakin ingin melakukan $actionName untuk reservasi ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus == 'dibatalkan' ? AppColors.error : AppColors.primaryNavy,
            ),
            child: Text(actionName, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final admin = context.read<AdminProvider>();
      bool success;
      if (newStatus == 'check-in') {
        success = await admin.checkIn(id);
      } else if (newStatus == 'check-out') {
        success = await admin.checkOut(id);
      } else {
        success = await admin.updateStatus(id, newStatus);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '$actionName berhasil diproses!' : (admin.errorMessage ?? 'Gagal memproses')),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Kelola Reservasi',
          style: TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primaryNavy),
            onPressed: _loadReservations,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadReservations(),
        color: AppColors.primaryYellow,
        child: CustomScrollView(
          slivers: [
            // 1. FILTER BULAN & TAHUN
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.bgLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _selectedMonth,
                            isExpanded: true,
                            items: List.generate(12, (index) {
                              return DropdownMenuItem(
                                value: index + 1,
                                child: Text(_months[index], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              );
                            }),
                            onChanged: (m) {
                              if (m != null) {
                                setState(() => _selectedMonth = m);
                                _loadReservations();
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.bgLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _selectedYear,
                            isExpanded: true,
                            items: [2025, 2026, 2027].map((y) {
                              return DropdownMenuItem(
                                value: y,
                                child: Text('$y', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              );
                            }).toList(),
                            onChanged: (y) {
                              if (y != null) {
                                setState(() => _selectedYear = y);
                                _loadReservations();
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. FILTER STATUS CHIPS
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatusChip('All', 'Semua'),
                      const SizedBox(width: 8),
                      _buildStatusChip('belum_dikonfirm', 'Menunggu'),
                      const SizedBox(width: 8),
                      _buildStatusChip('disetujui', 'Disetujui'),
                      const SizedBox(width: 8),
                      _buildStatusChip('aktif', 'Sedang Aktif'),
                      const SizedBox(width: 8),
                      _buildStatusChip('selesai', 'Selesai'),
                      const SizedBox(width: 8),
                      _buildStatusChip('dibatalkan', 'Batal'),
                    ],
                  ),
                ),
              ),
            ),

            // 3. DAFTAR RESERVASI ADMIN
            if (admin.isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primaryYellow)),
                ),
              )
            else if (admin.reservations.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 50),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.inbox_rounded, size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 10),
                        Text(
                          'Tidak ada reservasi ditemukan pada filter ini.',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = admin.reservations[index];
                      return _buildAdminReservationCard(item);
                    },
                    childCount: admin.reservations.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String key, String label) {
    final isSelected = _selectedStatus.toLowerCase() == key.toLowerCase();
    return ChoiceChip(
      selected: isSelected,
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : AppColors.primaryNavy,
        ),
      ),
      selectedColor: AppColors.primaryNavy,
      backgroundColor: AppColors.bgLight,
      side: BorderSide(color: isSelected ? AppColors.primaryNavy : AppColors.border),
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedStatus = key);
          _loadReservations();
        }
      },
    );
  }

  Widget _buildAdminReservationCard(ReservasiModel item) {
    final status = item.status.toLowerCase();
    final isPending = status == 'belum_dikonfirm' || status == 'pending';
    final isApproved = status == 'disetujui' || status == 'approved';
    final isActive = status == 'aktif' || status == 'active';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPending ? AppColors.warning.withValues(alpha: 0.5) : AppColors.border,
          width: isPending ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Baris: Kode & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.kodeReservasi ?? '#${item.id}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryNavy,
                  letterSpacing: 0.5,
                ),
              ),
              StatusBadge(status: item.status),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 10),

          // Space & Member Details
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 62,
                  height: 62,
                  child: Image.network(
                    item.displayFotoSpace,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.bgLight,
                      child: Icon(
                        item.space?.tipe.toLowerCase().contains('meeting') == true
                            ? Icons.groups_rounded
                            : (item.space?.tipe.toLowerCase().contains('office') == true
                                ? Icons.business_rounded
                                : Icons.desk_rounded),
                        color: AppColors.primaryYellow,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.displayTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: AppColors.yellowLight,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.primaryYellow.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            item.displayTipeSpace,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${item.member?.namaMember ?? item.member?.username ?? "Member"} (${item.member?.instansi ?? "-"})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.calendar_month_outlined, size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${Formatters.dateWithDay(item.tanggalReservasi)} • ${item.jamMulai} (${item.durasiJam} Jam)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Total Bayar & Aksi Operasional
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Bayar', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  Text(
                    Formatters.rupiah(item.calculatedTotalBayar),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryYellow,
                    ),
                  ),
                ],
              ),

              // Tombol-Tombol Operasional Admin
              Row(
                children: [
                  if (isPending) ...[
                    OutlinedButton(
                      onPressed: () => _handleStatusUpdate(item.id, 'dibatalkan', 'Tolak'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Tolak', style: TextStyle(color: AppColors.error, fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _handleStatusUpdate(item.id, 'disetujui', 'Setujui'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Setujui', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                  if (isApproved)
                    ElevatedButton.icon(
                      onPressed: () => _handleStatusUpdate(item.id, 'check-in', 'Check-In'),
                      icon: const Icon(Icons.login_rounded, size: 16, color: Colors.white),
                      label: const Text('Check-In', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.info,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  if (isActive)
                    ElevatedButton.icon(
                      onPressed: () => _handleStatusUpdate(item.id, 'check-out', 'Check-Out'),
                      icon: const Icon(Icons.logout_rounded, size: 16, color: Colors.white),
                      label: const Text('Check-Out', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
