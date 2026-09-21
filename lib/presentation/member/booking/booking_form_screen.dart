import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/diskon_model.dart';
import '../../../data/models/space_model.dart';
import '../../../utils/formatters.dart';
import '../../shared/providers/booking_provider.dart';
import '../../shared/providers/reservasi_provider.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/custom_text_field.dart';

class BookingFormScreen extends StatefulWidget {
  final SpaceModel space;
  const BookingFormScreen({super.key, required this.space});

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final TextEditingController _promoController = TextEditingController();

  final List<String> _presetTimeSlots = [
    '08:00',
    '09:00',
    '10:00',
    '11:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '18:00',
  ];

  final List<int> _presetDurations = [1, 2, 3, 4, 8];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final booking = context.read<BookingProvider>();
      booking.reset();
      // Otomatis cek ketersediaan slot awal untuk memastikan jam default belum ada bookingan
      booking.checkAvailability(widget.space.id);
    });
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _calculateEndTime(String startTime, int durationHours) {
    final parts = startTime.split(':');
    final hour = int.tryParse(parts[0]) ?? 9;
    final minute = parts.length > 1 ? parts[1] : '00';
    final endHour = (hour + durationHours) % 24;
    return '${endHour.toString().padLeft(2, '0')}:$minute';
  }

  void _showUnavailableSlotDialog(BuildContext context, BookingProvider booking) {
    final endTime = _calculateEndTime(booking.selectedTime, booking.durasiJam);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3), width: 3),
              ),
              child: const Icon(Icons.event_busy_rounded, color: AppColors.error, size: 38),
            ),
            const SizedBox(height: 18),
            const Text(
              'Slot Sudah Ada Bookingan!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primaryNavy),
            ),
            const SizedBox(height: 10),
            Text(
              'Ruangan ${widget.space.namaSpace} pada tanggal ${Formatters.date(booking.selectedDate)} jam ${booking.selectedTime} s/d $endTime (${booking.durasiJam} jam) sudah memiliki bookingan lain atau tidak tersedia.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.45),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      booking.availabilityMessage ?? 'Silakan pilih tanggal atau jam mulai lainnya.',
                      style: const TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            CustomButton(
              text: 'Pilih Jadwal Lain',
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSubmit() async {
    final booking = context.read<BookingProvider>();

    // 1. Selalu cek ketersediaan slot ke server terlebih dahulu sebelum booking
    if (booking.isAvailable == null) {
      final isAvail = await booking.checkAvailability(widget.space.id);
      if (!isAvail && mounted) {
        _showUnavailableSlotDialog(context, booking);
        return;
      }
    }

    // 2. Jika slot sudah dipastikan tidak tersedia (sudah ada bookingan pada jam tersebut)
    if (booking.isAvailable == false) {
      if (mounted) {
        _showUnavailableSlotDialog(context, booking);
      }
      return;
    }

    final safeRate = widget.space.hargaPerJam > 0
        ? widget.space.hargaPerJam
        : (widget.space.tipe.toLowerCase().contains('meeting')
            ? 75000.0
            : (widget.space.tipe.toLowerCase().contains('office') ? 150000.0 : 25000.0));
    final expectedTotal = booking.calculateTotal(safeRate);

    final result = await booking.submitBooking(widget.space);

    if (result != null && mounted) {
      // Daftarkan reservasi terkonfirmasi lengkap dengan harga final yang disetujui user
      context.read<ReservasiProvider>().registerConfirmedBooking(result);
      context.read<ReservasiProvider>().fetchMyReservations();
      context.read<ReservasiProvider>().fetchHistory();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3), width: 3),
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 44),
              ),
              const SizedBox(height: 18),
              const Text(
                'Reservasi Berhasil Diajukan!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.primaryNavy),
              ),
              const SizedBox(height: 8),
              Text(
                'Pesanan Anda untuk ${widget.space.namaSpace} berhasil dibuat dan sedang menunggu konfirmasi admin.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 18),
              // Kode Reservasi & Detail Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.yellowPale,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primaryYellow.withValues(alpha: 0.4)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'KODE RESERVASI',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result.kodeReservasi ?? "#${result.id}",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primaryNavy),
                    ),
                    const Divider(height: 16, color: Color(0xFFE2E8F0)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Pembayaran:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Text(
                          Formatters.rupiah(result.totalBayar > 0 ? result.totalBayar : expectedTotal),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.primaryNavy),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              CustomButton(
                text: 'Lihat Status Pesanan',
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/member/booking-status');
                },
              ),
            ],
          ),
        ),
      );
    } else if (mounted && booking.errorMessage != null) {
      // Jika penolakan terjadi karena slot bentrok
      if (booking.errorMessage!.toLowerCase().contains('bookingan') ||
          booking.errorMessage!.toLowerCase().contains('terisi') ||
          booking.errorMessage!.toLowerCase().contains('tidak tersedia') ||
          booking.errorMessage!.toLowerCase().contains('bentrok')) {
        _showUnavailableSlotDialog(context, booking);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(booking.errorMessage!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingProvider>();
    final space = widget.space;
    final safeRate = space.hargaPerJam > 0
        ? space.hargaPerJam
        : (space.tipe.toLowerCase().contains('meeting')
            ? 75000.0
            : (space.tipe.toLowerCase().contains('office') ? 150000.0 : 25000.0));

    final subtotal = booking.calculateSubtotal(safeRate);
    final discount = booking.calculateDiscount(safeRate);
    final total = booking.calculateTotal(safeRate);
    final endTimeStr = _calculateEndTime(booking.selectedTime, booking.durasiJam);

    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final dayAfter = now.add(const Duration(days: 2));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.bgLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primaryNavy, size: 16),
          ),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Form Pemesanan',
              style: TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.w800, fontSize: 17),
            ),
            Text(
              'Lengkapi jadwal dan rincian sewa space',
              style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.8), fontSize: 11),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. RINGKASAN SPACE CARD ──────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          space.displayImageUrl,
                          width: 86,
                          height: 76,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 86,
                            height: 76,
                            color: AppColors.yellowPale,
                            child: const Icon(Icons.meeting_room_rounded, color: AppColors.primaryYellow, size: 30),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryNavy.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            space.tipeFormatted,
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          space.namaSpace,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryNavy,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.people_alt_outlined, size: 13, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              'Kapasitas ${space.kapasitas} Orang',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.yellowLight.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.primaryYellow.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            '${Formatters.rupiah(safeRate)} / jam',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryNavy,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // ── 2. JADWAL PENGGUNAAN (TANGGAL & WAKTU) ────────────────
            _buildSectionHeader(
              icon: Icons.calendar_month_rounded,
              title: 'Jadwal Penggunaan',
              subtitle: 'Tentukan tanggal dan jam mulai pemakaian ruangan',
            ),
            const SizedBox(height: 12),

            // Date Card Selector
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: booking.selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                );
                if (picked != null) {
                  booking.setDate(picked, widget.space.id);
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.yellowPale,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.calendar_today_rounded, size: 20, color: AppColors.primaryYellow),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tanggal Reservasi', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          const SizedBox(height: 2),
                          Text(
                            Formatters.date(booking.selectedDate),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.bgLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Text('Ubah', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
                          SizedBox(width: 2),
                          Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.primaryNavy),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Quick Date Chips (Hari Ini, Besok, Lusa)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickDateChip(
                    label: 'Hari Ini',
                    date: now,
                    isSelected: _isSameDay(booking.selectedDate, now),
                    onTap: () => booking.setDate(now, widget.space.id),
                  ),
                  const SizedBox(width: 8),
                  _buildQuickDateChip(
                    label: 'Besok',
                    date: tomorrow,
                    isSelected: _isSameDay(booking.selectedDate, tomorrow),
                    onTap: () => booking.setDate(tomorrow, widget.space.id),
                  ),
                  const SizedBox(width: 8),
                  _buildQuickDateChip(
                    label: 'Lusa',
                    date: dayAfter,
                    isSelected: _isSameDay(booking.selectedDate, dayAfter),
                    onTap: () => booking.setDate(dayAfter, widget.space.id),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Jam Mulai Selector Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.yellowLight.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.schedule_rounded, size: 20, color: AppColors.primaryNavy),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Jam Mulai Pemakaian', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        Text(
                          '${booking.selectedTime} WIB (Selesai ~ $endTimeStr)',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_calendar_rounded, size: 20, color: AppColors.primaryYellow),
                    tooltip: 'Pilih Jam Kustom',
                    onPressed: () async {
                      final parts = booking.selectedTime.split(':');
                      final currentHour = int.tryParse(parts[0]) ?? 9;
                      final currentMin = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(hour: currentHour, minute: currentMin),
                      );
                      if (picked != null) {
                        final formatted =
                            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                        booking.setTime(formatted, widget.space.id);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Preset Time Slots Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presetTimeSlots.map((slot) {
                final isSelected = booking.selectedTime == slot;
                return InkWell(
                  onTap: () => booking.setTime(slot, widget.space.id),
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryYellow : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppColors.primaryYellow : const Color(0xFFCBD5E1),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primaryYellow.withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      slot,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? AppColors.primaryNavy : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 22),

            // ── 3. DURASI PEMAKAIAN STEPPER ─────────────────────────
            _buildSectionHeader(
              icon: Icons.timelapse_rounded,
              title: 'Durasi Pemakaian Ruangan',
              subtitle: 'Pilih lama sewa per jam sesuai kebutuhan kerja Anda',
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Durasi Sewa', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          const SizedBox(height: 2),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '${booking.durasiJam}',
                                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.primaryNavy),
                              ),
                              const SizedBox(width: 4),
                              const Text('Jam', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          InkWell(
                            onTap: booking.durasiJam > 1 ? () => booking.setDuration(booking.durasiJam - 1, widget.space.id) : null,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: booking.durasiJam > 1 ? AppColors.bgLight : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Icon(
                                Icons.remove_rounded,
                                size: 20,
                                color: booking.durasiJam > 1 ? AppColors.primaryNavy : AppColors.textMuted,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          InkWell(
                            onTap: booking.durasiJam < 12 ? () => booking.setDuration(booking.durasiJam + 1, widget.space.id) : null,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.yellowLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.primaryYellow.withValues(alpha: 0.5)),
                              ),
                              child: const Icon(
                                Icons.add_rounded,
                                size: 20,
                                color: AppColors.primaryNavy,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 12),
                  // Preset Duration Chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _presetDurations.map((hrs) {
                      final isSelected = booking.durasiJam == hrs;
                      return InkWell(
                        onTap: () => booking.setDuration(hrs, widget.space.id),
                        borderRadius: BorderRadius.circular(8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryNavy : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? AppColors.primaryNavy : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Text(
                            hrs == 8 ? '8 Jam (Seharian)' : '$hrs Jam',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── 4. CARD STATUS KETERSEDIAAN RUANGAN ───────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: booking.isCheckingAvailability
                    ? AppColors.yellowPale
                    : (booking.isAvailable == true
                        ? AppColors.successLight
                        : (booking.isAvailable == false ? AppColors.errorLight : Colors.white)),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: booking.isCheckingAvailability
                      ? AppColors.primaryYellow.withValues(alpha: 0.5)
                      : (booking.isAvailable == true
                          ? AppColors.success.withValues(alpha: 0.5)
                          : (booking.isAvailable == false ? AppColors.error.withValues(alpha: 0.5) : const Color(0xFFCBD5E1))),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: booking.isCheckingAvailability
                          ? AppColors.yellowLight
                          : (booking.isAvailable == true
                              ? AppColors.success.withValues(alpha: 0.15)
                              : (booking.isAvailable == false
                                  ? AppColors.error.withValues(alpha: 0.15)
                                  : AppColors.bgLight)),
                      shape: BoxShape.circle,
                    ),
                    child: booking.isCheckingAvailability
                        ? const Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: AppColors.primaryNavy,
                              ),
                            ),
                          )
                        : Icon(
                            booking.isAvailable == true
                                ? Icons.check_circle_rounded
                                : (booking.isAvailable == false ? Icons.event_busy_rounded : Icons.event_available_rounded),
                            size: 20,
                            color: booking.isAvailable == true
                                ? AppColors.success
                                : (booking.isAvailable == false ? AppColors.error : AppColors.primaryNavy),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.isCheckingAvailability
                              ? 'Memeriksa Jadwal...'
                              : (booking.isAvailable == true
                                  ? 'Slot Waktu Tersedia!'
                                  : (booking.isAvailable == false
                                      ? 'Slot Sudah Ada Bookingan!'
                                      : 'Cek Ketersediaan Slot')),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: booking.isCheckingAvailability
                                ? AppColors.primaryNavy
                                : (booking.isAvailable == true
                                    ? AppColors.success
                                    : (booking.isAvailable == false ? AppColors.error : AppColors.primaryNavy)),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          booking.isCheckingAvailability
                              ? 'Mengecek apakah jam ini ada bookingan lain...'
                              : (booking.isAvailable == true
                                  ? 'Belum ada bookingan pada jam ini. Siap dipesan!'
                                  : (booking.isAvailable == false
                                      ? (booking.availabilityMessage ??
                                          'Ruangan sudah terisi pada jam ini. Silakan ubah jam.')
                                      : 'Pastikan ruangan belum dibooking sebelum memesan.')),
                          style: TextStyle(
                            fontSize: 11,
                            color: booking.isAvailable == false
                                ? AppColors.error.withValues(alpha: 0.85)
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: booking.isCheckingAvailability
                        ? null
                        : () => booking.checkAvailability(space.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: booking.isAvailable == true
                          ? AppColors.success
                          : (booking.isAvailable == false ? AppColors.error : AppColors.primaryNavy),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: booking.isCheckingAvailability
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            booking.isAvailable != null ? 'Cek Ulang' : 'Cek Slot',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // ── 5. KODE PROMO & VOUCHER DISKON ────────────────────────
            _buildSectionHeader(
              icon: Icons.local_offer_rounded,
              title: 'Kode Promo / Voucher',
              subtitle: 'Gunakan voucher diskon aktif untuk menghemat biaya',
            ),
            const SizedBox(height: 12),

            if (booking.appliedDiskon != null) ...[
              // Kartu Voucher Terpasang (Gaya Tiket)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.confirmation_number_rounded, color: AppColors.success, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                booking.appliedDiskon!.namaDiskon,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.primaryNavy),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '-${booking.appliedDiskon!.persentaseDiskon.toStringAsFixed(0)}%',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Hemat ${Formatters.rupiah(discount)} berhasil diterapkan!',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.success),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.error, size: 20),
                      tooltip: 'Hapus Voucher',
                      onPressed: () {
                        booking.removePromo();
                        _promoController.clear();
                      },
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Input Kode Promo
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _promoController,
                      label: '',
                      hint: 'Ketik kode promo (misal: HEMAT20)',
                      prefixIcon: Icons.local_offer_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: booking.isCheckingPromo
                        ? null
                        : () {
                            booking.applyPromoCode(_promoController.text);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryNavy,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: booking.isCheckingPromo
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Pasang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
              if (booking.promoMessage != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      booking.isPromoSuccess ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded,
                      size: 14,
                      color: booking.isPromoSuccess ? AppColors.success : AppColors.error,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        booking.promoMessage!,
                        style: TextStyle(
                          fontSize: 12,
                          color: booking.isPromoSuccess ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              // Daftar Voucher Aktif
              if (booking.activeDiscounts.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Voucher Tersedia (Ketuk untuk Menggunakan):',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: booking.activeDiscounts.map((d) {
                    return _buildVoucherPill(
                      diskon: d,
                      onTap: () {
                        _promoController.text = d.namaDiskon;
                        booking.applyDiskonDirect(d);
                      },
                    );
                  }).toList(),
                ),
              ],
            ],
            const SizedBox(height: 22),

            // ── 6. RINCIAN BIAYA TRANSAKSI (RECEIPT CARD) ────────────
            _buildSectionHeader(
              icon: Icons.receipt_long_rounded,
              title: 'Rincian Pembayaran',
              subtitle: 'Kalkulasi resmi biaya sewa dan potongan promo',
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 3)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCostRow(
                    label: 'Tarif Sewa (${Formatters.rupiah(safeRate)} x ${booking.durasiJam} jam)',
                    value: Formatters.rupiah(subtotal),
                  ),
                  if (discount > 0) ...[
                    const SizedBox(height: 8),
                    _buildCostRow(
                      label: 'Diskon Voucher (${booking.appliedDiskon?.namaDiskon ?? ""})',
                      value: '-${Formatters.rupiah(discount)}',
                      valueColor: AppColors.success,
                      isBold: true,
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Pembayaran',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                          ),
                          Text('Bebas biaya platform', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        ],
                      ),
                      Text(
                        Formatters.rupiah(total),
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryYellow,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      // ── 7. STICKY BOTTOM CHECKOUT BAR ─────────────────────────────
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Pembayaran', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    Text(
                      Formatters.rupiah(total),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    Text(
                      '${booking.durasiJam} Jam • Tanpa Biaya Admin',
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: (booking.isSubmitting || booking.isCheckingAvailability)
                    ? null
                    : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: booking.isAvailable == false
                      ? const Color(0xFFFEE2E2)
                      : AppColors.primaryYellow,
                  foregroundColor: booking.isAvailable == false
                      ? AppColors.error
                      : AppColors.primaryNavy,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: booking.isAvailable == false
                        ? BorderSide(color: AppColors.error.withValues(alpha: 0.4), width: 1.5)
                        : BorderSide.none,
                  ),
                ),
                child: booking.isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: AppColors.primaryNavy, strokeWidth: 2.2),
                      )
                    : Row(
                        children: [
                          if (booking.isAvailable == false) ...[
                            const Icon(Icons.event_busy_rounded, size: 16, color: AppColors.error),
                            const SizedBox(width: 6),
                            const Text('Slot Terisi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.error)),
                          ] else ...[
                            const Text('Pesan Sekarang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward_rounded, size: 16),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── WIDGET HELPERS ────────────────────────────────────────────────
  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.yellowPale,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.primaryYellow),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryNavy,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickDateChip({
    required String label,
    required DateTime date,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryYellow : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primaryYellow : const Color(0xFFCBD5E1),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryYellow.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check_rounded, size: 13, color: AppColors.primaryNavy),
              const SizedBox(width: 4),
            ],
            Text(
              '$label (${date.day}/${date.month})',
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.primaryNavy : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoucherPill({
    required DiskonModel diskon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.yellowPale,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primaryYellow.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.confirmation_number_outlined, size: 14, color: AppColors.primaryNavy),
            const SizedBox(width: 6),
            Text(
              diskon.namaDiskon,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.primaryYellow,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${diskon.persentaseDiskon.toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostRow({
    required String label,
    required String value,
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? AppColors.primaryNavy,
          ),
        ),
      ],
    );
  }
}
