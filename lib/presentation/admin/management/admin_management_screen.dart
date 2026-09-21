import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/space_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/diskon_model.dart';
import '../../../utils/formatters.dart';
import '../../shared/providers/admin_provider.dart';
import '../../shared/providers/space_provider.dart';
import '../../shared/widgets/custom_text_field.dart';

class AdminManagementScreen extends StatefulWidget {
  final int initialTabIndex;
  const AdminManagementScreen({super.key, this.initialTabIndex = 0});

  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTabIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final admin = context.read<AdminProvider>();
      admin.fetchSpaces();
      admin.fetchMembers();
      admin.fetchDiskon();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ----------------------------------------------------
  // DIALOG CRUD SPACE
  // ----------------------------------------------------
  void _showSpaceDialog([SpaceModel? existingSpace]) {
    final isEdit = existingSpace != null;
    final nameCtrl = TextEditingController(text: existingSpace?.namaSpace ?? '');
    final priceCtrl = TextEditingController(text: existingSpace != null ? existingSpace.hargaPerJam.toStringAsFixed(0) : '');
    final capacityCtrl = TextEditingController(text: existingSpace != null ? existingSpace.kapasitas.toString() : '1');
    final descCtrl = TextEditingController(text: existingSpace?.deskripsi ?? '');
    final fotoCtrl = TextEditingController(text: existingSpace?.foto ?? existingSpace?.fotoUrl ?? '');
    String selectedTipe = existingSpace?.tipe ?? 'desk';
    File? pickedImageFile;
    bool isUploading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final previewUrl = existingSpace?.displayImageUrl;

          String resolvePreviewUrl() {
            if (pickedImageFile != null) return '';
            final text = fotoCtrl.text.trim();
            if (text.isNotEmpty) {
              final mock = SpaceModel(
                id: 0,
                namaSpace: '',
                tipe: selectedTipe,
                hargaPerJam: 0,
                kapasitas: 0,
                deskripsi: '',
                foto: text,
              );
              return mock.displayImageUrl;
            }
            if (previewUrl != null && previewUrl.isNotEmpty) {
              return previewUrl;
            }
            return '';
          }

          Future<void> pickImage(ImageSource source) async {
            try {
              final picker = ImagePicker();
              final picked = await picker.pickImage(
                source: source,
                maxWidth: 1200,
                maxHeight: 1200,
                imageQuality: 85,
              );
              if (picked != null) {
                setDialogState(() {
                  pickedImageFile = File(picked.path);
                  fotoCtrl.text = picked.name;
                });
              }
            } catch (e) {
              debugPrint('Error picking image: $e');
            }
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              isEdit ? 'Edit Data Space' : 'Tambah Space Baru',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- AREA INPUT / PREVIEW FOTO ---
                  const Text(
                    'Foto Ruangan / Space',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.primaryNavy),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    height: 140,
                    decoration: BoxDecoration(
                      color: AppColors.yellowPale,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (pickedImageFile != null)
                          Image.file(
                            pickedImageFile!,
                            fit: BoxFit.cover,
                          )
                        else if (resolvePreviewUrl().isNotEmpty)
                          Image.network(
                            resolvePreviewUrl(),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.broken_image_rounded, color: AppColors.textMuted, size: 36),
                            ),
                          )
                        else
                          const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined, color: AppColors.textMuted, size: 36),
                                SizedBox(height: 4),
                                Text(
                                  'Belum ada foto',
                                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        if (pickedImageFile != null || fotoCtrl.text.isNotEmpty)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: InkWell(
                              onTap: () {
                                setDialogState(() {
                                  pickedImageFile = null;
                                  fotoCtrl.clear();
                                });
                              },
                              child: CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.black.withValues(alpha: 0.6),
                                child: const Icon(Icons.close, size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isUploading ? null : () => pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_outlined, size: 16),
                          label: const Text('Galeri', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryNavy,
                            side: const BorderSide(color: AppColors.primaryNavy),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isUploading ? null : () => pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_outlined, size: 16),
                          label: const Text('Kamera', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryNavy,
                            side: const BorderSide(color: AppColors.primaryNavy),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  CustomTextField(
                    controller: fotoCtrl,
                    label: 'Atau Masukkan Nama/URL Foto',
                    hint: 'desk_01.jpg atau https://...',
                    prefixIcon: Icons.image_outlined,
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 8),

                  CustomTextField(controller: nameCtrl, label: 'Nama Space', hint: 'Personal Desk Alpha 01'),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedTipe,
                    decoration: InputDecoration(
                      labelText: 'Tipe Space',
                      filled: true,
                      fillColor: AppColors.yellowPale,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'desk', child: Text('Personal Desk')),
                      DropdownMenuItem(value: 'meeting_room', child: Text('Meeting Room')),
                      DropdownMenuItem(value: 'private_office', child: Text('Private Office')),
                    ],
                    onChanged: (v) {
                      if (v != null) setDialogState(() => selectedTipe = v);
                    },
                  ),
                  const SizedBox(height: 10),
                  CustomTextField(
                    controller: priceCtrl,
                    label: 'Harga per Jam (Rp)',
                    hint: '25000',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  CustomTextField(
                    controller: capacityCtrl,
                    label: 'Kapasitas (Orang)',
                    hint: '1',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  CustomTextField(
                    controller: descCtrl,
                    label: 'Deskripsi Fasilitas',
                    hint: 'Deskripsi ruangan & fasilitas...',
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isUploading ? null : () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: isUploading
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final admin = context.read<AdminProvider>();

                        setDialogState(() => isUploading = true);

                        String? fotoResult;
                        // 1. Upload jika ada file baru yang dipilih
                        if (pickedImageFile != null) {
                          fotoResult = await admin.uploadSpacePhoto(pickedImageFile!);
                          if (fotoResult == null || fotoResult.isEmpty) {
                            setDialogState(() => isUploading = false);
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(admin.errorMessage ?? 'Gagal mengunggah foto space'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                            return;
                          }
                        }

                        final data = <String, dynamic>{
                          'nama_space': nameCtrl.text.trim(),
                          'tipe': selectedTipe,
                          'harga_per_jam': double.tryParse(priceCtrl.text) ?? 20000,
                          'kapasitas': int.tryParse(capacityCtrl.text) ?? 1,
                          'deskripsi': descCtrl.text.trim(),
                        };

                        if (fotoResult != null && fotoResult.isNotEmpty) {
                          data['foto'] = fotoResult;
                        } else if (fotoCtrl.text.trim().isNotEmpty) {
                          String clean = fotoCtrl.text.trim();
                          if (clean.contains('learn.smktelkom-mlg.sch.id')) {
                            if (clean.contains('?')) clean = clean.split('?').first;
                            if (clean.contains('/')) clean = clean.split('/').last;
                            if (clean.contains('\\')) clean = clean.split('\\').last;
                          }
                          data['foto'] = clean;
                        }

                        bool success;
                        if (isEdit) {
                          success = await admin.updateSpace(existingSpace.id, data);
                        } else {
                          success = await admin.createSpace(data);
                        }

                        // Evict Flutter Image Cache agar perubahan foto langsung tampil tanpa menampilkan gambar lama
                        PaintingBinding.instance.imageCache.clear();
                        PaintingBinding.instance.imageCache.clearLiveImages();

                        // Refresh juga SpaceProvider agar katalog member langsung ter-update
                        try {
                          if (context.mounted) {
                            context.read<SpaceProvider>().fetchSpaces();
                          }
                        } catch (_) {}

                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(success ? 'Space berhasil disimpan!' : (admin.errorMessage ?? 'Gagal menyimpan space')),
                            backgroundColor: success ? AppColors.success : AppColors.error,
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryNavy),
                child: isUploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Simpan', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  // ----------------------------------------------------
  // DIALOG CRUD MEMBER
  // ----------------------------------------------------
  void _showMemberDialog([UserModel? existingMember]) {
    final isEdit = existingMember != null;
    final nameCtrl = TextEditingController(text: existingMember?.namaMember ?? '');
    final instansiCtrl = TextEditingController(text: existingMember?.instansi ?? '');
    final telpCtrl = TextEditingController(text: existingMember?.telp ?? '');
    final alamatCtrl = TextEditingController(text: existingMember?.alamat ?? '');
    final userCtrl = TextEditingController(text: existingMember?.username ?? '');
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isEdit ? 'Edit Data Member' : 'Tambah Member Baru',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(controller: nameCtrl, label: 'Nama Lengkap', hint: 'Budi Raharjo'),
              const SizedBox(height: 10),
              CustomTextField(controller: instansiCtrl, label: 'Instansi', hint: 'SMK Telkom Malang'),
              const SizedBox(height: 10),
              CustomTextField(controller: telpCtrl, label: 'No. Telepon', hint: '085712345678', keyboardType: TextInputType.phone),
              const SizedBox(height: 10),
              CustomTextField(controller: alamatCtrl, label: 'Alamat', hint: 'Jl. Danau Ranau No. 1'),
              if (!isEdit) ...[
                const SizedBox(height: 10),
                CustomTextField(controller: userCtrl, label: 'Username', hint: 'user_budi'),
                const SizedBox(height: 10),
                CustomTextField(controller: passCtrl, label: 'Password', hint: 'Secret123!', obscureText: true),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final admin = context.read<AdminProvider>();
              final data = <String, dynamic>{
                'nama_member': nameCtrl.text.trim(),
                'instansi': instansiCtrl.text.trim(),
                'telp': telpCtrl.text.trim(),
                'alamat': alamatCtrl.text.trim(),
              };
              if (!isEdit) {
                data['username'] = userCtrl.text.trim();
                data['password'] = passCtrl.text;
              }

              bool success;
              if (isEdit) {
                success = await admin.updateMember(existingMember.id, data);
              } else {
                success = await admin.createMember(data);
              }

              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
              messenger.showSnackBar(
                SnackBar(
                  content: Text(success ? 'Member berhasil disimpan!' : 'Gagal menyimpan member'),
                  backgroundColor: success ? AppColors.success : AppColors.error,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryNavy),
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // DIALOG CRUD DISKON
  // ----------------------------------------------------
  void _showDiskonDialog([DiskonModel? existingDiskon]) {
    final isEdit = existingDiskon != null;
    final nameCtrl = TextEditingController(text: existingDiskon?.namaDiskon ?? '');
    final percentCtrl = TextEditingController(
      text: existingDiskon != null ? existingDiskon.persentaseDiskon.toStringAsFixed(0) : '20',
    );
    DateTime startDate = DateTime.now().subtract(const Duration(days: 1));
    DateTime endDate = DateTime.now().add(const Duration(days: 60));

    if (existingDiskon?.tanggalAwal != null) {
      startDate = DateTime.tryParse(existingDiskon!.tanggalAwal!) ?? startDate;
    }
    if (existingDiskon?.tanggalAkhir != null) {
      endDate = DateTime.tryParse(existingDiskon!.tanggalAkhir!) ?? endDate;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            isEdit ? 'Edit Kode Promo' : 'Tambah Promo Baru',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextField(
                  controller: nameCtrl,
                  label: 'Kode Promo (Nama Diskon)',
                  hint: 'Contoh: PROMOAGUSTUS',
                  prefixIcon: Icons.local_offer_outlined,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: percentCtrl,
                  label: 'Persentase Diskon (1 - 100%)',
                  hint: '20',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.percent_rounded,
                ),
                const SizedBox(height: 14),
                const Text(
                  'Periode Berlaku',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: DateTime(2025),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setDialogState(() => startDate = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.yellowPale,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Mulai', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                              Text(
                                Formatters.dateShort(startDate),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: endDate,
                            firstDate: DateTime(2025),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setDialogState(() => endDate = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.yellowPale,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Berakhir', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                              Text(
                                Formatters.dateShort(endDate),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final admin = context.read<AdminProvider>();

                final parsedPercent = int.tryParse(percentCtrl.text.trim()) ??
                    (double.tryParse(percentCtrl.text.trim())?.round() ?? 20);

                final startIso = "${DateTime.utc(startDate.year, startDate.month, startDate.day, 0, 0, 0).toIso8601String().split('.').first}Z";
                final endIso = "${DateTime.utc(endDate.year, endDate.month, endDate.day, 23, 59, 59).toIso8601String().split('.').first}Z";

                final data = <String, dynamic>{
                  'nama_diskon': nameCtrl.text.trim().toUpperCase(),
                  'persentase_diskon': parsedPercent,
                  'tanggal_akhir': endIso,
                };
                if (!isEdit) {
                  data['tanggal_awal'] = startIso;
                }

                bool success;
                if (isEdit) {
                  success = await admin.updateDiskon(existingDiskon.id, data);
                } else {
                  success = await admin.createDiskon(data);
                }

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Promo berhasil disimpan!' : (admin.errorMessage ?? 'Gagal menyimpan promo')),
                    backgroundColor: success ? AppColors.success : AppColors.error,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryNavy),
              child: const Text('Simpan', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primaryNavy),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'Kelola Master Data',
          style: TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryNavy,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primaryYellow,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(text: 'Space (${admin.spaces.length})'),
            Tab(text: 'Member (${admin.members.length})'),
            Tab(text: 'Diskon (${admin.diskonList.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. TAB SPACES
          _buildSpaceTab(admin),

          // 2. TAB MEMBERS
          _buildMemberTab(admin),

          // 3. TAB DISKON
          _buildDiskonTab(admin),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryYellow,
        onPressed: () {
          if (_tabController.index == 0) {
            _showSpaceDialog();
          } else if (_tabController.index == 1) {
            _showMemberDialog();
          } else {
            _showDiskonDialog();
          }
        },
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildSpaceTab(AdminProvider admin) {
    return RefreshIndicator(
      onRefresh: () async => admin.fetchSpaces(),
      color: AppColors.primaryYellow,
      child: admin.spaces.isEmpty
          ? const Center(child: Text('Belum ada data space.'))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: admin.spaces.length,
              itemBuilder: (context, index) {
                final sp = admin.spaces[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        sp.displayImageUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 56,
                          height: 56,
                          color: AppColors.yellowPale,
                          child: const Icon(Icons.meeting_room_outlined, color: AppColors.primaryYellow),
                        ),
                      ),
                    ),
                    title: Text(sp.namaSpace, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text('${sp.tipeFormatted} • ${Formatters.rupiah(sp.hargaPerJam)}/jam • ${sp.kapasitas} org'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: AppColors.primaryNavy, size: 20),
                          onPressed: () => _showSpaceDialog(sp),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Hapus Space?'),
                                content: Text('Hapus ${sp.namaSpace}?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                    child: const Text('Hapus', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await admin.deleteSpace(sp.id);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildMemberTab(AdminProvider admin) {
    return RefreshIndicator(
      onRefresh: () async => admin.fetchMembers(),
      color: AppColors.primaryYellow,
      child: admin.members.isEmpty
          ? const Center(child: Text('Belum ada data member.'))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: admin.members.length,
              itemBuilder: (context, index) {
                final mem = admin.members[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(mem.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text('${mem.instansi ?? "-"} • Telp: ${mem.telp ?? "-"}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: AppColors.primaryNavy, size: 20),
                          onPressed: () => _showMemberDialog(mem),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Hapus Member?'),
                                content: Text('Hapus member ${mem.displayName}?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                    child: const Text('Hapus', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await admin.deleteMember(mem.id);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildDiskonTab(AdminProvider admin) {
    return RefreshIndicator(
      onRefresh: () async => admin.fetchDiskon(),
      color: AppColors.primaryYellow,
      child: admin.diskonList.isEmpty
          ? const Center(child: Text('Belum ada kode promo aktif.'))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: admin.diskonList.length,
              itemBuilder: (context, index) {
                final d = admin.diskonList[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.yellowLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.local_offer_rounded, color: AppColors.primaryYellow, size: 20),
                    ),
                    title: Row(
                      children: [
                        Text(d.namaDiskon, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.yellowLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${d.persentaseDiskon.toStringAsFixed(0)}% OFF',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryYellow,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      d.tanggalAkhir != null
                          ? 'Berlaku s/d ${Formatters.dateShort(DateTime.tryParse(d.tanggalAkhir!) ?? DateTime.now())}'
                          : 'ID #${d.id} • Potongan ${d.persentaseDiskon.toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: AppColors.primaryNavy, size: 20),
                          onPressed: () => _showDiskonDialog(d),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Hapus Promo?'),
                                content: Text('Hapus kode promo ${d.namaDiskon}?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                    child: const Text('Hapus', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await admin.deleteDiskon(d.id);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
