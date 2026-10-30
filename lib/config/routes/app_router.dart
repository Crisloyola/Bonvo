import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bonvo/core/utils/go_router_refresh_stream.dart';
import 'package:bonvo/core/utils/responsive.dart';
import 'package:bonvo/features/auth/domain/entities/auth_user.dart';
import 'package:bonvo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bonvo/features/auth/presentation/bloc/auth_state.dart';
import 'package:bonvo/features/auth/presentation/pages/login_page.dart';
import 'package:bonvo/features/auth/presentation/pages/onboarding_page.dart';
import 'package:bonvo/features/auth/presentation/pages/register_page.dart';
import 'package:bonvo/features/client/presentation/pages/mis_tiendas_page.dart';
import 'package:bonvo/features/business/presentation/pages/business_home_page.dart';
import 'package:bonvo/features/business/presentation/pages/business_programs_page.dart';
import 'package:bonvo/features/business/presentation/pages/business_requests_page.dart';
import 'package:bonvo/features/business/presentation/pages/business_setup_page.dart';
import 'package:bonvo/features/business/presentation/pages/client_list_page.dart';
import 'package:bonvo/features/client/presentation/pages/client_home_page.dart';
import 'package:bonvo/features/client/presentation/pages/qr_fullscreen_page.dart';
import 'package:bonvo/features/client/presentation/pages/scan_business_qr_page.dart';
import 'package:bonvo/features/client/presentation/pages/store_page.dart';
import 'package:bonvo/features/client/presentation/pages/transaction_history_page.dart';
import 'package:bonvo/features/employee/presentation/pages/employee_home_page.dart';
import 'package:bonvo/features/employee/presentation/pages/points_accreditation_page.dart';
import 'package:bonvo/features/employee/presentation/pages/qr_scanner_page.dart';
import 'package:bonvo/features/promotions/presentation/pages/client_promotions_page.dart';
import 'package:bonvo/features/promotions/presentation/pages/create_promotion_page.dart';
import 'package:bonvo/features/promotions/presentation/pages/promotions_admin_page.dart';

const _publicRoutes = ['/login', '/register', '/onboarding'];

/// Rutas que necesitan datos de la pantalla anterior (`extra`). Si se abren
/// sin ellos (p. ej. pegando el enlace), se vuelve al inicio del usuario.
const _routesWithExtra = {
  '/client/qr',
  '/client/history',
  '/client/store',
  '/client/promotions',
  '/business/clients',
  '/business/promotions',
  '/business/create-promotion',
  '/business/requests',
  '/business/programs',
  '/employee/accredit',
};

/// Datos pasados entre pantallas (`extra`). En web go_router los guarda en el
/// historial del navegador y al reconstruir la ruta vuelven como
/// Map<String, dynamic>, así que no se puede castear directo a
/// Map<String, String>.
Map<String, String> _extraMap(GoRouterState state) {
  final raw = state.extra;
  if (raw is! Map) return const {};
  return raw.map((k, v) => MapEntry('$k', '$v'));
}

/// GoRoute cuya página se envuelve en [ResponsiveFrame]: en pantallas anchas
/// se muestra como columna centrada, salvo las rutas con diseño de escritorio.
GoRoute _route({
  required String path,
  String? name,
  required GoRouterWidgetBuilder builder,
}) =>
    GoRoute(
      path: path,
      name: name,
      builder: (context, state) => ResponsiveFrame(
        fullWidth: wideLayoutRoutes.contains(path),
        child: builder(context, state),
      ),
    );

class AppRouter {
  late final GoRouter router;

