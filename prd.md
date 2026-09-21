# Product Requirements Document (PRD)
## Smart Space Booking — Aplikasi Reservasi Coworking Space & Workstation

| | |
|---|---|
| **Proyek** | UKK RPL 2026/2027 — Paket B |
| **Kategori** | Mobile App |
| **Platform Target** | Android (Flutter) |
| **Sumber Data** | REST API disediakan panitia (multi-tenant via `x-maker-key`) |
| **Status Dokumen** | Draft v1.0 |

---

## 1. Latar Belakang

Pengelola coworking space membutuhkan sistem reservasi ruangan dan workstation (Personal Desk, Private Office, Meeting Room) secara online agar member/pengunjung bisa memesan tanpa datang langsung, sementara admin pengelola dapat mengatur ketersediaan, promo, dan proses check-in/check-out tamu secara digital.

## 2. Tujuan Produk

1. Memberi member cara cepat untuk melihat ketersediaan space, memesan, dan memantau status reservasinya.
2. Memberi admin pengelola alat untuk mengatur data space, member, diskon, dan transaksi reservasi dari satu aplikasi.
3. Menyediakan bukti reservasi digital (e-ticket + QR code) sebagai alat verifikasi check-in di lokasi.
4. Memberi admin visibilitas pendapatan bulanan untuk pengambilan keputusan operasional.

## 3. Ruang Lingkup

### 3.1 Termasuk (In Scope)
- Autentikasi dua role: **Member** dan **Admin Space**, via API panitia (JWT).
- Konsumsi penuh Kontrak API pada Bagian III soal (Spaces, Diskon, Reservasi, Admin, Upload).
- Alur reservasi end-to-end: pilih space → cek ketersediaan → pilih tanggal/jam/durasi → terapkan promo → checkout → e-ticket.
- Alur operasional admin: konfirmasi status → check-in → check-out.
- Rekapitulasi pendapatan bulanan (ringkas, sesuai response API).

### 3.2 Tidak Termasuk (Out of Scope)
- Pembayaran online (gateway pembayaran) — total_bayar hanya dihitung & ditampilkan, tidak ada proses payment gateway.
- Backend custom — aplikasi murni konsumen API yang disediakan panitia (base URL diberikan saat ujian).
- Notifikasi push / real-time socket.
- Multi-bahasa (i18n).

## 4. Peran Pengguna

| Role | Deskripsi | Sumber Kontrak API |
|---|---|---|
| **Member / Pengunjung** | Memesan space, melihat status & histori, mencetak e-ticket | `role: "member"` |
| **Admin Pengelola Space** | Mengelola member, space, diskon, dan transaksi reservasi lokasi coworking | `role: "admin_space"` |

## 5. User Stories & Fitur

### 5.1 Member / Pengunjung

| # | User Story | Endpoint Terkait |
|---|---|---|
| M1 | Sebagai pengunjung, saya bisa **daftar akun** dengan nama, instansi, no. telp, alamat, username, password, foto profil | `POST /api/auth/register/member` |
| M2 | Sebagai member, saya bisa **login** ke aplikasi | `POST /api/auth/login` |
| M3 | Sebagai member, saya bisa **melihat katalog space** (Personal Desk, Private Office, Meeting Room) lengkap foto, kapasitas, fasilitas, harga/jam | `GET /api/spaces`, `GET /api/spaces/{id}`, `GET /api/spaces/types` |
| M4 | Sebagai member, saya bisa **mengecek ketersediaan** space pada tanggal & jam tertentu sebelum memesan | `GET /api/spaces/availability` |
| M5 | Sebagai member, saya bisa **memesan space** dengan memilih tanggal, jam mulai, durasi, dan kode promo (opsional) | `POST /api/reservasi`, `POST /api/diskon/check` |
| M6 | Sebagai member, saya bisa **melihat status pemesanan saya** (Belum Dikonfirmasi, Disetujui, Aktif, Selesai, Dibatalkan) | `GET /api/reservasi/my` |
| M7 | Sebagai member, saya bisa **melihat histori pemesanan** difilter per bulan | `GET /api/reservasi/my/history` |
| M8 | Sebagai member, saya bisa **mencetak e-ticket** berisi kode reservasi & QR Code untuk check-in | `GET /api/reservasi/{id}/e-ticket` |
| M9 | Sebagai member, saya bisa **membatalkan pemesanan** yang belum aktif | `PATCH /api/reservasi/{id}/cancel` |

### 5.2 Admin Pengelola Space

