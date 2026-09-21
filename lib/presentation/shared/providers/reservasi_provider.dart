import 'package:flutter/material.dart';
import '../../../data/models/reservasi_model.dart';
import '../../../data/models/e_ticket_model.dart';
import '../../../data/models/space_model.dart';
import '../../../data/models/diskon_model.dart';
import '../../../data/repositories/diskon_repository.dart';
import '../../../data/repositories/reservasi_repository.dart';
import '../../../data/repositories/space_repository.dart';

class ReservasiProvider extends ChangeNotifier {
  final ReservasiRepository _repo = ReservasiRepository();
  final SpaceRepository _spaceRepo = SpaceRepository();
  final DiskonRepository _diskonRepo = DiskonRepository();

  List<ReservasiModel> _myReservations = [];
  List<ReservasiModel> _historyReservations = [];
  List<SpaceModel> _cachedSpaces = [];
  List<DiskonModel> _cachedDiscounts = [];
  final Map<int, ReservasiModel> _confirmedBookings = {};
  ETicketModel? _currentETicket;

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  bool _isLoading = false;
  bool _isLoadingTicket = false;
  String? _errorMessage;

  List<ReservasiModel> get myReservations => _myReservations;
  List<ReservasiModel> get historyReservations => _historyReservations;
  ETicketModel? get currentETicket => _currentETicket;
  int get selectedMonth => _selectedMonth;
  int get selectedYear => _selectedYear;
  bool get isLoading => _isLoading;
  bool get isLoadingTicket => _isLoadingTicket;
  String? get errorMessage => _errorMessage;

  void registerConfirmedBooking(ReservasiModel res) {
    _confirmedBookings[res.id] = res;
    final index = _myReservations.indexWhere((r) => r.id == res.id);
    if (index >= 0) {
      _myReservations[index] = res;
    } else {
      _myReservations.insert(0, res);
    }
    notifyListeners();
  }

