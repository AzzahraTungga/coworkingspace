import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'core/router/app_router.dart';
import 'presentation/shared/providers/admin_provider.dart';
import 'presentation/shared/providers/auth_provider.dart';
import 'presentation/shared/providers/booking_provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'presentation/shared/providers/reservasi_provider.dart';
import 'presentation/shared/providers/space_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  runApp(const CoworkingApp());
}

class CoworkingApp extends StatelessWidget {
  const CoworkingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SpaceProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => ReservasiProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: const _CoworkingAppView(),
    );
  }
}

class _CoworkingAppView extends StatefulWidget {
  const _CoworkingAppView();

  @override
  State<_CoworkingAppView> createState() => _CoworkingAppViewState();
}

class _CoworkingAppViewState extends State<_CoworkingAppView> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _router = AppRouter.createRouter(auth);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Smart Coworking Space',
      routerConfig: _router,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.bgLight,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryNavy,
          primary: AppColors.primaryNavy,
          secondary: AppColors.primaryYellow,
          surface: Colors.white,
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          Theme.of(context).textTheme,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.primaryNavy),
          titleTextStyle: TextStyle(
            color: AppColors.primaryNavy,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primaryYellow,
          unselectedItemColor: AppColors.textMuted,
        ),
      ),
    );
  }
}
