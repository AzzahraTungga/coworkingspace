import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../utils/formatters.dart';
import '../../shared/providers/reservasi_provider.dart';
import '../../shared/widgets/status_badge.dart';

class ETicketScreen extends StatefulWidget {
  final int reservasiId;
  const ETicketScreen({super.key, required this.reservasiId});

  @override
  State<ETicketScreen> createState() => _ETicketScreenState();
}

class _ETicketScreenState extends State<ETicketScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReservasiProvider>().fetchETicket(widget.reservasiId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final reservasiProv = context.watch<ReservasiProvider>();
    final ticket = reservasiProv.currentETicket;

    return Scaffold(
      backgroundColor: AppColors.primaryNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'E-Ticket Pass',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: reservasiProv.isLoadingTicket
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow))
          : ticket == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.primaryYellow),
                      const SizedBox(height: 12),
                      Text(
                        reservasiProv.errorMessage ?? 'E-Ticket belum dapat dimuat.',
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => reservasiProv.fetchETicket(widget.reservasiId),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryYellow),
                        child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
                  child: Column(
                    children: [
                      // TIKET CARD DENGAN STYLING PREMIUM
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Header Tiket
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              decoration: const BoxDecoration(
                                color: AppColors.yellowPale,
                                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.confirmation_number_rounded, color: AppColors.primaryYellow),
                                      const SizedBox(width: 8),
                                      Text(
                                        ticket.kodeReservasi,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.primaryNavy,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                  StatusBadge(status: ticket.status),
                                ],
                              ),
                            ),

                            // QR Code Section
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: AppColors.border, width: 1.5),
                                    ),
                                    child: QrImageView(
                                      data: ticket.qrCodePayload.isNotEmpty
                                          ? ticket.qrCodePayload
                                          : ticket.kodeReservasi,
                                      version: QrVersions.auto,
                                      size: 190.0,
                                      eyeStyle: const QrEyeStyle(
                                        eyeShape: QrEyeShape.square,
                                        color: AppColors.primaryNavy,
                                      ),
                                      dataModuleStyle: const QrDataModuleStyle(
                                        dataModuleShape: QrDataModuleShape.square,
                                        color: AppColors.primaryNavy,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  const Text(
                                    'Tunjukkan QR Code ini ke petugas saat Check-In',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Garis Sobek Tiket (Ticket Perforation)
                            Row(
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 32,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryNavy,
                                      borderRadius: BorderRadius.horizontal(right: Radius.circular(16)),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      return Flex(
                                        direction: Axis.horizontal,
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        mainAxisSize: MainAxisSize.max,
                                        children: List.generate(
                                          (constraints.constrainWidth() / 10).floor(),
                                          (_) => const SizedBox(
                                            width: 5,
                                            height: 1.5,
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(color: AppColors.border),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(
                                  width: 16,
                                  height: 32,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryNavy,
                                      borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Detail Informasi Tiket
                            Padding(
                              padding: const EdgeInsets.all(22),
                              child: Column(
                                children: [
                                  _buildTicketRow('Space', ticket.namaSpace),
                                  const SizedBox(height: 10),
                                  _buildTicketRow('Pengunjung', ticket.namaMember),
                                  const SizedBox(height: 10),
                                  _buildTicketRow('Instansi', ticket.instansi),
                                  const SizedBox(height: 10),
                                  _buildTicketRow('Tanggal', Formatters.dateWithDay(ticket.tanggalReservasi)),
                                  const SizedBox(height: 10),
                                  _buildTicketRow('Waktu', '${ticket.jamMulai} (${ticket.durasiJam} Jam)'),
                                  const SizedBox(height: 10),
                                  _buildTicketRow('Total Bayar', Formatters.rupiah(ticket.totalBayar), isHighlight: true),
                                ],
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

  Widget _buildTicketRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlight ? 15 : 13,
            fontWeight: FontWeight.bold,
            color: isHighlight ? AppColors.primaryYellow : AppColors.primaryNavy,
          ),
        ),
      ],
    );
  }
}
