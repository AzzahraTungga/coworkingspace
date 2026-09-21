import 'package:flutter/material.dart';
import '../../../data/models/diskon_model.dart';
import '../../../data/models/reservasi_model.dart';
import '../../../data/models/space_model.dart';
import '../../../data/repositories/diskon_repository.dart';
import '../../../data/repositories/reservasi_repository.dart';
import '../../../data/repositories/space_repository.dart';
import '../../../utils/formatters.dart';

class BookingProvider extends ChangeNotifier {
  final ReservasiRepository _reservasiRepo = ReservasiRepository();
  final DiskonRepository _diskonRepo = DiskonRepository();
  final SpaceRepository _spaceRepo = SpaceRepository();

  DateTime _selectedDate = DateTime.now();
  String _selectedTime = '09:00';
  int _durasiJam = 2;

  DiskonModel? _appliedDiskon;
  bool _isCheckingPromo = false;
  String? _promoMessage;
  bool _isPromoSuccess = false;

  List<DiskonModel> _activeDiscounts = [];
  bool _isLoadingDiscounts = false;

  bool _isCheckingAvailability = false;
  bool? _isAvailable;
  String? _availabilityMessage;

  bool _isSubmitting = false;
  String? _errorMessage;

  DateTime get selectedDate => _selectedDate;
  String get selectedTime => _selectedTime;
  int get durasiJam => _durasiJam;
  DiskonModel? get appliedDiskon => _appliedDiskon;
  bool get isCheckingPromo => _isCheckingPromo;
  String? get promoMessage => _promoMessage;
  bool get isPromoSuccess => _isPromoSuccess;
  List<DiskonModel> get activeDiscounts => _activeDiscounts;
  bool get isLoadingDiscounts => _isLoadingDiscounts;
  bool get isCheckingAvailability => _isCheckingAvailability;
  bool? get isAvailable => _isAvailable;
  String? get availabilityMessage => _availabilityMessage;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  void reset() {
    _selectedDate = DateTime.now();
    _selectedTime = '09:00';
    _durasiJam = 2;
    _appliedDiskon = null;
    _promoMessage = null;
    _isPromoSuccess = false;
    _isAvailable = null;
    _availabilityMessage = null;
    _isSubmitting = false;
    _errorMessage = null;
    notifyListeners();
    fetchActiveDiscounts();
  }

  void setDate(DateTime date, [int? idSpace]) {
    _selectedDate = date;
    _isAvailable = null;
    _availabilityMessage = null;
    notifyListeners();
    if (idSpace != null) {
      checkAvailability(idSpace);
    }
  }

  void setTime(String time, [int? idSpace]) {
    _selectedTime = time;
    _isAvailable = null;
    _availabilityMessage = null;
    notifyListeners();
    if (idSpace != null) {
      checkAvailability(idSpace);
    }
  }

  void setDuration(int hours, [int? idSpace]) {
    if (hours > 0 && hours <= 24) {
      _durasiJam = hours;
      _isAvailable = null;
      _availabilityMessage = null;
      notifyListeners();
      if (idSpace != null) {
        checkAvailability(idSpace);
      }
    }
  }

  // KALKULASI HARGA
  double calculateSubtotal(double hargaPerJam) {
    final rate = hargaPerJam > 0 ? hargaPerJam : 25000.0;
    return rate * (_durasiJam > 0 ? _durasiJam : 1);
  }

  double calculateDiscount(double hargaPerJam) {
    if (_appliedDiskon == null) return 0.0;
    final rate = hargaPerJam > 0 ? hargaPerJam : 25000.0;
    final subtotal = calculateSubtotal(rate);
    final raw = _appliedDiskon!.persentaseDiskon;
    if (raw <= 0) return 0.0;

    double disc;
    if (raw <= 1.0) {
      disc = subtotal * raw;
    } else if (raw <= 100.0) {
      disc = subtotal * (raw / 100.0);
    } else {
      disc = raw;
    }

    if (disc >= subtotal) {
      if (raw == 100.0) return subtotal;
      return subtotal * 0.9;
    }
    return disc;
  }

  double calculateTotal(double hargaPerJam) {
    final rate = hargaPerJam > 0 ? hargaPerJam : 25000.0;
    final subtotal = calculateSubtotal(rate);
    final discount = calculateDiscount(rate);
    final total = subtotal - discount;
    return total > 0 ? total : 0.0;
  }

  // CHECK AVAILABILITY
  Future<bool> checkAvailability(int idSpace) async {
    _isCheckingAvailability = true;
    _isAvailable = null;
    _availabilityMessage = null;
    notifyListeners();

    try {
      final res = await _spaceRepo.checkAvailabilityDetail(
        idSpace: idSpace,
        tanggal: Formatters.dateApi(_selectedDate),
        jamMulai: _selectedTime,
        durasiJam: _durasiJam,
      );
      _isAvailable = res['available'] == true;
      _availabilityMessage = res['message']?.toString();
      return _isAvailable!;
    } catch (e) {
      _isAvailable = false;
      _availabilityMessage = 'Gagal memeriksa ketersediaan slot waktu.';
      return false;
    } finally {
      _isCheckingAvailability = false;
      notifyListeners();
    }
  }

