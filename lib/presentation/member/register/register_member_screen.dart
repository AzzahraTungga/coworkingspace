import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../utils/validators.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/custom_text_field.dart';

class RegisterMemberScreen extends StatefulWidget {
  const RegisterMemberScreen({super.key});

  @override
  State<RegisterMemberScreen> createState() => _RegisterMemberScreenState();
}

class _RegisterMemberScreenState extends State<RegisterMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _instansiController = TextEditingController();
  final _telpController = TextEditingController();
  final _alamatController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _namaController.dispose();
    _instansiController.dispose();
    _telpController.dispose();
    _alamatController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    final success = await auth.registerMember(
      username: username,
      password: password,
      namaMember: _namaController.text,
      instansi: _instansiController.text,
      alamat: _alamatController.text,
      telp: _telpController.text,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline_rounded,
                  color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text('Akun member berhasil dibuat! Menuju login...'),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      // Langsung diarahkan ke halaman login lalu otomatis ke dashboard
      context.go(
        '/login',
        extra: {
          'username': username,
          'password': password,
          'autoLogin': true,
        },
      );
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
          // ── App bar custom ─────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppColors.primaryNavy,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/login'),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.fromLTRB(56, 0, 16, 16),
              title: const Text(
                'Daftar Member',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: AppColors.primaryNavy),
                  // Aksen titik
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: Row(
                      children: List.generate(
                        3,
                        (i) => Container(
                          margin: const EdgeInsets.only(left: 6),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == 0
                                ? AppColors.primaryYellow
                                : Colors.white.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Label top
                  Positioned(
                    left: 16,
                    top: 70,
                    child: Text(
                      'Buat akun untuk mulai memesan space',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Form ───────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ─ Grup 1: Data Diri ──────────────────────
                      _SectionHeader(
                        number: '01',
                        title: 'Data Diri',
                        subtitle: 'Informasi dasar tentang kamu',
                      ),
                      const SizedBox(height: 14),

                      CustomTextField(
                        controller: _namaController,
                        label: 'Nama Lengkap',
                        hint: 'John Doe',
                        prefixIcon: Icons.person_outline_rounded,
                        validator: (v) =>
                            Validators.requiredField(v, 'Nama Lengkap'),
                      ),
                      const SizedBox(height: 12),

                      CustomTextField(
                        controller: _instansiController,
                        label: 'Instansi / Perusahaan',
                        hint: 'Universitas / Startup / Freelance',
                        prefixIcon: Icons.business_center_outlined,
                        validator: (v) =>
                            Validators.requiredField(v, 'Instansi'),
                      ),
                      const SizedBox(height: 12),

                      CustomTextField(
                        controller: _telpController,
                        label: 'No. WhatsApp',
                        hint: '081234567890',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: Validators.phone,
                      ),
                      const SizedBox(height: 12),

                      CustomTextField(
                        controller: _alamatController,
                        label: 'Alamat',
                        hint: 'Jl. Merdeka No.1, Malang',
                        prefixIcon: Icons.location_on_outlined,
                        maxLines: 2,
                        validator: (v) =>
                            Validators.requiredField(v, 'Alamat'),
                      ),
                      const SizedBox(height: 28),

                      // ─ Grup 2: Akun ───────────────────────────
                      _SectionHeader(
                        number: '02',
                        title: 'Akun Login',
                        subtitle: 'Digunakan untuk masuk ke aplikasi',
                      ),
                      const SizedBox(height: 14),

                      CustomTextField(
                        controller: _usernameController,
                        label: 'Username',
                        hint: 'Pilih username unik',
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

                      // Tombol submit
                      CustomButton(
                        text: 'Buat Akun',
                        isLoading: auth.isLoading,
                        onPressed: _handleRegister,
                      ),
                      const SizedBox(height: 18),

                      // Sudah punya akun
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
                                  style:
                                      TextStyle(color: AppColors.textSecondary),
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

/// Section header bernomor
class _SectionHeader extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.number,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Nomor bulat
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.primaryNavy,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
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
