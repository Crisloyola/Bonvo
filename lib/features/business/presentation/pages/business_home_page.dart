import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:bonvo/config/themes/app_theme.dart';
import 'package:bonvo/core/services/storage_service.dart';
import 'package:bonvo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bonvo/features/auth/presentation/bloc/auth_event.dart';
import 'package:bonvo/features/auth/presentation/bloc/auth_state.dart';
import 'package:bonvo/features/business/domain/entities/business.dart';
import 'package:bonvo/features/business/domain/repositories/business_repository.dart';
import 'package:bonvo/features/business/domain/usecases/create_business.dart';
import 'package:bonvo/features/business/presentation/cubit/business_cubit.dart';
import 'package:bonvo/features/business/presentation/pages/business_qr_page.dart';
import 'package:bonvo/injection/injection.dart';

class BusinessHomePage extends StatelessWidget {
  const BusinessHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is AuthLoading) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final user =
            authState is AuthAuthenticated ? authState.user : null;
        if (user == null) return const SizedBox.shrink();

        if (user.businessIds.isEmpty) return const _SetupPrompt();

        return BlocProvider(
          create: (_) => BusinessCubit(
            repository: getIt<BusinessRepository>(),
            createBusiness: getIt<CreateBusiness>(),
          )..loadBusiness(user.businessIds.first),
          child: const _BusinessDashboard(),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────
class _SetupPrompt extends StatelessWidget {
  const _SetupPrompt();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.28,
            decoration:
                const BoxDecoration(gradient: AppColors.gradient),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('Bonvo Business',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                    IconButton(
                      icon: const Icon(AppIcons.signOut,
                          color: Colors.white),
                      onPressed: () => context
                          .read<AuthBloc>()
                          .add(const AuthLogoutRequested()),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: const BoxDecoration(
                          color: AppColors.greenTint,
                          shape: BoxShape.circle),
                      child: const Icon(AppIcons.store,
                          size: 48, color: AppColors.primary),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Aún no tienes un negocio',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Crea tu programa de fidelización\nen minutos.',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 36),
                    SizedBox(
                      width: double.infinity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppColors.gradient,
                          borderRadius:
                              BorderRadius.circular(AppRadius.button),
                          boxShadow: AppShadows.button,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius:
                                BorderRadius.circular(AppRadius.button),
                            onTap: () => context.go('/business/setup'),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(AppIcons.plus,
                                      color: Colors.white),
                                  SizedBox(width: 8),
                                  Text('Crear mi negocio',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
class _BusinessDashboard extends StatelessWidget {
  const _BusinessDashboard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BusinessCubit, BusinessState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: switch (state) {
            BusinessLoading() =>
              const Center(child: CircularProgressIndicator()),
            BusinessError(:final message) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(AppIcons.warning,
                        size: 48, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () =>
                          context.read<BusinessCubit>().loadBusiness(
                                (context.read<AuthBloc>().state
                                        as AuthAuthenticated)
                                    .user
                                    .businessIds
                                    .first,
                              ),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            BusinessLoaded(
              :final business,
              :final stats,
              :final clients
            ) =>
              _DashboardContent(
                  business: business, stats: stats, clients: clients),
            _ => const Center(child: CircularProgressIndicator()),
          },
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────
class _DashboardContent extends StatefulWidget {
  final Business business;
  final BusinessStats stats;
  final List<ClientSummary> clients;

  const _DashboardContent({
    required this.business,
    required this.stats,
    required this.clients,
  });

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent> {
  bool _bannerUploading = false;

  bool _logoUploading = false;

  Future<void> _changeLogo() async {
    setState(() => _logoUploading = true);
    try {
      final base64 = await getIt<StorageService>().pickLogoImage();
      if (base64 != null && mounted) {
        await getIt<BusinessRepository>().updateLogoBase64(
          businessId: widget.business.id,
          logoBase64: base64,
        );
        if (mounted) {
          context.read<BusinessCubit>().loadBusiness(widget.business.id);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al subir logo: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _logoUploading = false);
    }
  }

  Future<void> _changeBanner() async {
    setState(() => _bannerUploading = true);
    try {
      final base64 = await getIt<StorageService>().pickBannerImage();
      if (base64 != null && mounted) {
        await getIt<BusinessRepository>().updateBannerBase64(
          businessId: widget.business.id,
          bannerBase64: base64,
        );
        if (mounted) {
          context
              .read<BusinessCubit>()
              .loadBusiness(widget.business.id);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al subir banner: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _bannerUploading = false);
    }
  }

  void _showPointsDialog() {
    int pts = widget.business.pointsPerSol;
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: const Text('Programa de puntos',
              style: TextStyle(fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Puntos por cada S/ 1.00',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(AppIcons.minusCircle,
                        color: AppColors.primary),
                    onPressed: pts > 1 ? () => setS(() => pts--) : null,
                  ),
                  Text('$pts',
                      style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                  IconButton(
                    icon: const Icon(AppIcons.plusCircle,
                        color: AppColors.primary),
                    onPressed: pts < 10 ? () => setS(() => pts++) : null,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Chip cashback efectivo
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.amberTint,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.monetization_on_outlined,
                        color: AppColors.amberText, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Cashback efectivo: $pts%',
                      style: const TextStyle(
                        color: AppColors.amberText,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Por cada S/ 100 gastados\nel cliente recibe S/ $pts de cashback',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                getIt<BusinessRepository>().updatePointsPerSol(
                  businessId: widget.business.id,
                  pointsPerSol: pts,
                );
                context
                    .read<BusinessCubit>()
                    .loadBusiness(widget.business.id);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            _SheetTile(
              icon: AppIcons.scanner,
              color: AppColors.primary,
              title: 'QR de mi tienda',
              subtitle: 'Para que clientes se inscriban',
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) =>
                      BusinessQrPage(business: widget.business),
                ));
              },
            ),
            _SheetTile(
              icon: AppIcons.configure,
              color: const Color(0xFF7C3AED),
              title: 'Programa de puntos',
              subtitle:
                  '${widget.business.pointsPerSol} pt por S/ 1.00 · Toca para editar',
              onTap: () {
                Navigator.pop(ctx);
                _showPointsDialog();
              },
            ),
            _SheetTile(
              icon: AppIcons.image,
              color: const Color(0xFF0284C7),
              title: _logoUploading
                  ? 'Subiendo logo...'
                  : widget.business.logoBase64 != null
                      ? 'Cambiar logo'
                      : 'Subir logo del negocio',
              subtitle: 'Aparece en el encabezado de tu tienda',
              onTap: _logoUploading
                  ? null
                  : () {
                      Navigator.pop(ctx);
                      _changeLogo();
                    },
            ),
            _SheetTile(
              icon: AppIcons.upload,
              color: const Color(0xFF0284C7),
              title: _bannerUploading
                  ? 'Subiendo banner...'
                  : widget.business.bannerBase64 != null
                      ? 'Cambiar banner'
                      : 'Subir banner',
              subtitle: 'Imagen de portada del negocio',
              onTap: _bannerUploading
                  ? null
                  : () {
                      Navigator.pop(ctx);
                      _changeBanner();
                    },
            ),
            const Divider(height: 20),
            _SheetTile(
              icon: AppIcons.signOut,
              color: AppColors.error,
              title: 'Cerrar sesión',
              subtitle: 'Salir de tu cuenta',
              onTap: () {
                Navigator.pop(ctx);
                context
                    .read<AuthBloc>()
                    .add(const AuthLogoutRequested());
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        elevation: 4,
        shape: const CircleBorder(),
        onPressed: () => context.push('/business/scanner'),
        child: const Icon(AppIcons.scanner,
            color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _AdminBottomBar(
        onClientes: () => context.push('/business/clients', extra: {
          'businessId': widget.business.id,
          'businessName': widget.business.name,
        }),
        onPromos: () => context.push('/business/promotions', extra: {
          'businessId': widget.business.id,
          'businessName': widget.business.name,
        }),
        onPerfil: _showSettingsSheet,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AdminHeader(
            business: widget.business,
            onSettings: _showSettingsSheet,
            onRefresh: () => context
                .read<BusinessCubit>()
                .loadBusiness(widget.business.id),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Banner de cashback ──
                  _CashbackBanner(
                    pointsPerSol: widget.business.pointsPerSol,
                    totalPointsIssued: widget.stats.totalPointsIssued,
                  ),

                  const SizedBox(height: 16),

                  // Métricas 2×2
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          label: 'Clientes activos',
                          value: _fmtMetric(widget.stats.uniqueClients),
                          icon: AppIcons.clients,
                          color: AppColors.primary,
                          bgColor: AppColors.greenTint,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetricCard(
                          label: 'Puntos emitidos',
                          value: _fmtMetric(
                              widget.stats.totalPointsIssued),
                          icon: AppIcons.star,
                          color: AppColors.amberText,
                          bgColor: AppColors.amberTint,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          label: 'Transacciones',
                          value: _fmtMetric(
                              widget.stats.totalTransactions),
                          icon: AppIcons.coins,
                          color: const Color(0xFF0284C7),
                          bgColor: const Color(0xFFE0F2FE),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetricCard(
                          label: 'Cashback emitido',
                          value: 'S/ ${(widget.stats.totalPointsIssued / 100).toStringAsFixed(2)}',
                          icon: AppIcons.coins,
                          color: const Color(0xFF7C3AED),
                          bgColor: const Color(0xFFEDE9FE),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Botones de acción ──
                  Row(
                    children: [
                      Expanded(
                        flex: 6,
                        child: GestureDetector(
                          onTap: () =>
                              context.push('/business/scanner'),
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: AppColors.gradient,
                              borderRadius: BorderRadius.circular(
                                  AppRadius.button),
                              boxShadow: AppShadows.button,
                            ),
                            child: const Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Icon(AppIcons.scanner,
                                    color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Acreditar',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 5,
                        child: GestureDetector(
                          onTap: () =>
                              context.push('/business/promotions',
                                  extra: {
                                'businessId': widget.business.id,
                                'businessName':
                                    widget.business.name,
                              }),
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(
                                  AppRadius.button),
                            ),
                            child: const Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Icon(AppIcons.plus,
                                    color: Colors.white, size: 20),
                                SizedBox(width: 6),
                                Text(
                                  'Nueva\npromo',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    height: 1.2,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ── Actividad reciente ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Actividad reciente',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (widget.clients.isNotEmpty)
                        TextButton(
                          onPressed: () =>
                              context.push('/business/clients',
                                  extra: {
                                'businessId': widget.business.id
                              }),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            tapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Ver todos',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  if (widget.clients.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(AppRadius.card),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Center(
                        child: Text(
                          'Aún no hay actividad.\nEscanea tu primer cliente.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ...widget.clients
                        .take(5)
                        .map((c) => _ActivityRow(
                            client: c,
                            pointsPerSol:
                                widget.business.pointsPerSol)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtMetric(int v) {
    if (v >= 10000) {
      final k = v / 1000.0;
      return '${k.toStringAsFixed(k < 10 ? 1 : 0)}k';
    }
    if (v >= 1000) {
      return '${v ~/ 1000},${(v % 1000).toString().padLeft(3, '0')}';
    }
    return '$v';
  }
}

// ──────────────────────────────────────────────────────────────
class _AdminHeader extends StatelessWidget {
  final Business business;
  final VoidCallback onSettings;
  final VoidCallback onRefresh;

  const _AdminHeader({
    required this.business,
    required this.onSettings,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final bannerBytes = business.bannerBase64 != null
        ? base64Decode(business.bannerBase64!)
        : null;

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.gradient),
      child: Stack(
        children: [
          // Banner como fondo cuando existe
          if (bannerBytes != null)
            Positioned.fill(
              child: Image.memory(
                bannerBytes,
                fit: BoxFit.cover,
              ),
            ),
          // Overlay oscuro para legibilidad del texto
          if (bannerBytes != null)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xCC065F46), Color(0xAA059669)],
                  ),
                ),
              ),
            ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 16, 18),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: business.logoBase64 != null
                        ? Image.memory(
                            base64Decode(business.logoBase64!),
                            fit: BoxFit.cover,
                          )
                        : const Icon(AppIcons.store,
                            color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Negocio',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          business.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(AppIcons.refresh,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 20),
                    onPressed: onRefresh,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: onSettings,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(AppIcons.settings,
                          color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
class _CashbackBanner extends StatelessWidget {
  final int pointsPerSol;
  final int totalPointsIssued;

  const _CashbackBanner({
    required this.pointsPerSol,
    required this.totalPointsIssued,
  });

  String get _cashbackPct => '$pointsPerSol%';
  String get _totalCashback =>
      'S/ ${(totalPointsIssued / 100).toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -6,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.monetization_on_outlined,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Programa de Cashback',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ofreces $_cashbackPct de cashback',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _totalCashback,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'total emitido',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -1.5,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
class _ActivityRow extends StatelessWidget {
  final ClientSummary client;
  final int pointsPerSol;

  const _ActivityRow({required this.client, required this.pointsPerSol});

  static const _avatarColors = [
    AppColors.primary,
    Color(0xFF0284C7),
    Color(0xFF7C3AED),
    Color(0xFFD97706),
    Color(0xFFDC2626),
  ];

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 30) return 'Hace ${diff.inDays} días';
    return 'Hace meses';
  }

  @override
  Widget build(BuildContext context) {
    final color =
        _avatarColors[client.name.hashCode.abs() % _avatarColors.length];
    final initial = client.name.isNotEmpty
        ? client.name.trim()[0].toUpperCase()
        : '?';
    final visits = client.transactionCount;

    final photoBytes = client.photoBase64 != null
        ? base64Decode(client.photoBase64!)
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: color.withValues(alpha: 0.12),
            backgroundImage:
                photoBytes != null ? MemoryImage(photoBytes) : null,
            child: photoBytes == null
                ? Text(
                    initial,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      client.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.greenTint,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '+${visits * pointsPerSol} pts',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${_timeAgo(client.lastVisit)} · $visits visitas',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
class _AdminBottomBar extends StatelessWidget {
  final VoidCallback onClientes;
  final VoidCallback onPromos;
  final VoidCallback onPerfil;

  const _AdminBottomBar({
    required this.onClientes,
    required this.onPromos,
    required this.onPerfil,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      color: Colors.white,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: AppIcons.dashboard,
              label: 'Inicio',
              active: true,
              onTap: () {},
            ),
            _NavItem(
              icon: AppIcons.clients,
              label: 'Clientes',
              onTap: onClientes,
            ),
            const SizedBox(width: 56),
            _NavItem(
              icon: AppIcons.promotions,
              label: 'Promos',
              onTap: onPromos,
            ),
            _NavItem(
              icon: AppIcons.profile,
              label: 'Perfil',
              onTap: onPerfil,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.textMuted;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
class _SheetTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SheetTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: AppColors.textPrimary),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
            fontSize: 12, color: AppColors.textSecondary),
      ),
      onTap: onTap,
    );
  }
}