| # | User Story | Endpoint Terkait |
|---|---|---|
| A1 | Sebagai calon pengelola, saya bisa **register** akun admin + profil lokasi coworking | `POST /api/auth/register/admin-space` |
| A2 | Sebagai admin, saya bisa **login** ke aplikasi pengelolaan | `POST /api/auth/login` |
| A3 | Sebagai admin, saya bisa **update profil lokasi** (nama space, pemilik, alamat, telepon, deskripsi) | `GET/PUT /api/admin/profile` |
| A4 | Sebagai admin, saya bisa **CRUD data member/pelanggan** | `GET/POST/PUT/DELETE /api/admin/members` |
| A5 | Sebagai admin, saya bisa **CRUD data space** (tipe, kapasitas, harga, deskripsi, foto) | `GET/POST/PUT/DELETE /api/admin/spaces` |
| A6 | Sebagai admin, saya bisa **CRUD kode promo/diskon** (nama, persentase, periode berlaku) | `GET/POST/PUT/DELETE /api/admin/diskon` |
| A7 | Sebagai admin, saya bisa **mengonfirmasi & mengubah status pesanan** serta **check-in/check-out** tamu | `PATCH /api/admin/reservasi/{id}/status`, `POST .../check-in`, `POST .../check-out` |
| A8 | Sebagai admin, saya bisa **melihat semua reservasi** dengan filter status & bulan | `GET /api/admin/reservasi` |
| A9 | Sebagai admin, saya bisa **melihat rekapitulasi pendapatan** bulanan per jenis space | `GET /api/admin/reports/monthly` |

## 6. Alur Utama (Key Flows)

### 6.1 Alur Reservasi (Member)
```
Login → Lihat Katalog Space → Pilih Space → Cek Ketersediaan (tanggal/jam/durasi)
→ Input/Pilih Kode Promo (opsional) → Review Ringkasan Harga → Konfirmasi Reservasi
→ Status "Belum Dikonfirmasi" → (menunggu admin) → E-Ticket tersedia setelah "Disetujui"
```

### 6.2 Alur Operasional (Admin)
```
Login → Lihat Semua Reservasi (filter bulan/status) → Konfirmasi Status → "Disetujui"
→ Tamu datang → Scan/Verifikasi QR → Check-In → Status "Aktif"
→ Selesai pakai → Check-Out → Status "Selesai"
```

## 7. Referensi Wireframe

Mengacu pada **Lampiran D** soal UKK:
- **Member (7 layar):** Register, Login, Ketersediaan Space, Pesan Space, Status Pemesanan, Histori Pemesanan, E-Ticket.
- **Admin (9 layar):** Register, Login, Profil Lokasi, Data Member (CRUD), Data Diskon/Promo (CRUD), Kelola Reservasi, Semua Reservasi (Filter Bulan), Rekapitulasi Pendapatan.

## 8. Kebutuhan Non-Fungsional

| Aspek | Kebutuhan |
|---|---|
| Kompatibilitas | Android 10 (Q) ke atas |
| Konektivitas | Membutuhkan koneksi internet stabil (API eksternal) |
| Keamanan | Password di-hash oleh backend; token JWT disimpan aman di perangkat (bukan plaintext) |
| Usability | Alur reservasi maksimal 4–5 langkah dari katalog sampai konfirmasi |
| Performa | Loading list/detail < 2 detik pada koneksi normal |
| Konsistensi Data | Seluruh data terisolasi otomatis oleh backend via header `x-maker-key` |

## 9. Ketergantungan Eksternal

- **Base URL API**: diberikan panitia saat ujian dimulai (lihat dokumentasi API/Postman collection terpisah).
- **Header wajib di setiap request**: `x-maker-key: <app_key>` (didapat dari `POST /api/maker/register`).
- **Header autentikasi endpoint privat**: `Authorization: Bearer <access_token>` hasil `POST /api/auth/login`.
- Format response API standar: `{ status, statusCode, message, data, timestamp }` — aplikasi harus menangani baik format sukses maupun error.

## 10. Kriteria Penerimaan (Definition of Done)

- [ ] Member dapat menyelesaikan seluruh alur register → login → lihat space → reservasi → lihat e-ticket tanpa error.
- [ ] Admin dapat menyelesaikan seluruh alur register → login → CRUD member/space/diskon → konfirmasi → check-in/out → lihat laporan.
- [ ] Seluruh 7 layar Member dan 9 layar Admin pada wireframe tersedia dan berfungsi.
- [ ] Error dari API (400/401/403/404/500) ditampilkan sebagai pesan yang informatif ke pengguna, bukan crash.
- [ ] Aplikasi berjalan pada emulator/device Android 10+ tanpa crash pada alur utama.
- [ ] APK debug tersedia dan bisa langsung dijalankan oleh penguji.

## 11. Asumsi & Batasan

- Panitia menyediakan data awal (space, diskon) di server sehingga aplikasi tidak perlu seeding data sendiri.
- Tidak ada mekanisme refresh token pada Kontrak API — token dianggap berlaku selama sesi ujian.
- Upload foto (member/space) bersifat opsional untuk fitur inti, namun disediakan karena tercantum di Kontrak API (`/api/upload/*`).

## 12. Berkas yang Wajib Dikumpulkan (sesuai Lampiran D)

1. Source code lengkap (folder project Flutter).
2. File APK debug (jika tersedia).
3. Dokumen singkat: framework yang digunakan dan cara menjalankan aplikasi.