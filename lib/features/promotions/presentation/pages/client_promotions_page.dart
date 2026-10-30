import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:bonvo/config/themes/app_theme.dart';
import 'package:bonvo/core/utils/responsive.dart';
import 'package:bonvo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bonvo/features/auth/presentation/bloc/auth_state.dart';
import 'package:bonvo/features/client/presentation/widgets/client_web_shell.dart';
import 'package:bonvo/features/loyalty/data/loyalty_repository.dart';
import 'package:bonvo/features/promotions/domain/entities/promotion.dart';
import 'package:bonvo/features/promotions/domain/repositories/promotions_repository.dart';
import 'package:bonvo/features/promotions/presentation/widgets/promotion_card.dart';
import 'package:bonvo/injection/injection.dart';

class ClientPromotionsPage extends StatefulWidget {
  final List<String> businessIds;
  const ClientPromotionsPage({super.key, required this.businessIds});

  @override
  State<ClientPromotionsPage> createState() =>
      _ClientPromotionsPageState();
}

class _ClientPromotionsPageState extends State<ClientPromotionsPage> {
  List<Promotion> _promotions = [];
  bool _loading = true;
  String _activeFilter = 'Todas';
  final Set<String> _redeemedIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await getIt<PromotionsRepository>()
        .getClientPromotions(widget.businessIds);
    result.fold((_) {}, (list) => setState(() => _promotions = list));
    setState(() => _loading = false);
  }

  List<String> get _filters {
    final names = _promotions
        .where((p) => p.active)
        .map((p) => p.businessName)
        .toSet()
        .toList();
    return ['Todas', 'Canjeables', ...names];
  }

  List<Promotion> _filteredFor(int userPoints) {
    final active = _promotions.where((p) => p.active).toList();
    if (_activeFilter == 'Todas') return active;
    if (_activeFilter == 'Canjeables') {
      return active.where((p) => userPoints >= p.pointsCost).toList();
    }
    return active.where((p) => p.businessName == _activeFilter).toList();
  }

  /// Los canjes se piden desde la tienda: ahí están los puntos de esa
  /// tienda y el negocio aprueba la entrega.
  Future<void> _redeem(
      Promotion promo, String userId, int currentPoints) async {
    context.push('/client/store', extra: {'businessId': promo.businessId});
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final user =
            authState is AuthAuthenticated ? authState.user : null;
        final userId = user?.uid ?? '';
        // Sincroniza los ids del servidor en el set local (sin borrar los locales)
        if (user != null) {
          _redeemedIds.addAll(user.redeemedPromoIds);
        }

        return StreamBuilder<int>(
          stream: userId.isNotEmpty
              ? getIt<LoyaltyRepository>()
                  .watchTotalPoints(userId, user!.businessIds)
              : const Stream.empty(),
          initialData: 0,
          builder: (context, snap) {
            final userPoints = snap.data ?? 0;
            final filtered = _filteredFor(userPoints);

            final wide = context.isWide;

            Widget cardFor(Promotion p, int i) {
              final isRedeemed = _redeemedIds.contains(p.id);
              return _PromoCard(
                promo: p,
                canAfford: userPoints >= p.pointsCost,
                isRedeemed: isRedeemed,
                userPoints: userPoints,
                onRedeem: (!isRedeemed && userId.isNotEmpty)
                    ? () => _redeem(p, userId, userPoints)
                    : null,
              );
            }

            final body = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Título ──
                  Container(
                    color: Colors.white,
                    child: const SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(20, 16, 20, 14),
                        child: Text(
                          'Promociones',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Barra de puntos ámbar ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                            maxWidth: wide ? 520 : double.infinity),
                        child: _PointsBar(points: userPoints),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Chips de filtro ──
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filters.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final f = _filters[i];
                        final active = f == _activeFilter;
                        final label = f.split(' ').first;
                        return GestureDetector(
                          onTap: () => setState(() => _activeFilter = f),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: active
                                  ? const Color(0xFF0F0F0E)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: active
                                    ? const Color(0xFF0F0F0E)
                                    : AppColors.border,
                              ),
                            ),
                            child: Text(
                              i < 2 ? f : label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: active
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Lista de promos ──
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : filtered.isEmpty
                            ? const _EmptyState()
                            : wide
                                ? SingleChildScrollView(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 0, 16, 32),
                                    child: ResponsiveWrapGrid(
                                      minItemWidth: 340,
                                      spacing: 16,
                                      children: [
                                        for (var i = 0; i < filtered.length; i++)
                                          cardFor(filtered[i], i),
                                      ],
                                    ),
                                  )
                                : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                    16, 0, 16, 24),
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 14),
                                itemBuilder: (_, i) =>
                                    cardFor(filtered[i], i),
                              ),
                  ),
                ],
              );

            if (wide && user != null) {
              return ClientWebShell(
                current: ClientSection.promotions,
                user: user,
                child: body,
              );
            }

            return Scaffold(
              backgroundColor: AppColors.background,
              floatingActionButton: FloatingActionButton(
                backgroundColor: AppColors.primary,
                elevation: 4,
                shape: const CircleBorder(),
                onPressed: () {
                  if (userId.isNotEmpty && user != null) {
                    context.push('/client/qr', extra: {
                      'userId': userId,
                      'userName': user.name,
                    });
                  }
                },
                child: const Icon(AppIcons.scanner,
                    color: Colors.white, size: 28),
              ),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.centerDocked,
              bottomNavigationBar: _BottomBar(
                onInicio: () => context.go('/client/home'),
                onTiendas: () => context.push('/client/tiendas'),
                onPerfil: () {},
              ),
              body: body,
            );
          },
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────
class _PointsBar extends StatelessWidget {
  final int points;
  const _PointsBar({required this.points});

