import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/space_model.dart';
import '../../presentation/admin/dashboard/admin_dashboard_screen.dart';
import '../../presentation/admin/income_report/admin_income_report_screen.dart';
import '../../presentation/admin/main_layout/admin_main_layout.dart';
import '../../presentation/admin/management/admin_management_screen.dart';
import '../../presentation/admin/profile/admin_profile_edit_screen.dart';
import '../../presentation/admin/register/register_admin_screen.dart';
import '../../presentation/admin/reservasi_list/admin_reservasi_list_screen.dart';
import '../../presentation/member/booking/booking_form_screen.dart';
import '../../presentation/member/booking_history/member_history_screen.dart';
import '../../presentation/member/booking_status/member_booking_status_screen.dart';
import '../../presentation/member/e_ticket/e_ticket_screen.dart';
import '../../presentation/member/main_layout/member_main_layout.dart';
import '../../presentation/member/profile/member_profile_screen.dart';
import '../../presentation/member/register/register_member_screen.dart';
import '../../presentation/member/space_catalog/member_home_screen.dart';
import '../../presentation/member/space_catalog/space_detail_screen.dart';
import '../../presentation/shared/providers/auth_provider.dart';
import '../../presentation/shared/screens/login_screen.dart';
import '../../presentation/shared/screens/splash_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isAuth = authProvider.isAuthenticated;
        final role = authProvider.role;
        final loc = state.uri.path;

        final isSplash = loc == '/';
        final isLogin = loc == '/login';
        final isRegister = loc == '/register-member' || loc == '/register-admin';

        // 1. Jika belum login
        if (!isAuth) {
          if (isSplash || isLogin || isRegister) {
            return null; // Izinkan akses halaman publik
          }
          return '/login'; // Redirect semua rute privat ke login
        }

        // 2. Jika sudah login dan mencoba akses splash / login / register
        if (isSplash || isLogin || isRegister) {
          return role == 'admin_space' ? '/admin/dashboard' : '/member/catalog';
        }

        // 3. Role Guard: Cegah Member buka halaman Admin
        if (role == 'member' && loc.startsWith('/admin')) {
          return '/member/catalog';
        }

        // 4. Role Guard: Cegah Admin buka halaman Member
        if (role == 'admin_space' && loc.startsWith('/member')) {
          return '/admin/dashboard';
        }

        // 5. Short route /member -> /member/catalog
        if (loc == '/member') {
          return '/member/catalog';
        }

        // 6. Short route /admin -> /admin/dashboard
        if (loc == '/admin') {
          return '/admin/dashboard';
        }

        return null;
      },
      routes: [
        // Halaman Publik
        GoRoute(
          path: '/',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return LoginScreen(
              initialUsername: extra?['username'] as String?,
              initialPassword: extra?['password'] as String?,
              autoLogin: extra?['autoLogin'] as bool? ?? false,
            );
          },
        ),
        GoRoute(
          path: '/register-member',
          builder: (context, state) => const RegisterMemberScreen(),
        ),
        GoRoute(
          path: '/register-admin',
          builder: (context, state) => const RegisterAdminScreen(),
        ),

        // ----------------------------------------------------
        // STATEFUL SHELL ROUTE: MEMBER AREA
        // ----------------------------------------------------
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MemberMainLayout(navigationShell: navigationShell);
          },
          branches: [
            // Tab 0: Katalog Space
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/member/catalog',
                  builder: (context, state) => const MemberHomeScreen(),
                ),
              ],
            ),
            // Tab 1: Pesanan (Booking Status)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/member/booking-status',
                  builder: (context, state) => const MemberBookingStatusScreen(),
                ),
              ],
            ),
            // Tab 2: Riwayat (History)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/member/history',
                  builder: (context, state) => const MemberHistoryScreen(),
                ),
              ],
            ),
            // Tab 3: Profil
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/member/profile',
                  builder: (context, state) => const MemberProfileScreen(),
                ),
              ],
            ),
          ],
        ),

        // Sub-rute Member (Tampil di atas Shell/Fullscreen)
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/space-detail',
          builder: (context, state) {
            final space = state.extra as SpaceModel;
            return SpaceDetailScreen(space: space);
          },
        ),
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/booking-form',
          builder: (context, state) {
            final space = state.extra as SpaceModel;
            return BookingFormScreen(space: space);
          },
        ),
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/e-ticket/:id',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
            return ETicketScreen(reservasiId: id);
          },
        ),

        // ----------------------------------------------------
        // STATEFUL SHELL ROUTE: ADMIN AREA
        // ----------------------------------------------------
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return AdminMainLayout(navigationShell: navigationShell);
          },
          branches: [
            // Tab 0: Dashboard Beranda
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/admin/dashboard',
                  builder: (context, state) => const AdminDashboardScreen(),
                ),
              ],
            ),
            // Tab 1: Kelola Reservasi (Status, Check-In, Check-Out)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/admin/reservasi',
                  builder: (context, state) => const AdminReservasiListScreen(),
                ),
              ],
            ),
            // Tab 2: Kelola Data Master (Space, Member, Diskon)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/admin/management',
                  builder: (context, state) => const AdminManagementScreen(),
                ),
              ],
            ),
            // Tab 3: Rekapitulasi Pendapatan
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/admin/reports',
                  builder: (context, state) => const AdminIncomeReportScreen(),
                ),
              ],
            ),
          ],
        ),

        // Sub-rute Admin (Fullscreen)
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/admin/space-crud',
          builder: (context, state) => const AdminManagementScreen(initialTabIndex: 0),
        ),
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/admin/member-crud',
          builder: (context, state) => const AdminManagementScreen(initialTabIndex: 1),
        ),
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/admin/diskon-crud',
          builder: (context, state) => const AdminManagementScreen(initialTabIndex: 2),
        ),
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/admin/profile-edit',
          builder: (context, state) => const AdminProfileEditScreen(),
        ),
      ],
    );
  }
}
