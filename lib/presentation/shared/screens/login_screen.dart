import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../utils/validators.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/server_config_dialog.dart';

class LoginScreen extends StatefulWidget {
  final String? initialUsername;
  final String? initialPassword;
  final bool autoLogin;

  const LoginScreen({
    super.key,
    this.initialUsername,
    this.initialPassword,
    this.autoLogin = false,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    if (widget.initialUsername != null && widget.initialUsername!.isNotEmpty) {
      _usernameController.text = widget.initialUsername!;
    }
    if (widget.initialPassword != null && widget.initialPassword!.isNotEmpty) {
      _passwordController.text = widget.initialPassword!;
    }

    if (widget.autoLogin &&
        widget.initialUsername != null &&
        widget.initialUsername!.isNotEmpty &&
        widget.initialPassword != null &&
        widget.initialPassword!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerAutoLogin();
      });
    }
  }

  @override
  void didUpdateWidget(covariant LoginScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialUsername != null &&
        widget.initialUsername != oldWidget.initialUsername) {
      _usernameController.text = widget.initialUsername!;
    }
    if (widget.initialPassword != null &&
        widget.initialPassword != oldWidget.initialPassword) {
      _passwordController.text = widget.initialPassword!;
    }
    if (widget.autoLogin &&
        !oldWidget.autoLogin &&
        widget.initialUsername != null &&
        widget.initialUsername!.isNotEmpty &&
        widget.initialPassword != null &&
        widget.initialPassword!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerAutoLogin();
      });
    }
  }

  void _triggerAutoLogin() async {
    // Beri jeda sejenak agar pengguna melihat form login sudah terisi sebelum dialihkan
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Akun terdaftar! Sedang masuk ke dashboard...',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryNavy,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      _usernameController.text,
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      context.go(auth.isAdmin ? '/admin/dashboard' : '/member/catalog');
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
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();

    if (!auth.hasAppKey) {
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Text('App Key Belum Diisi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: const Text(
            'x-maker-key diperlukan untuk terhubung ke sistem. Atur dulu atau lanjut tanpa key?',
            style: TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx, false);
                ServerConfigDialog.show(context);
              },
              child: const Text('Atur Key'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                  foregroundColor: Colors.white),
              child: const Text('Lanjut'),
            ),
          ],
        ),
      );
      if (go != true) return;
    }

    final success =
        await auth.login(_usernameController.text, _passwordController.text);

    if (!mounted) return;

    if (success) {
      context.go(auth.isAdmin ? '/admin/dashboard' : '/member/catalog');
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
      body: Column(
        children: [
          // ── Top section — navy dengan pattern dots ─────────────
          Container(
            color: AppColors.primaryNavy,
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  // Dot pattern dekoratif
                  Positioned(
                    right: -20,
                    top: -20,
                    child: _DotGrid(
                        color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tombol setting
                        Align(
                          alignment: Alignment.topRight,
                          child: GestureDetector(
                            onTap: () => ServerConfigDialog.show(context),
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.settings_outlined,
                                  color: Colors.white70, size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Label kecil
                        Text(
                          'Selamat datang kembali',
                          style: TextStyle(
                            color: AppColors.primaryYellow
                                .withValues(alpha: 0.85),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Heading
                        const Text(
                          'Masuk ke\nAkun Anda',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Form section ───────────────────────────────────────
          Expanded(
            child: Container(
              color: AppColors.bgLight,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Username
                      _Label('Username'),
                      const SizedBox(height: 7),
                      _InputField(
                        controller: _usernameController,
                        hint: 'Masukkan username kamu',
                        icon: Icons.person_outline_rounded,
                        validator: Validators.username,
                      ),
                      const SizedBox(height: 18),

                      // Password
                      _Label('Password'),
                      const SizedBox(height: 7),
                      _InputField(
                        controller: _passwordController,
                        hint: 'Masukkan password',
                        icon: Icons.lock_outline_rounded,
                        obscure: _obscurePassword,
                        validator: Validators.password,
                        suffix: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Tombol masuk
                      CustomButton(
                        text: 'Masuk',
                        isLoading: auth.isLoading,
                        onPressed: _handleLogin,
                      ),
                      const SizedBox(height: 28),

                      // Divider
                      const Row(
                        children: [
                          Expanded(child: Divider(color: AppColors.border)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'atau',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.textMuted),
                            ),
                          ),
                          Expanded(child: Divider(color: AppColors.border)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Daftar member
                      _OutlineBtn(
                        label: 'Buat Akun Member',
                        icon: Icons.badge_outlined,
                        onTap: () => context.push('/register-member'),
                        color: AppColors.primaryNavy,
                      ),
                      const SizedBox(height: 10),

                      // Daftar admin
                      _OutlineBtn(
                        label: 'Daftar sebagai Admin Space',
                        icon: Icons.storefront_outlined,
                        onTap: () => context.push('/register-admin'),
                        color: AppColors.primaryYellow,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Komponen lokal ────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final String? Function(String?)? validator;
  final Widget? suffix;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.validator,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(fontSize: 13, color: AppColors.textMuted),
        prefixIcon:
            Icon(icon, size: 18, color: AppColors.textMuted),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.primaryNavy, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _OutlineBtn({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: color),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withValues(alpha: 0.4)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: color.withValues(alpha: 0.04),
        ),
      ),
    );
  }
}

/// Dot grid dekoratif
class _DotGrid extends StatelessWidget {
  final Color color;
  const _DotGrid({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: CustomPaint(painter: _DotGridPainter(color)),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  final Color color;
  _DotGridPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const gap = 16.0;
    for (double x = 0; x < size.width; x += gap) {
      for (double y = 0; y < size.height; y += gap) {
        canvas.drawCircle(Offset(x, y), 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
