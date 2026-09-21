import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/reservasi_model.dart';
import '../../../utils/formatters.dart';
import '../../shared/providers/reservasi_provider.dart';
import '../../shared/widgets/status_badge.dart';

class MemberHistoryScreen extends StatefulWidget {
  const MemberHistoryScreen({super.key});

  @override
  State<MemberHistoryScreen> createState() => _MemberHistoryScreenState();
}

class _MemberHistoryScreenState extends State<MemberHistoryScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  final List<String> _months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHistory();
    });
  }

  void _loadHistory() {
    context.read<ReservasiProvider>().fetchHistory(
      month: _selectedMonth,
      year: _selectedYear,
    );
  }

  @override
  Widget build(BuildContext context) {
    final reservasiProv = context.watch<ReservasiProvider>();

    // Hitung total pengeluaran bulan ini
    double totalSpent = 0;
    for (final r in reservasiProv.historyReservations) {
      if (r.status.toLowerCase() != 'dibatalkan') {
        totalSpent += r.calculatedTotalBayar;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Histori Pemesanan',
          style: TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadHistory(),
        color: AppColors.primaryYellow,
        child: CustomScrollView(
          slivers: [
            // 1. FILTER BULAN & TAHUN
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                child: Row(
                  children: [
                    // Dropdown Bulan
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
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primaryNavy),
                            isExpanded: true,
                            items: List.generate(12, (index) {
                              return DropdownMenuItem(
                                value: index + 1,
                                child: Text(
                                  _months[index],
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryNavy),
                                ),
                              );
                            }),
                            onChanged: (newMonth) {
                              if (newMonth != null) {
                                setState(() {
                                  _selectedMonth = newMonth;
                                });
                                _loadHistory();
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Dropdown Tahun
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
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primaryNavy),
                            isExpanded: true,
                            items: [2025, 2026, 2027].map((y) {
                              return DropdownMenuItem(
                                value: y,
                                child: Text(
                                  '$y',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryNavy),
                                ),
                              );
                            }).toList(),
                            onChanged: (newYear) {
                              if (newYear != null) {
                                setState(() {
                                  _selectedYear = newYear;
                                });
                                _loadHistory();
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

            // 2. RINGKASAN STATISTIK BULANAN
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(18),
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
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Reservasi (${_months[_selectedMonth - 1]})',
                          style: const TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${reservasiProv.historyReservations.length} Transaksi',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Total Pengeluaran',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          Formatters.rupiah(totalSpent),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryYellow,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 3. DAFTAR RIWAYAT
            if (reservasiProv.isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primaryYellow)),
                ),
              )
            else if (reservasiProv.historyReservations.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 50),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.history_toggle_off_rounded, size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 10),
                        Text(
                          'Tidak ada riwayat reservasi pada ${_months[_selectedMonth - 1]} $_selectedYear',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = reservasiProv.historyReservations[index];
                      return _buildHistoryItem(item);
                    },
                    childCount: reservasiProv.historyReservations.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(ReservasiModel item) {
    final statusLower = item.status.toLowerCase();
    final canViewTicket = statusLower.contains('setuju') ||
        statusLower.contains('approv') ||
        statusLower.contains('aktif') ||
        statusLower.contains('check_in') ||
        statusLower.contains('selesai') ||
        statusLower.contains('check_out');

    return InkWell(
      onTap: canViewTicket ? () => context.push('/e-ticket/${item.id}') : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: Image.network(
                      item.displayFotoSpace,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.bgLight,
                          child: const Icon(
                            Icons.meeting_room_rounded,
                            color: AppColors.primaryYellow,
                            size: 24,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.displayTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryNavy,
                              ),
                            ),
                          ),
                          StatusBadge(status: item.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${Formatters.dateWithDay(item.tanggalReservasi)} • ${item.jamMulai} (${item.durasiJam} Jam)',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.yellowLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.displayTipeSpace,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primaryNavy),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      item.kodeReservasi ?? '#${item.id}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                    ),
                    if (canViewTicket) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.qr_code_rounded, size: 14, color: AppColors.primaryYellow),
                      const SizedBox(width: 2),
                      const Text(
                        'E-Ticket',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryYellow),
                      ),
                    ],
                  ],
                ),
                Text(
                  Formatters.rupiah(item.calculatedTotalBayar),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryNavy,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