  String get _formatted {
    if (points >= 1000) {
      return '${points ~/ 1000},${(points % 1000).toString().padLeft(3, '0')}';
    }
    return '$points';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF2A2A27), Color(0xFF0F0F0E)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A2A27).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(AppIcons.star, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          const Text(
            'Puntos disponibles',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            _formatted,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
class _PromoCard extends StatelessWidget {
  final Promotion promo;
  final bool canAfford;
  final bool isRedeemed;
  final int userPoints;
  final VoidCallback? onRedeem;

  const _PromoCard({
    required this.promo,
    required this.canAfford,
    required this.isRedeemed,
    required this.userPoints,
    this.onRedeem,
  });

  @override
  Widget build(BuildContext context) {
    final lacking = promo.pointsCost - userPoints;
    final Widget footer;
    if (isRedeemed) {
      footer = const _FooterNote(
          icon: AppIcons.check, text: 'Promoción canjeada');
    } else if (promo.pointsCost == 0 || canAfford) {
      footer = FilledButton(
        style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
        onPressed: onRedeem,
        child: Text(promo.pointsCost == 0 ? 'Ver en la tienda' : 'Canjear'),
      );
    } else {
      footer = _FooterNote(icon: AppIcons.star, text: 'Te faltan $lacking pts');
    }
    return PromotionCard(promo: promo, showBusiness: true, footer: footer);
  }
}

class _FooterNote extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FooterNote({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.amberTint,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(text,
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.amberTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(AppIcons.promotions,
                size: 40, color: AppColors.amberText),
          ),
          const SizedBox(height: 20),
          const Text(
            'Sin promociones disponibles',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Las tiendas donde estás inscrito\npublicarán ofertas aquí.',
            textAlign: TextAlign.center,
            style:
                TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final VoidCallback onInicio;
  final VoidCallback onTiendas;
  final VoidCallback onPerfil;

  const _BottomBar({
    required this.onInicio,
    required this.onTiendas,
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
                icon: AppIcons.home,
                label: 'Inicio',
                onTap: onInicio),
            _NavItem(
                icon: AppIcons.tiendas,
                label: 'Tiendas',
                onTap: onTiendas),
            const SizedBox(width: 56),
            _NavItem(
              icon: AppIcons.promotions,
              label: 'Promos',
              active: true,
              onTap: () {},
            ),
            _NavItem(
                icon: AppIcons.profile,
                label: 'Perfil',
                onTap: onPerfil),
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
