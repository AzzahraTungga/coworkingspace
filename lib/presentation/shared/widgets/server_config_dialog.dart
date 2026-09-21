import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import 'custom_button.dart';
import 'custom_text_field.dart';

class ServerConfigDialog extends StatefulWidget {
  const ServerConfigDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const ServerConfigDialog(),
    );
  }

  @override
  State<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends State<ServerConfigDialog> {
  late final TextEditingController _baseUrlController;
  late final TextEditingController _appKeyController;

  // Form Auto Maker
  final _makerNameController = TextEditingController();
  final _makerUsernameController = TextEditingController();
  final _makerEmailController = TextEditingController();
  final _makerPasswordController = TextEditingController();
  bool _showMakerForm = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _baseUrlController = TextEditingController(text: auth.baseUrl);
    _appKeyController = TextEditingController(text: auth.appKey ?? '');
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _appKeyController.dispose();
    _makerNameController.dispose();
    _makerUsernameController.dispose();
    _makerEmailController.dispose();
    _makerPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.yellowLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.tune_rounded, color: AppColors.primaryYellow),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Konfigurasi API & Maker',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      Text(
                        'Multi-Tenancy UKK (x-maker-key)',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 16),

            // Base URL
            CustomTextField(
              controller: _baseUrlController,
              label: 'API Base URL',
              hint: 'https://learn.smktelkom-mlg.sch.id/coworking',
              prefixIcon: Icons.link_rounded,
            ),
            const SizedBox(height: 14),

            // App Key
            CustomTextField(
              controller: _appKeyController,
              label: 'Maker App Key (x-maker-key)',
              hint: 'Masukkan app_key siswa...',
              prefixIcon: Icons.key_rounded,
            ),
            const SizedBox(height: 10),

            // Toggle Buat Maker Baru
            InkWell(
              onTap: () {
                setState(() {
                  _showMakerForm = !_showMakerForm;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Icon(
                      _showMakerForm ? Icons.expand_less : Icons.add_circle_outline,
                      size: 18,
                      color: AppColors.primaryYellow,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _showMakerForm ? 'Sembunyikan Form Maker' : 'Belum punya App Key? Buat Maker Baru',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryYellow,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_showMakerForm) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.bgLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _makerNameController,
                      label: 'Nama Lengkap Siswa',
                      hint: 'Budi Santoso',
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      controller: _makerUsernameController,
                      label: 'Username Maker',
                      hint: 'budisantoso',
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      controller: _makerEmailController,
                      label: 'Email',
                      hint: 'budi@smk.sch.id',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      controller: _makerPasswordController,
                      label: 'Password',
                      hint: 'Password123!',
                      obscureText: true,
                    ),
                    const SizedBox(height: 14),
                    CustomButton(
                      text: 'Daftarkan App Maker',
                      isLoading: auth.isLoading,
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final success = await auth.autoRegisterMaker(
                          name: _makerNameController.text,
                          username: _makerUsernameController.text,
                          email: _makerEmailController.text,
                          password: _makerPasswordController.text,
                        );
                        if (!mounted) return;
                        if (success) {
                          _appKeyController.text = auth.appKey ?? '';
                          setState(() {
                            _showMakerForm = false;
                          });
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Maker berhasil dibuat & App Key tersimpan!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        } else if (auth.errorMessage != null) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(auth.errorMessage!),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Tombol Simpan Konfigurasi
            CustomButton(
              text: 'Simpan Konfigurasi',
              backgroundColor: AppColors.primaryNavy,
              onPressed: () async {
                await auth.setBaseUrl(_baseUrlController.text);
                await auth.setAppKey(_appKeyController.text);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Konfigurasi API berhasil disimpan!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
