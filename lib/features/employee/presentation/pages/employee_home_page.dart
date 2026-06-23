import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:bonvo/config/themes/app_theme.dart';
import 'package:bonvo/core/widgets/app_button.dart';
import 'package:bonvo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bonvo/features/auth/presentation/bloc/auth_event.dart';
import 'package:bonvo/features/auth/presentation/bloc/auth_state.dart';

class EmployeeHomePage extends StatelessWidget {
  const EmployeeHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;
        final size = MediaQuery.of(context).size;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              // Header con gradiente
              Container(
                height: size.height * 0.28,
                width: double.infinity,
                decoration:
                    const BoxDecoration(gradient: AppColors.gradient),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 16, 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hola, ${user?.name.split(' ').first ?? ''}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Punto de venta · Bonvo',
                                  style: TextStyle(
                                    color:
                                        Colors.white.withValues(alpha: 0.7),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(AppIcons.signOut,
                                  color: Colors.white),
                              tooltip: 'Cerrar sesión',
                              onPressed: () => context
                                  .read<AuthBloc>()
                                  .add(const AuthLogoutRequested()),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Contenido
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Info card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.greenTint,
                          borderRadius:
                              BorderRadius.circular(AppRadius.card),
                          border: Border.all(color: AppColors.greenBorder),
                        ),
                        child: const Row(
                          children: [
                            Icon(AppIcons.info,
                                color: AppColors.primary, size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Escanea el QR del cliente para acreditar puntos por su compra.',
                                style: TextStyle(
                                  color: AppColors.primaryDeep,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Acción principal: escanear QR
                      GestureDetector(
                        onTap: () => context.go('/employee/scanner'),
                        child: Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            gradient: AppColors.gradient,
                            borderRadius:
                                BorderRadius.circular(AppRadius.cardLg),
                            boxShadow: AppShadows.button,
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color:
                                      Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                    AppIcons.scanner,
                                    color: Colors.white,
                                    size: 36),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Escanear QR del cliente',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Toca para abrir la cámara',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      AppButton(
                        label: 'Historial del día',
                        variant: AppButtonVariant.white,
                        icon: AppIcons.history,
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
