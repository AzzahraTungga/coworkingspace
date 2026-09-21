import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../utils/validators.dart';
import '../../shared/providers/admin_provider.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/custom_text_field.dart';

class AdminProfileEditScreen extends StatefulWidget {
  const AdminProfileEditScreen({super.key});

  @override
  State<AdminProfileEditScreen> createState() => _AdminProfileEditScreenState();
}

class _AdminProfileEditScreenState extends State<AdminProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _coworkingNameCtrl;
  late final TextEditingController _ownerNameCtrl;
  late final TextEditingController _telpCtrl;

  @override
  void initState() {
    super.initState();
    final admin = context.read<AdminProvider>();
    final profile = admin.coworkingProfile;
    _coworkingNameCtrl = TextEditingController(text: profile?.namaCoworking ?? '');
    _ownerNameCtrl = TextEditingController(text: profile?.namaPemilik ?? '');
    _telpCtrl = TextEditingController(text: profile?.telp ?? '');
  }

  @override
  void dispose() {
    _coworkingNameCtrl.dispose();
    _ownerNameCtrl.dispose();
    _telpCtrl.dispose();
    super.dispose();
  }

  void _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final admin = context.read<AdminProvider>();
    final success = await admin.updateProfile(
      namaCoworking: _coworkingNameCtrl.text,
      namaPemilik: _ownerNameCtrl.text,
      telp: _telpCtrl.text,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil lokasi coworking berhasil diperbarui!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } else if (mounted && admin.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(admin.errorMessage!),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primaryNavy),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Edit Profil Lokasi',
          style: TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Informasi Lokasi Coworking',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
              ),
              const SizedBox(height: 4),
              const Text(
                'Perbarui nama usaha, nama penanggung jawab, dan nomor telepon kontak lokasi.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 22),

              CustomTextField(
                controller: _coworkingNameCtrl,
                label: 'Nama Lokasi Coworking',
                hint: 'Moklet Hub Coworking',
                prefixIcon: Icons.apartment_rounded,
                validator: (v) => Validators.requiredField(v, 'Nama Coworking'),
              ),
              const SizedBox(height: 14),

              CustomTextField(
                controller: _ownerNameCtrl,
                label: 'Nama Pemilik / Pengelola',
                hint: 'Ahmad Bidin, S.Kom',
                prefixIcon: Icons.badge_outlined,
                validator: (v) => Validators.requiredField(v, 'Nama Pemilik'),
              ),
              const SizedBox(height: 14),

              CustomTextField(
                controller: _telpCtrl,
                label: 'No. Telepon / Hotline',
                hint: '081298765432',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: Validators.phone,
              ),
              const SizedBox(height: 26),

              CustomButton(
                text: 'Simpan Perubahan',
                backgroundColor: AppColors.primaryNavy,
                isLoading: admin.isLoading,
                onPressed: _handleSave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
