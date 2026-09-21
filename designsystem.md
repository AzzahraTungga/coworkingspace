# Design System — Smart Space Booking
## Sistem Desain "PLAT" (Papan Lokasi & Alokasi Tempat)

| | |
|---|---|
| **Proyek** | UKK RPL 2026/2027 — Paket B |
| **Platform** | Flutter (Mobile, Android) |
| **Status** | Draft v1.0 |

---

## 1. Titik Tolak: Dunia Nyata Coworking Space, Bukan Template SaaS

Sebelum masuk ke token, satu keputusan dasar: aplikasi ini **bukan** dashboard SaaS generik. Subjeknya adalah ruang fisik — meja kerja, ruang rapat, kantor privat — yang dipesan, ditandai terisi/kosong, lalu di-*check-in* dan *check-out* oleh orang sungguhan di lokasi sungguhan.

Referensi visual yang dipakai sebagai jangkar desain:
- **Plakat nomor pintu ruangan** (door plaque) di kantor/hotel.
- **Papan status split-flap** (seperti papan keberangkatan bandara lama) — objek fisik yang secara alami merepresentasikan *perubahan status*, cocok sekali dengan siklus status reservasi (Belum Dikonfirmasi → Disetujui → Aktif → Selesai/Dibatalkan).
- **Direktori lantai gedung** (floor directory) — grid, bukan tumpukan kartu bulat.
- Material coworking space itu sendiri: kayu oak, beton, logam kuningan (brass) pada gagang pintu, dan tanaman hijau di sudut ruangan.

Prinsip turunannya: **status bukan cuma warna pil kecil di pojok kartu — status adalah objek utama**, ditampilkan sebagai "slat" bergaya papan flip, bukan badge rounded generik.

## 2. Kenapa Bukan Default AI (Self-Critique)

Beberapa pola yang sengaja dihindari karena jadi ciri khas desain hasil AI generik:

| Pola generik yang dihindari | Yang dipakai sebagai gantinya |
|---|---|
| Latar krem hangat + aksen terracotta (~`#D97757`) | Latar batu/plester dingin + aksen kuningan (brass) yang benar-benar merujuk ke material hardware coworking |
| Kartu seragam, radius sama rata, shadow abu lembut di semua elemen | Radius berjenjang sesuai fungsi: plakat/status = tajam (0–2px), tombol = sedang, sheet/modal = besar |
| Label ALL CAPS di atas tiap judul, eyebrow text | Nomor ruangan & tipe space sebagai identitas utama, tanpa label dekoratif tambahan |
| Font mono dipakai sebagai gaya untuk semua label data | Mono **hanya** dipakai untuk hal yang secara harfiah adalah kode (kode booking, nomor e-ticket) — karena itu memang datanya, bukan gaya |
| Panah `→` ditempel di akhir tombol/link | Tombol memakai kata kerja aktif tanpa dekorasi tambahan (`Pesan Space`, bukan `Pesan Space →`) |
| Animasi fade+slide-up di tiap section saat load | Satu momen animasi bermakna: transisi *flip* saat status reservasi berubah (mengikuti metafora papan split-flap) |

## 3. Warna

### 3.1 Palet Dasar

| Token | Hex | Peran |
|---|---|---|
| `plaster` | `#EAE6DC` | Latar utama — dinding plester, netral hangat tapi bukan krem klise |
| `concrete` | `#D3CCBD` | Permukaan sekunder, divider, area non-interaktif |
| `ink` | `#211D18` | Teks utama & elemen gelap — graphite hangat, bukan hitam pekat generik |
| `brass` | `#A16A2E` | Aksen primer — CTA, elemen interaktif utama, merujuk gagang pintu/hardware |

### 3.2 Warna Semantik Status Reservasi (Slat Papan Flip)

Status reservasi adalah komponen visual, bukan sekadar teks. Setiap status punya "warna slat" sendiri:

| Status API (`status`) | Label UI | Token | Hex |
|---|---|---|---|
| `belum_dikonfirm` | Menunggu | `oak` | `#C79A56` |
| `disetujui` | Disetujui | `brass` | `#A16A2E` |
| `aktif` | Aktif / Digunakan | `moss` | `#4B6B4A` |
| `selesai` | Selesai | `concrete-dark` | `#8C8575` |
| `dibatalkan` | Dibatalkan | `brick` | `#B54A34` |

> Aturan: warna semantik ini **hanya** dipakai untuk status reservasi/okupansi — tidak dipakai ulang sebagai warna dekoratif di tempat lain, supaya artinya tetap konsisten (mata pengguna belajar: brick = batal, di mana pun muncul).

