import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../utils/validators.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/custom_text_field.dart';

class RegisterAdminScreen extends StatefulWidget {
  const RegisterAdminScreen({super.key});

  @override
  State<RegisterAdminScreen> createState() => _RegisterAdminScreenState();
}

class _RegisterAdminScreenState extends State<RegisterAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _coworkingNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _telpController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _coworkingNameController.dispose();
    _ownerNameController.dispose();
    _telpController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.registerAdminSpace(
      username: _usernameController.text,
      password: _passwordController.text,
      namaCoworking: _coworkingNameController.text,
      namaPemilik: _ownerNameController.text,
      telp: _telpController.text,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Space berhasil didaftarkan! Silakan masuk.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      context.canPop() ? context.pop() : context.go('/login');
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: CustomScrollView(
        slivers: [
          // ── App bar — aksen kuning untuk admin ─────────────────
          SliverAppBar(
            expandedHeight: 170,
            pinned: true,
            backgroundColor: AppColors.primaryNavy,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/login'),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(56, 0, 16, 16),
              title: const Text(
                'Daftar Admin Space',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: AppColors.primaryNavy),

                  // Aksen garis kuning horizontal
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      height: 3,
                      color: AppColors.primaryYellow,
                    ),
                  ),

                  // Ikon besar dekoratif
                  Positioned(
                    right: 20,
                    top: 50,
                    child: Icon(
                      Icons.storefront_outlined,
                      size: 72,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),

                  // Teks sub-header
                  Positioned(
                    left: 16,
                    top: 72,
                    child: Text(
                      'Kelola coworking space kamu\nsecara digital dari mana saja.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ─ Info card ─────────────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.yellowLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border(
                            left: BorderSide(
                              color: AppColors.primaryYellow,
                              width: 3,
                            ),
                          ),
                        ),
                        child: const Text(
                          'Data coworking kamu akan digunakan untuk mengelola reservasi dan profil space secara publik.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ─ Grup 1: Info Space ────────────────────
                      _SectionHeader(
                        number: '01',
                        title: 'Info Coworking Space',
                        subtitle: 'Data publik bisnis kamu',
                        accent: AppColors.primaryYellow,
                      ),
                      const SizedBox(height: 14),

                      CustomTextField(
                        controller: _coworkingNameController,
                        label: 'Nama Coworking Space',
                        hint: 'Moklet Hub Coworking',
                        prefixIcon: Icons.apartment_outlined,
                        validator: (v) =>
                            Validators.requiredField(v, 'Nama Coworking'),
                      ),
                      const SizedBox(height: 12),

                      CustomTextField(
                        controller: _ownerNameController,
                        label: 'Nama Pemilik / Pengelola',
                        hint: 'Ahmad Bidin, S.Kom',
                        prefixIcon: Icons.manage_accounts_outlined,
                        validator: (v) =>
                            Validators.requiredField(v, 'Nama Pemilik'),
                      ),
                      const SizedBox(height: 12),

                      CustomTextField(
                        controller: _telpController,
                        label: 'No. Telepon / Hotline',
                        hint: '081298765432',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: Validators.phone,
                      ),
                      const SizedBox(height: 28),

                      // ─ Grup 2: Akun admin ────────────────────
                      _SectionHeader(
                        number: '02',
                        title: 'Akun Admin',
                        subtitle: 'Kredensial untuk masuk panel admin',
                        accent: AppColors.primaryYellow,
                      ),
                      const SizedBox(height: 14),

                      CustomTextField(
                        controller: _usernameController,
                        label: 'Username Admin',
                        hint: 'admin_moklet',
                        prefixIcon: Icons.alternate_email_rounded,
                        validator: Validators.username,
                      ),
                      const SizedBox(height: 12),

                      CustomTextField(
                        controller: _passwordController,
                        label: 'Password',
                        hint: 'Minimal 6 karakter',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: _obscurePassword,
                        validator: Validators.password,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textMuted,
                            size: 18,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Tombol daftar
                      CustomButton(
                        text: 'Daftarkan Coworking Space',
                        backgroundColor: AppColors.primaryYellow,
                        isLoading: auth.isLoading,
                        onPressed: _handleRegister,
                      ),
                      const SizedBox(height: 18),

                      Center(
                        child: GestureDetector(
                          onTap: () => context.canPop()
                              ? context.pop()
                              : context.go('/login'),
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(fontSize: 13),
                              children: [
                                TextSpan(
                                  text: 'Sudah punya akun?  ',
                                  style: TextStyle(
                                      color: AppColors.textSecondary),
                                ),
                                TextSpan(
                                  text: 'Masuk di sini',
                                  style: TextStyle(
                                    color: AppColors.primaryYellow,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;
  final Color accent;

  const _SectionHeader({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }
}