  // AMBIL DISKON AKTIF
  Future<void> fetchActiveDiscounts() async {
    _isLoadingDiscounts = true;
    notifyListeners();
    try {
      _activeDiscounts = await _diskonRepo.getActiveDiskon();
    } catch (_) {
      _activeDiscounts = [];
    } finally {
      _isLoadingDiscounts = false;
      notifyListeners();
    }
  }

  // TERAPKAN DISKON LANGSUNG
  void applyDiskonDirect(DiskonModel diskon) {
    _appliedDiskon = diskon;
    _isPromoSuccess = true;
    _promoMessage = 'Promo "${diskon.namaDiskon}" aktif! Diskon ${diskon.persentaseDiskon.toStringAsFixed(0)}%';
    notifyListeners();
  }

  // CEK KODE PROMO
  Future<bool> applyPromoCode(String promoCode) async {
    final clean = promoCode.trim().toUpperCase();
    if (clean.isEmpty) return false;

    _isCheckingPromo = true;
    _promoMessage = null;
    _isPromoSuccess = false;
    notifyListeners();

    try {
      // Cek apakah ada di daftar activeDiscounts yang sudah di-load
      final match = _activeDiscounts.where((d) => d.namaDiskon.trim().toUpperCase() == clean);
      if (match.isNotEmpty) {
        final diskon = match.first;
        _appliedDiskon = diskon;
        _isPromoSuccess = true;
        _promoMessage = 'Promo "${diskon.namaDiskon}" aktif! Diskon ${diskon.persentaseDiskon.toStringAsFixed(0)}%';
        return true;
      }

      final diskon = await _diskonRepo.checkPromo(clean);
      _appliedDiskon = diskon;
      _isPromoSuccess = true;
      _promoMessage = 'Promo "${diskon.namaDiskon}" aktif! Diskon ${diskon.persentaseDiskon.toStringAsFixed(0)}%';
      return true;
    } catch (e) {
      _appliedDiskon = null;
      _isPromoSuccess = false;
      _promoMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isCheckingPromo = false;
      notifyListeners();
    }
  }

  void removePromo() {
    _appliedDiskon = null;
    _promoMessage = null;
    _isPromoSuccess = false;
    notifyListeners();
  }

  // SUBMIT RESERVASI
  Future<ReservasiModel?> submitBooking(SpaceModel space) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. MANDATORY CHECK: Selalu periksa ketersediaan slot ke API terlebih dahulu
      // Memastikan di jam tersebut tidak ada bookingan yang bentrok / terisi
      final checkResult = await _spaceRepo.checkAvailabilityDetail(
        idSpace: space.id,
        tanggal: Formatters.dateApi(_selectedDate),
        jamMulai: _selectedTime,
        durasiJam: _durasiJam,
      );

      _isAvailable = checkResult['available'] == true;
      _availabilityMessage = checkResult['message']?.toString();

      if (_isAvailable != true) {
        _isSubmitting = false;
        _errorMessage = _availabilityMessage ??
            'Slot waktu jam $_selectedTime ($_durasiJam jam) pada tanggal ${Formatters.date(_selectedDate)} sudah ada bookingan lain. Silakan pilih jam atau tanggal lain.';
        notifyListeners();
        return null;
      }

      final safeRate = space.hargaPerJam > 0
          ? space.hargaPerJam
          : (space.tipe.toLowerCase().contains('meeting')
              ? 75000.0
              : (space.tipe.toLowerCase().contains('office') ? 150000.0 : 25000.0));
      final total = calculateTotal(safeRate);
      final subtotal = calculateSubtotal(safeRate);
      final finalPrice = total > 0 ? total : subtotal;

      final dto = CreateReservasiDto(
        idSpace: space.id,
        tanggalReservasi: Formatters.dateApi(_selectedDate),
        jamMulai: _selectedTime,
        durasiJam: _durasiJam,
        totalBayar: finalPrice,
        idDiskon: (_appliedDiskon != null && _appliedDiskon!.id > 0) ? _appliedDiskon!.id : null,
        kodePromo: _appliedDiskon?.namaDiskon,
      );

      final result = await _reservasiRepo.createReservasi(dto);

      // Selalu gunakan finalPrice yang dikonfirmasi oleh pengguna di form
      final enrichedResult = result.copyWith(
        totalBayar: finalPrice,
        space: result.space ?? space,
        durasiJam: _durasiJam,
        diskon: result.diskon ?? _appliedDiskon,
      );

      return enrichedResult;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