### 3.3 Kontras & Aksesibilitas
- `ink` di atas `plaster` → rasio kontras ~13:1 (aman untuk teks kecil).
- Teks putih di atas `brass`/`moss`/`brick` wajib dicek ≥ 4.5:1; gunakan `#FFFBF5` (bukan `#FFFFFF` murni) agar tetap dalam keluarga warna hangat.

## 4. Tipografi

| Peran | Font | Alasan |
|---|---|---|
| Display / Judul layar | **Space Grotesk** | Karakter geometris-arsitektural, angka besar terasa seperti nomor ruangan pada plakat — bukan pilihan default (Inter/Poppins) |
| Body / UI umum | **IBM Plex Sans** | Humanis, sangat terbaca di ukuran kecil, mendukung karakter Indonesia dengan baik |
| Kode/data literal (kode booking, nomor e-ticket) | **IBM Plex Mono** | Dipakai **karena datanya memang kode** (`BOOK-20260830-0012`), bukan gaya label |

### 4.1 Skala Tipe

| Level | Font | Ukuran / Line-height | Weight | Contoh Pemakaian |
|---|---|---|---|---|
| Display | Space Grotesk | 32 / 38 | 600 | Nama space di layar detail ("Meeting Room Alpha") |
| H1 | Space Grotesk | 24 / 30 | 600 | Judul layar ("Ketersediaan Space") |
| H2 | Space Grotesk | 18 / 24 | 500 | Judul section ("Ringkasan Pembayaran") |
| Body | IBM Plex Sans | 15 / 22 | 400 | Deskripsi, paragraf |
| Body Strong | IBM Plex Sans | 15 / 22 | 600 | Nilai penting (harga, total bayar) |
| Caption | IBM Plex Sans | 13 / 18 | 400 | Metadata sekunder (instansi, telp) |
| Code | IBM Plex Mono | 14 / 20 | 500 | Kode booking, nomor e-ticket, QR payload |

Aturan: **tidak ada teks all-caps** untuk label kecuali status pada slat papan flip (di situ all-caps dipakai secara sadar karena meniru huruf cetak fisik papan flip asli, bukan kebiasaan default).

## 5. Grid & Spacing

- Unit dasar: **8px** (`space-1 = 8`, `space-2 = 16`, `space-3 = 24`, `space-4 = 32`).
- Grid katalog space memakai **grid 2 kolom** menyerupai denah lantai (bukan list vertikal generik), setiap sel proporsional dengan tipe space:

```
┌───────────────┬───────────────┐
│  DESK #01     │  DESK #02     │   ← Personal Desk: sel kecil
├───────────────┴───────────────┤
│      MEETING ROOM — ALPHA     │   ← Meeting Room: sel lebar (span 2 kolom)
├───────────────┬───────────────┤
│ PRIVATE OFFICE│  DESK #03     │
└───────────────┴───────────────┘
```

- Margin layar: 20px kiri/kanan. Line-length body maksimal ~65 karakter pada layar lebar (tablet).

## 6. Radius & Elevasi (bukan satu radius untuk semua)

| Elemen | Radius | Shadow |
|---|---|---|
| Plakat status (flip tag) | 2px | Tidak ada — datar seperti slat fisik |
| Kartu space (plaque card) | 4px | Hairline border `1px solid concrete`, tanpa shadow |
| Tombol primer | 8px | Tidak ada shadow default; shadow hanya muncul saat *pressed* (efek "ditekan") |
| Bottom sheet / modal | 20px (top corners) | Shadow tunggal, dipakai **hanya** di elemen yang benar mengambang di atas konten |

Aturan tegas: **shadow abu lembut generik tidak dipakai di kartu list.** Pemisah antar kartu memakai hairline border, seperti garis pada denah arsitektur — bukan efek "melayang".

## 7. Motion

Satu momen animasi yang disengaja: **flip transition** pada perubahan status reservasi, meniru papan split-flap fisik — potongan atas slat berputar turun untuk menampilkan status baru saat admin mengubah status atau saat member membuka layar status pemesanan.

- Durasi: 280ms, curve `easeInOutCubic`.
- Dipicu oleh aksi nyata (admin menekan "Setujui", "Check-In", "Check-Out") — bukan animasi otomatis saat halaman dimuat.
- Elemen lain (list, form) **tidak** memakai fade-slide-up saat render. Transisi antar layar pakai `go_router` default page transition standar Android (shared-axis), tidak dikustom berlebihan.

## 8. Komponen Kunci

### 8.1 Flip Status Tag
Pengganti "badge/pill" generik. Bentuk persegi tajam (radius 2px), warna sesuai tabel §3.2, teks all-caps IBM Plex Sans 12px/bold, dengan garis tengah horizontal tipis (`1px`, warna latar sedikit lebih gelap) yang membelah tag jadi dua — meniru sambungan fisik slat papan flip.

