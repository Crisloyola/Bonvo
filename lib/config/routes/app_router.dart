import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bonvo/core/utils/go_router_refresh_stream.dart';
import 'package:bonvo/features/auth/domain/entities/auth_user.dart';
import 'package:bonvo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bonvo/features/auth/presentation/bloc/auth_state.dart';
import 'package:bonvo/features/auth/presentation/pages/login_page.dart';
import 'package:bonvo/features/auth/presentation/pages/onboarding_page.dart';
import 'package:bonvo/features/auth/presentation/pages/register_page.dart';
import 'package:bonvo/features/client/presentation/pages/mis_tiendas_page.dart';
import 'package:bonvo/features/business/presentation/pages/business_home_page.dart';
import 'package:bonvo/features/business/presentation/pages/business_setup_page.dart';
import 'package:bonvo/features/business/presentation/pages/client_list_page.dart';
import 'package:bonvo/features/client/presentation/pages/client_home_page.dart';
import 'package:bonvo/features/client/presentation/pages/join_business_page.dart';
import 'package:bonvo/features/client/presentation/pages/qr_fullscreen_page.dart';
import 'package:bonvo/features/client/presentation/pages/scan_business_qr_page.dart';
import 'package:bonvo/features/client/presentation/pages/transaction_history_page.dart';
import 'package:bonvo/features/employee/presentation/pages/employee_home_page.dart';
import 'package:bonvo/features/employee/presentation/pages/points_accreditation_page.dart';
import 'package:bonvo/features/employee/presentation/pages/qr_scanner_page.dart';
import 'package:bonvo/features/promotions/presentation/pages/client_promotions_page.dart';
import 'package:bonvo/features/promotions/presentation/pages/create_promotion_page.dart';
import 'package:bonvo/features/promotions/presentation/pages/promotions_admin_page.dart';

const _publicRoutes = ['/login', '/register', '/onboarding'];

class AppRouter {
  late final GoRouter router;

  AppRouter({required AuthBloc authBloc}) {
    router = GoRouter(
      initialLocation: '/onboarding',
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
      redirect: (context, state) {
        final authState = authBloc.state;
        final location = state.uri.path;
        final isPublic = _publicRoutes.contains(location);

        if (authState is AuthInitial || authState is AuthLoading) return null;

        if (authState is AuthAuthenticated) {
          if (isPublic) return _homeForRole(authState.user.role);
          return null;
        }

        if (!isPublic) return '/login';
        return null;
      },
      routes: [
        // --- Auth ---
        GoRoute(
          path: '/onboarding',
          name: 'onboarding',
          builder: (context, state) => const OnboardingPage(),
        ),
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: '/register',
          name: 'register',
          builder: (context, state) => const RegisterPage(),
        ),

        // --- Cliente ---
        GoRoute(
          path: '/client/home',
          name: 'clientHome',
          builder: (context, state) => const ClientHomePage(),
        ),
        GoRoute(
          path: '/client/tiendas',
          name: 'clientTiendas',
          builder: (context, state) => const MisTiendasPage(),
        ),
        GoRoute(
          path: '/client/qr',
          name: 'clientQr',
          builder: (context, state) {
            final extra = state.extra as Map<String, String>;
            return QrFullscreenPage(
              userId: extra['userId']!,
              userName: extra['userName']!,
            );
          },
        ),
        GoRoute(
          path: '/client/history',
          name: 'clientHistory',
          builder: (context, state) {
            final extra = state.extra as Map<String, String>;
            return TransactionHistoryPage(userId: extra['userId']!);
          },
        ),
        GoRoute(
          path: '/client/scan-business',
          name: 'clientScanBusiness',
          builder: (context, state) => const ScanBusinessQrPage(),
        ),
        GoRoute(
          path: '/client/join',
          name: 'clientJoinBusiness',
          builder: (context, state) {
            final extra = state.extra as Map<String, String>;
            return JoinBusinessPage(businessId: extra['businessId']!);
          },
        ),

        // --- Negocio ---
        GoRoute(
          path: '/business/home',
          name: 'businessHome',
          builder: (context, state) => const BusinessHomePage(),
        ),
        GoRoute(
          path: '/business/setup',
          name: 'businessSetup',
          builder: (context, state) => const BusinessSetupPage(),
        ),
        GoRoute(
          path: '/business/clients',
          name: 'businessClients',
          builder: (context, state) {
            final extra = state.extra as Map<String, String>;
            return ClientListPage(
              businessId: extra['businessId']!,
              businessName: extra['businessName'] ?? '',
            );
          },
        ),

        // --- Promociones admin ---
        GoRoute(
          path: '/business/promotions',
          name: 'businessPromotions',
          builder: (context, state) {
            final extra = state.extra as Map<String, String>;
            return PromotionsAdminPage(
              businessId: extra['businessId']!,
              businessName: extra['businessName']!,
            );
          },
        ),
        GoRoute(
          path: '/business/create-promotion',
          name: 'createPromotion',
          builder: (context, state) {
            final extra = state.extra as Map<String, String>;
            return CreatePromotionPage(
              businessId: extra['businessId']!,
              businessName: extra['businessName']!,
            );
          },
        ),

        // --- Promociones cliente ---
        GoRoute(
          path: '/client/promotions',
          name: 'clientPromotions',
          builder: (context, state) {
            final extra = List<String>.from(state.extra as List);
            return ClientPromotionsPage(businessIds: extra);
          },
        ),

        // --- Empleado ---
        GoRoute(
          path: '/employee/home',
          name: 'employeeHome',
          builder: (context, state) => const EmployeeHomePage(),
        ),
        GoRoute(
          path: '/employee/scanner',
          name: 'employeeScanner',
          builder: (context, state) => const QrScannerPage(),
        ),
        GoRoute(
          path: '/business/scanner',
          name: 'businessScanner',
          builder: (context, state) =>
              const QrScannerPage(homeRoute: '/business/home'),
        ),
        GoRoute(
          path: '/employee/accredit',
          name: 'employeeAccredit',
          builder: (context, state) {
            final extra = state.extra as Map<String, String>;
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