  AppRouter({required AuthBloc authBloc}) {
    router = GoRouter(
      // En web no hay onboarding: se entra directo al login
      initialLocation: kIsWeb ? '/login' : '/onboarding',
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
      redirect: (context, state) {
        final authState = authBloc.state;
        final location = state.uri.path;
        final isPublic = _publicRoutes.contains(location);

        if (authState is AuthInitial || authState is AuthLoading) return null;

        if (authState is AuthAuthenticated) {
          if (isPublic) return _homeForRole(authState.user.role);
          if (_routesWithExtra.contains(location) && state.extra == null) {
            return _homeForRole(authState.user.role);
          }
          return null;
        }

        if (!isPublic) return '/login';
        if (kIsWeb && location == '/onboarding') return '/login';
        return null;
      },
      routes: [
        // --- Auth ---
        _route(
          path: '/onboarding',
          name: 'onboarding',
          builder: (context, state) => const OnboardingPage(),
        ),
        _route(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginPage(),
        ),
        _route(
          path: '/register',
          name: 'register',
          builder: (context, state) => const RegisterPage(),
        ),

        // --- Cliente ---
        _route(
          path: '/client/home',
          name: 'clientHome',
          builder: (context, state) => const ClientHomePage(),
        ),
        _route(
          path: '/client/tiendas',
          name: 'clientTiendas',
          builder: (context, state) => const MisTiendasPage(),
        ),
        _route(
          path: '/client/qr',
          name: 'clientQr',
          builder: (context, state) {
            final extra = _extraMap(state);
            return QrFullscreenPage(
              userId: extra['userId']!,
              userName: extra['userName']!,
            );
          },
        ),
        _route(
          path: '/client/history',
          name: 'clientHistory',
          builder: (context, state) {
            final extra = _extraMap(state);
            return TransactionHistoryPage(userId: extra['userId']!);
          },
        ),
        _route(
          path: '/client/scan-business',
          name: 'clientScanBusiness',
          builder: (context, state) => const ScanBusinessQrPage(),
        ),
        _route(
          path: '/client/store',
          name: 'clientStore',
          builder: (context, state) {
            final extra = _extraMap(state);
            return StorePage(businessId: extra['businessId']!);
          },
        ),

        // --- Negocio ---
        _route(
          path: '/business/home',
          name: 'businessHome',
          builder: (context, state) => const BusinessHomePage(),
        ),
        _route(
          path: '/business/setup',
          name: 'businessSetup',
          builder: (context, state) => const BusinessSetupPage(),
        ),
        _route(
          path: '/business/requests',
          name: 'businessRequests',
          builder: (context, state) {
            final extra = _extraMap(state);
            return BusinessRequestsPage(
              businessId: extra['businessId']!,
              businessName: extra['businessName'] ?? '',
            );
          },
        ),
        _route(
          path: '/business/programs',
          name: 'businessPrograms',
          builder: (context, state) {
            final extra = _extraMap(state);
            return BusinessProgramsPage(
              businessId: extra['businessId']!,
              businessName: extra['businessName'] ?? '',
            );
          },
        ),
        _route(
          path: '/business/clients',
          name: 'businessClients',
          builder: (context, state) {
            final extra = _extraMap(state);
            return ClientListPage(
              businessId: extra['businessId']!,
              businessName: extra['businessName'] ?? '',
            );
          },
        ),

        // --- Promociones admin ---
        _route(
          path: '/business/promotions',
          name: 'businessPromotions',
          builder: (context, state) {
            final extra = _extraMap(state);
            return PromotionsAdminPage(
              businessId: extra['businessId']!,
              businessName: extra['businessName']!,
            );
          },
        ),
        _route(
          path: '/business/create-promotion',
          name: 'createPromotion',
          builder: (context, state) {
            final extra = _extraMap(state);
            return CreatePromotionPage(
              businessId: extra['businessId']!,
              businessName: extra['businessName']!,
            );
          },
        ),

        // --- Promociones cliente ---
        _route(
          path: '/client/promotions',
          name: 'clientPromotions',
          builder: (context, state) {
            final extra = [
              for (final e in (state.extra as List?) ?? const []) '$e',
            ];
            return ClientPromotionsPage(businessIds: extra);
          },
        ),

        // --- Empleado ---
        _route(
          path: '/employee/home',
          name: 'employeeHome',
          builder: (context, state) => const EmployeeHomePage(),
        ),
        _route(
          path: '/employee/scanner',
          name: 'employeeScanner',
          builder: (context, state) => const QrScannerPage(),
        ),
        _route(
          path: '/business/scanner',
          name: 'businessScanner',
          builder: (context, state) =>
              const QrScannerPage(homeRoute: '/business/home'),
        ),
        _route(
          path: '/employee/accredit',
          name: 'employeeAccredit',
          builder: (context, state) {
            final extra = _extraMap(state);
            return PointsAccreditationPage(
              clientUserId: extra['userId']!,
              homeRoute: extra['homeRoute'] ?? '/employee/home',
            );
          },
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(child: Text('Página no encontrada: ${state.error}')),
      ),
    );
  }

  String _homeForRole(UserRole role) {
    switch (role) {
      case UserRole.client:
        return '/client/home';
      case UserRole.businessAdmin:
        return '/business/home';
      case UserRole.employee:
        return '/employee/home';
    }
  }
}