### 8.2 Space Plaque Card
Kartu katalog space: hairline border, radius 4px, foto space di atas (aspect 4:3), lalu blok info bawah berisi **nomor/nama space besar (Space Grotesk)**, tipe, kapasitas (ikon kursi + angka, bukan teks "Kapasitas: 2 orang"), dan harga per jam rata kanan dengan Body Strong.

### 8.3 Booking Summary Panel
Bukan "card ringkasan" biasa — dibuat menyerupai **struk/nota fisik**: garis putus-putus (dashed) di atas total, angka harga rata kanan tabular figures, dan kode booking dalam IBM Plex Mono di bagian bawah seperti nomor struk.

### 8.4 Tombol
- Primer: latar `brass`, teks `#FFFBF5`, kata kerja aktif spesifik: `Pesan Space`, `Setujui Reservasi`, `Check-In Tamu` — **bukan** "Submit"/"Confirm" generik, dan **tanpa** panah `→`.
- Sekunder: outline `1px ink`, latar transparan.
- Destruktif (Batalkan): outline `brick`, teks `brick`.

## 9. Voice & Microcopy

| Situasi | Hindari | Pakai |
|---|---|---|
| Tombol simpan | "Submit" | "Simpan Reservasi" |
| Setelah berhasil pesan | "Success!" | "Reservasi dibuat. Menunggu konfirmasi admin." |
| List reservasi kosong | "No data available" | "Belum ada reservasi. Pilih space dan pesan yang pertama." |
| Error jaringan | "An error occurred" | "Tidak bisa terhubung ke server. Periksa koneksi internet, lalu coba lagi." |
| Error dari API (400) | Pesan generik custom | Tampilkan langsung `message` dari response API — bahasanya sudah ditulis oleh backend untuk situasi spesifik |

Prinsip: nama aksi konsisten dari tombol sampai ke notifikasi hasil — tombol "Check-In" menghasilkan toast "Check-in berhasil", bukan "Diproses" atau istilah lain.

## 10. Implementasi Token di Flutter

```dart
// lib/core/theme/app_colors.dart
class AppColors {
  static const plaster      = Color(0xFFEAE6DC);
  static const concrete     = Color(0xFFD3CCBD);
  static const concreteDark = Color(0xFF8C8575);
  static const ink          = Color(0xFF211D18);
  static const brass        = Color(0xFFA16A2E);
  static const oak          = Color(0xFFC79A56);
  static const moss         = Color(0xFF4B6B4A);
  static const brick        = Color(0xFFB54A34);
  static const onAccent     = Color(0xFFFFFBF5);
}

// lib/core/theme/app_text_theme.dart
final appTextTheme = TextTheme(
  displayMedium: GoogleFonts.spaceGrotesk(fontSize: 32, height: 38/32, fontWeight: FontWeight.w600),
  headlineLarge: GoogleFonts.spaceGrotesk(fontSize: 24, height: 30/24, fontWeight: FontWeight.w600),
  headlineSmall: GoogleFonts.spaceGrotesk(fontSize: 18, height: 24/18, fontWeight: FontWeight.w500),
  bodyLarge:     GoogleFonts.ibmPlexSans(fontSize: 15, height: 22/15, fontWeight: FontWeight.w400),
  labelLarge:    GoogleFonts.ibmPlexSans(fontSize: 15, height: 22/15, fontWeight: FontWeight.w600),
  bodySmall:     GoogleFonts.ibmPlexSans(fontSize: 13, height: 18/13, fontWeight: FontWeight.w400),
  bodyMedium:    GoogleFonts.ibmPlexMono(fontSize: 14, height: 20/14, fontWeight: FontWeight.w500), // kode/data literal
);

// Mapping status → warna slat
const statusColorMap = {
  'belum_dikonfirm': AppColors.oak,
  'disetujui':        AppColors.brass,
  'aktif':            AppColors.moss,
  'selesai':          AppColors.concreteDark,
  'dibatalkan':       AppColors.brick,
};
```

Dependency yang dibutuhkan di `pubspec.yaml`: `google_fonts` (untuk Space Grotesk, IBM Plex Sans, IBM Plex Mono).

## 11. Checklist Sebelum Merilis Satu Layar

- [ ] Tidak ada shadow abu generik di kartu list — hanya hairline border.
- [ ] Radius elemen sesuai fungsi (§6), bukan satu angka untuk semua.
- [ ] Status reservasi ditampilkan sebagai Flip Status Tag, bukan pill warna sembarang.
- [ ] Tombol memakai kata kerja aktif spesifik, tanpa panah `→`.
- [ ] Font mono hanya dipakai untuk data yang literal berupa kode.
- [ ] Tidak ada label ALL CAPS dekoratif di atas judul section.
- [ ] Copy kosong/error ditulis dalam suara aplikasi (jelas, memberi arah), bukan pesan generik sistem.