  Future<void> _enrichReservations(List<ReservasiModel> list, void Function(List<ReservasiModel>) assign) async {
    if (_cachedSpaces.isEmpty) {
      try {
        _cachedSpaces = await _spaceRepo.getSpaces();
      } catch (_) {
        _cachedSpaces = [];
      }
    }

    if (_cachedDiscounts.isEmpty) {
      try {
        _cachedDiscounts = await _diskonRepo.getActiveDiskon();
      } catch (_) {
        _cachedDiscounts = [];
      }
    }

    final spaceMap = {for (var s in _cachedSpaces) s.id: s};
    final discountMap = {for (var d in _cachedDiscounts) d.id: d};
    final discountNameMap = {for (var d in _cachedDiscounts) d.namaDiskon.trim().toUpperCase(): d};

    // Pastikan setiap reservasi memiliki detail space dari backend
    final processedList = <ReservasiModel>[];
    for (var res in list) {
      // Jika reservasi ini belum memiliki detail space yang valid atau judulnya masih generic
      if (res.space == null ||
          res.space!.namaSpace.trim().isEmpty ||
          ReservasiModel.isGenericTitle(res.space!.namaSpace)) {
        if (res.idSpace > 0) {
          if (spaceMap.containsKey(res.idSpace)) {
            final cached = spaceMap[res.idSpace]!;
            res = res.copyWith(
              space: cached,
              title: (!ReservasiModel.isGenericTitle(cached.title)) ? cached.title : res.title,
            );
          } else {
            try {
              final fetchedSpace = await _spaceRepo.getSpaceDetail(res.idSpace);
              spaceMap[res.idSpace] = fetchedSpace;
              _cachedSpaces.add(fetchedSpace);
              res = res.copyWith(
                space: fetchedSpace,
                title: (!ReservasiModel.isGenericTitle(fetchedSpace.title)) ? fetchedSpace.title : res.title,
              );
            } catch (_) {}
          }
        } else if (res.id > 0) {
          try {
            final detail = await _repo.getReservasiDetail(res.id);
            if (detail.space != null &&
                detail.space!.namaSpace.trim().isNotEmpty &&
                !ReservasiModel.isGenericTitle(detail.space!.namaSpace)) {
              res = res.copyWith(
                space: detail.space,
                idSpace: detail.idSpace > 0 ? detail.idSpace : res.idSpace,
                title: (!ReservasiModel.isGenericTitle(detail.title))
                    ? detail.title
                    : detail.space?.namaSpace,
              );
            }
          } catch (_) {}
        }

        // Jika masih belum ada space valid, cocokkan dari katalog backend berdasarkan tipe & rate
        if (res.space == null ||
            res.space!.namaSpace.trim().isEmpty ||
            ReservasiModel.isGenericTitle(res.space!.namaSpace)) {
          final durasi = res.durasiJam > 0 ? res.durasiJam : 1;
          final rate = res.totalBayar > 0 ? (res.totalBayar / durasi) : 0.0;
          for (var cand in _cachedSpaces) {
            if (rate >= 120000 && cand.tipe.toLowerCase().contains('office')) {
              res = res.copyWith(
                space: cand,
                title: (!ReservasiModel.isGenericTitle(cand.namaSpace)) ? cand.namaSpace : null,
              );
              break;
            } else if (rate >= 50000 && rate < 120000 && cand.tipe.toLowerCase().contains('meeting')) {
              res = res.copyWith(
                space: cand,
                title: (!ReservasiModel.isGenericTitle(cand.namaSpace)) ? cand.namaSpace : null,
              );
              break;
            } else if (rate < 50000 && cand.tipe.toLowerCase().contains('desk')) {
              res = res.copyWith(
                space: cand,
                title: (!ReservasiModel.isGenericTitle(cand.namaSpace)) ? cand.namaSpace : null,
              );
              break;
            }
          }
        }
      }
      processedList.add(res);
    }

    final enriched = processedList.map((res) {
      // 1. Jika ada di daftar confirmed bookings (dibuat langsung di sesi ini), pertahankan rincian pastinya
      final confirmed = _confirmedBookings[res.id];
      if (confirmed != null) {
        return confirmed.copyWith(
          status: res.status,
          checkInTime: res.checkInTime ?? confirmed.checkInTime,
          checkOutTime: res.checkOutTime ?? confirmed.checkOutTime,
          space: (res.space != null &&
                  res.space!.namaSpace.trim().isNotEmpty &&
                  !ReservasiModel.isGenericTitle(res.space!.namaSpace))
              ? res.space
              : confirmed.space,
          title: (res.title != null && !ReservasiModel.isGenericTitle(res.title!))
              ? res.title
              : (confirmed.title ?? confirmed.space?.namaSpace),
        );
      }

      // Prioritaskan space dari objek reservasi jika sudah punya nama
      SpaceModel? s;
      if (res.space != null &&
          res.space!.namaSpace.trim().isNotEmpty &&
          !ReservasiModel.isGenericTitle(res.space!.namaSpace)) {
        s = res.space;
      } else if (spaceMap.containsKey(res.idSpace)) {
        s = spaceMap[res.idSpace];
      } else {
        s = res.space;
      }

      String? effectiveTitle = (res.title != null && !ReservasiModel.isGenericTitle(res.title!))
          ? res.title!.trim()
          : (s != null && s.namaSpace.trim().isNotEmpty && !ReservasiModel.isGenericTitle(s.namaSpace)
              ? s.namaSpace.trim()
              : null);

      var d = res.diskon;
      if (d == null && res.idDiskon != null) {
        d = discountMap[res.idDiskon];
      }
      if (d == null && res.kodePromo != null && res.kodePromo!.isNotEmpty) {
        d = discountNameMap[res.kodePromo!.trim().toUpperCase()];
      }

      final durasi = res.durasiJam > 0 ? res.durasiJam : 1;
      final rate = (s?.hargaPerJam != null && s!.hargaPerJam > 0)
          ? s.hargaPerJam
          : (s?.tipe.toLowerCase().contains('meeting') == true
              ? 75000.0
              : (s?.tipe.toLowerCase().contains('office') == true ? 150000.0 : 25000.0));
      final subtotal = rate * durasi;

      double disc = 0.0;
      if (d != null) {
        final p = d.persentaseDiskon;
        if (p > 0 && p <= 1) {
          disc = subtotal * p;
        } else if (p > 1 && p <= 100) {
          disc = subtotal * (p / 100.0);
        } else if (p > 100) {
          disc = p > subtotal ? subtotal : p;
        }
      }

      double total = res.totalBayar;
      // Jika backend mengembalikan 0 atau belum terpotong diskon
      if (total <= 0) {
        total = (subtotal - disc).clamp(0.0, double.infinity);
      } else if (disc > 0 && total >= subtotal) {
        total = (subtotal - disc).clamp(0.0, double.infinity);
      }

      return res.copyWith(
        space: s ?? res.space,
        diskon: d ?? res.diskon,
        totalBayar: total > 0 ? total : res.totalBayar,
        title: effectiveTitle,
      );
    }).toList();

    assign(enriched);
  }

  // FETCH MY ACTIVE RESERVATIONS
  Future<void> fetchMyReservations() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final rawList = await _repo.getMyReservasi();
      // Gabungkan pemesanan baru yang baru saja dibuat di sesi ini jika belum muncul di response API
      final combinedList = [...rawList];
      for (final confirmed in _confirmedBookings.values) {
        if (!combinedList.any((r) => r.id == confirmed.id)) {
          combinedList.insert(0, confirmed);
        }
      }
      await _enrichReservations(combinedList, (res) => _myReservations = res);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // FETCH HISTORY
  Future<void> fetchHistory({int? month, int? year}) async {
    if (month != null) _selectedMonth = month;
    if (year != null) _selectedYear = year;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final rawList = await _repo.getMyReservasiHistory(
        month: _selectedMonth,
        year: _selectedYear,
      );
      await _enrichReservations(rawList, (res) => _historyReservations = res);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // FETCH E-TICKET
  Future<ETicketModel?> fetchETicket(int reservasiId) async {
    _isLoadingTicket = true;
    _currentETicket = null;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentETicket = await _repo.getETicket(reservasiId);
      return _currentETicket;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return null;
    } finally {
      _isLoadingTicket = false;
      notifyListeners();
    }
  }

  // CANCEL RESERVATION
  Future<bool> cancelReservation(int id) async {
    try {
      await _repo.cancelReservasi(id);
      await fetchMyReservations();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    }
  }
}
