import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/reservasi_model.dart';
import '../../../utils/formatters.dart';
import '../../shared/providers/reservasi_provider.dart';
import '../../shared/widgets/status_badge.dart';

class MemberBookingStatusScreen extends StatefulWidget {
  const MemberBookingStatusScreen({super.key});

  @override
  State<MemberBookingStatusScreen> createState() => _MemberBookingStatusScreenState();
}

class _MemberBookingStatusScreenState extends State<MemberBookingStatusScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReservasiProvider>().fetchMyReservations();
    });
  }

  void _handleCancel(ReservasiModel res) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Batalkan Reservasi?'),
        content: Text(
          'Apakah Anda yakin ingin membatalkan reservasi untuk ${res.displayTitle} pada tanggal ${Formatters.dateWithDay(res.tanggalReservasi)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Kembali'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Ya, Batalkan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final prov = context.read<ReservasiProvider>();
      final success = await prov.cancelReservation(res.id);
      if (mounted) {
        if (success) {
          prov.fetchMyReservations();
          prov.fetchHistory();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Reservasi berhasil dibatalkan' : (prov.errorMessage ?? 'Gagal membatalkan')),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reservasiProv = context.watch<ReservasiProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Status Pemesanan',
          style: TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primaryNavy),
            onPressed: () => reservasiProv.fetchMyReservations(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => reservasiProv.fetchMyReservations(),
        color: AppColors.primaryYellow,
        child: reservasiProv.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow))
            : reservasiProv.myReservations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            color: AppColors.yellowLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.confirmation_number_outlined,
                            size: 48,
                            color: AppColors.primaryYellow,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Belum Ada Pemesanan Aktif',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Pilih space dan ajukan reservasi pertama Anda.',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: reservasiProv.myReservations.length,
                    itemBuilder: (context, index) {
                      final item = reservasiProv.myReservations[index];
                      return _buildReservationCard(item);
                    },
                  ),
      ),
    );
  }

  Widget _buildReservationCard(ReservasiModel item) {
    final statusLower = item.status.toLowerCase();
    final canViewTicket = statusLower.contains('setuju') ||
        statusLower.contains('approv') ||
        statusLower.contains('aktif') ||
        statusLower.contains('check_in') ||
        statusLower.contains('selesai') ||
        statusLower.contains('check_out');
    final canCancel = statusLower.contains('belum') ||
        statusLower.contains('pending') ||
        statusLower.contains('menunggu');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris Atas: Kode Reservasi & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bookmark_border_rounded, size: 18, color: AppColors.primaryYellow),
                    const SizedBox(width: 6),
                    Text(
                      item.kodeReservasi ?? '#${item.id}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                  ],
                ),
                StatusBadge(status: item.status),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 12),

            // Informasi Space (Foto, Judul Space Sesuai Backend, & Badge Tipe)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: Image.network(
                      item.displayFotoSpace,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.bgLight,
                          child: Icon(
                            item.space?.tipe.toLowerCase().contains('meeting') == true
                                ? Icons.groups_rounded
                                : (item.space?.tipe.toLowerCase().contains('office') == true
                                    ? Icons.business_rounded
                                    : Icons.desk_rounded),
                            color: AppColors.primaryYellow,
                            size: 30,
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
                      Text(
                        item.displayTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryNavy,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.yellowLight,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.primaryYellow.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  item.space?.tipe.toLowerCase().contains('meeting') == true
                                      ? Icons.groups_outlined
                                      : (item.space?.tipe.toLowerCase().contains('office') == true
                                          ? Icons.business_outlined
                                          : Icons.desk_outlined),
                                  size: 11,
                                  color: AppColors.primaryNavy,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  item.displayTipeSpace,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryNavy,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (item.space != null && item.space!.kapasitas > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.person_outline_rounded, size: 11, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${item.space!.kapasitas} Org',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
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

            // Info Tanggal & Waktu
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.bgLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_outlined, size: 15, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    Formatters.dateWithDay(item.tanggalReservasi),
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 14),
                  const Icon(Icons.access_time_rounded, size: 15, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    '${item.jamMulai} (${item.durasiJam} Jam)',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── RINCIAN BIAYA & PEMBAYARAN ─────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Biaya Sewa (${Formatters.rupiah(item.calculatedSubtotal / (item.durasiJam > 0 ? item.durasiJam : 1))} x ${item.durasiJam} jam)',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      Text(
                        Formatters.rupiah(item.calculatedSubtotal),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryNavy),
                      ),
                    ],
                  ),
                  if (item.calculatedDiscount > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.local_offer_rounded, size: 13, color: AppColors.success),
                            const SizedBox(width: 4),
                            Text(
                              item.kodePromo != null && item.kodePromo!.isNotEmpty
                                  ? 'Diskon Promo (${item.kodePromo})'
                                  : (item.diskon != null
                                      ? 'Diskon Promo (${item.diskon!.namaDiskon})'
                                      : 'Diskon Promo'),
                              style: const TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Text(
                          '-${Formatters.rupiah(item.calculatedDiscount)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Pembayaran',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                          ),
                          Text(
                            'Biaya bersih yang dibayarkan',
                            style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                      Text(
                        Formatters.rupiah(item.calculatedTotalBayar),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Tombol Aksi
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (canCancel)
                  TextButton.icon(
                    onPressed: () => _handleCancel(item),
                    icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.error),
                    label: const Text('Batalkan', style: TextStyle(color: AppColors.error, fontSize: 12)),
                  ),
                if (item.space != null) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      context.push('/space-detail', extra: item.space!);
                    },
                    icon: const Icon(Icons.info_outline_rounded, size: 15),
                    label: const Text('Detail Space', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryNavy,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
                if (canViewTicket) ...[
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.push('/e-ticket/${item.id}');
                    },
                    icon: const Icon(Icons.qr_code_rounded, size: 16),
                    label: const Text('E-Ticket', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryNavy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
