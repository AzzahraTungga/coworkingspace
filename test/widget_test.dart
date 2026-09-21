import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ukk_2026/data/models/space_model.dart';
import 'package:ukk_2026/data/models/diskon_model.dart';
import 'package:ukk_2026/data/models/reservasi_model.dart';
import 'package:ukk_2026/data/models/user_model.dart';
import 'package:ukk_2026/utils/formatters.dart';

class _TestHttpOverrides extends HttpOverrides {}

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  group('Formatters Test', () {
    test('Formatters.rupiah formats number correctly', () {
      expect(Formatters.rupiah(25000), contains('25.000'));
      expect(Formatters.rupiah(0), contains('0'));
    });

    test('Formatters.timeOnly formats time correctly', () {
      expect(Formatters.timeOnly('09:00:00'), '09:00');
    });

    test('Formatters.date formats date beautifully in Indonesian', () {
      expect(Formatters.date('2026-09-19'), '19 September 2026');
      expect(Formatters.dateWithDay('2026-09-19'), 'Sabtu, 19 September 2026');
      expect(Formatters.dateShort('2026-09-19'), '19 Sep 2026');
      expect(Formatters.monthYear(9, 2026), 'September 2026');
    });
  });

  group('Models Test', () {
    test('SpaceModel.fromJson parses correctly', () {
      final json = {
        'id': 1,
        'nama_space': 'Personal Desk Alpha',
        'harga_per_jam': 25000,
        'tipe': 'desk',
        'kapasitas': 1,
        'deskripsi': 'Meja fokus',
      };
      final space = SpaceModel.fromJson(json);
      expect(space.id, 1);
      expect(space.namaSpace, 'Personal Desk Alpha');
      expect(space.tipeFormatted, 'Personal Desk');
      expect(space.hargaPerJam, 25000.0);
    });

    test('DiskonModel.fromJson parses correctly', () {
      final json = {
        'id': 1,
        'nama_diskon': 'DISKONHEMAT20',
        'persentase_diskon': 20,
      };
      final diskon = DiskonModel.fromJson(json);
      expect(diskon.id, 1);
      expect(diskon.namaDiskon, 'DISKONHEMAT20');
      expect(diskon.persentaseDiskon, 20.0);
    });

    test('ReservasiModel.fromJson parses correctly', () {
      final json = {
        'id': 101,
        'kode_reservasi': 'RES-2026-001',
        'id_space': 1,
        'id_member': 2,
        'tanggal_reservasi': '2026-09-15',
        'jam_mulai': '10:00',
        'durasi_jam': 3,
        'total_bayar': 75000,
        'status': 'disetujui',
      };
      final res = ReservasiModel.fromJson(json);
      expect(res.id, 101);
      expect(res.kodeReservasi, 'RES-2026-001');
      expect(res.totalBayar, 75000.0);
      expect(res.status, 'disetujui');
    });

    test('ReservasiModel.fromJson extracts flat space fields and sets displayNamaSpace accurately', () {
      final backendSqlJoinJson = {
        'id': 202,
        'id_space': 5,
        'id_member': 3,
        'nama_space': 'Executive Meeting Room B',
        'tipe': 'meeting_room',
        'kapasitas': 8,
        'harga_per_jam': 75000,
        'foto': 'meeting_b.jpg',
        'tanggal_reservasi': '2026-09-20',
        'jam_mulai': '13:00',
        'durasi_jam': 2,
        'total_bayar': 150000,
        'status': 'belum_dikonfirm',
      };

      final res = ReservasiModel.fromJson(backendSqlJoinJson);
      expect(res.displayNamaSpace, 'Executive Meeting Room B');
      expect(res.displayTipeSpace, 'Meeting Room');
      expect(res.space?.kapasitas, 8);
      expect(res.space?.hargaPerJam, 75000.0);
      expect(res.space?.foto, 'meeting_b.jpg');
    });

    test('ReservasiModel.fromJson unwraps nested reservasi object safely', () {
      final wrappedJson = {
        'reservasi': {
          'id': 303,
          'id_space': 2,
          'nama_space': 'Private Office Suite 1',
          'tipe': 'private_office',
          'total_bayar': 300000,
          'status': 'disetujui',
        }
      };

      final res = ReservasiModel.fromJson(wrappedJson);
      expect(res.id, 303);
      expect(res.displayTitle, 'Private Office Suite 1');
      expect(res.displayTipeSpace, 'Private Office');
    });

    test('ReservasiModel.fromJson and SpaceModel.fromJson match title from backend API', () {
      final apiResponseWithTitle = {
        'id': 404,
        'id_space': 10,
        'title': 'Grand Ballroom Coworking',
        'tipe': 'meeting_room',
        'total_bayar': 500000,
        'status': 'disetujui',
      };

      final res = ReservasiModel.fromJson(apiResponseWithTitle);
      expect(res.title, 'Grand Ballroom Coworking');
      expect(res.displayTitle, 'Grand Ballroom Coworking');

      final spaceApi = {
        'id': 10,
        'title': 'Grand Ballroom Coworking',
        'harga_per_jam': 250000,
        'tipe': 'meeting_room',
      };
      final space = SpaceModel.fromJson(spaceApi);
      expect(space.title, 'Grand Ballroom Coworking');
      expect(space.namaSpace, 'Grand Ballroom Coworking');
    });

    test('ReservasiModel.displayTitle NEVER outputs Space #212 or Space #220', () {
      // Skenario API mentah reservasi tanpa join tabel space
      final rawReservation212 = {
        'id': 212,
        'id_space': 212,
        'tanggal_reservasi': '2026-09-19',
        'jam_mulai': '09:00',
        'durasi_jam': 3,
        'total_bayar': 75000,
        'status': 'selesai',
      };
      final res212 = ReservasiModel.fromJson(rawReservation212);
      expect(res212.displayTitle, isNot(contains('#212')));
      expect(res212.displayTitle, isNot(contains('Space #')));
      expect(res212.displayTitle, 'Personal Desk');

      // Skenario API yang menyediakan nama_space asli dari backend
      final resWithBackendTitle = {
        'id': 220,
        'id_space': 368,
        'nama_space': 'meeting room',
        'tipe': 'meeting_room',
        'durasi_jam': 2,
        'total_bayar': 300000,
        'status': 'dibatalkan',
      };
      final res220 = ReservasiModel.fromJson(resWithBackendTitle);
      expect(res220.displayTitle, 'meeting room');

      // Skenario API dengan string generic 'Space #214' harus ditolak dan dideduksi
      final resGenericTitle = {
        'id': 214,
        'id_space': 214,
        'title': 'Space #214',
        'tipe': 'desk',
        'durasi_jam': 3,
        'total_bayar': 75000,
        'status': 'selesai',
      };
      final res214 = ReservasiModel.fromJson(resGenericTitle);
      expect(res214.displayTitle, isNot(contains('Space #')));
      expect(res214.displayTitle, 'Personal Desk');
    });
  });

  group('Booking Calculation Business Logic', () {
    test('Calculates subtotal and discount correctly', () {
      const hargaPerJam = 25000.0;
      const durasi = 4;
      const subtotal = hargaPerJam * durasi; // 100,000
      expect(subtotal, 100000.0);

      const diskonPersen = 20.0;
      const discount = subtotal * (diskonPersen / 100.0); // 20,000
      expect(discount, 20000.0);

      const total = subtotal - discount; // 80,000
      expect(total, 80000.0);
    });
  });

  group('Photo Endpoint and Image URL Resolution', () {
    test('SpaceModel resolves clean filename to /coworking/uploads/spaces canonical URL', () {
      final space = SpaceModel(
        id: 1,
        namaSpace: 'Focus Room',
        tipe: 'desk',
        hargaPerJam: 20000,
        kapasitas: 1,
        deskripsi: 'Meja nyaman',
        foto: '1789823313359-209517011.png',
      );
      expect(
        space.displayImageUrl,
        'https://learn.smktelkom-mlg.sch.id/coworking/uploads/spaces/1789823313359-209517011.png',
      );
    });

    test('SpaceModel intercepts broken backend URL missing /coworking and fixes it to working endpoint', () {
      final space = SpaceModel(
        id: 2,
        namaSpace: 'Meeting Space',
        tipe: 'meeting_room',
        hargaPerJam: 50000,
        kapasitas: 6,
        deskripsi: 'Ruang rapat',
        fotoUrl: 'http://learn.smktelkom-mlg.sch.id/uploads/spaces/1789823313359-209517011.png',
      );
      expect(
        space.displayImageUrl,
        'https://learn.smktelkom-mlg.sch.id/coworking/uploads/spaces/1789823313359-209517011.png',
      );
    });

    test('SpaceModel preserves third-party external image URLs', () {
      final space = SpaceModel(
        id: 3,
        namaSpace: 'External Photo Desk',
        tipe: 'desk',
        hargaPerJam: 20000,
        kapasitas: 1,
        deskripsi: 'Desk',
        foto: 'https://images.unsplash.com/photo-1527192491265-7e15c55b1ed2?q=80&w=800',
      );
      expect(space.displayImageUrl, 'https://images.unsplash.com/photo-1527192491265-7e15c55b1ed2?q=80&w=800');
    });

    test('UserModel resolves displayFotoUrl and hasCustomFoto correctly', () {
      final userWithPic = UserModel(
        id: 10,
        username: 'zea',
        role: 'member',
        namaMember: 'Zea',
        foto: '1789823313359-member.png',
      );
      expect(userWithPic.hasCustomFoto, true);
      expect(
        userWithPic.displayFotoUrl,
        'https://learn.smktelkom-mlg.sch.id/coworking/uploads/members/1789823313359-member.png',
      );

      final userDefault = UserModel(
        id: 11,
        username: 'no_pic',
        role: 'member',
        namaMember: 'No Pic',
      );
      expect(userDefault.hasCustomFoto, false);
    });
  });
}
