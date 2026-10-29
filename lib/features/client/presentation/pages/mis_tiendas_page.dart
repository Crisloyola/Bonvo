import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:bonvo/config/themes/app_theme.dart';
import 'package:bonvo/core/utils/responsive.dart';
import 'package:bonvo/features/auth/domain/entities/auth_user.dart';
import 'package:bonvo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bonvo/features/auth/presentation/bloc/auth_state.dart';
import 'package:bonvo/features/business/domain/entities/business.dart';
import 'package:bonvo/features/client/presentation/widgets/client_web_shell.dart';
import 'package:bonvo/features/business/domain/repositories/business_repository.dart';
import 'package:bonvo/features/loyalty/data/loyalty_repository.dart';
import 'package:bonvo/features/loyalty/domain/loyalty.dart';
import 'package:bonvo/injection/injection.dart';

class MisTiendasPage extends StatelessWidget {
  const MisTiendasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;
        if (user == null) return const SizedBox.shrink();
        return _MisTiendasView(user: user);
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────
class _MisTiendasView extends StatefulWidget {
  final AuthUser user;
  const _MisTiendasView({required this.user});

  @override
  State<_MisTiendasView> createState() => _MisTiendasViewState();
}

class _MisTiendasViewState extends State<_MisTiendasView> {
  List<Business> _businesses = [];
  Map<String, Membership> _members = {};
  Position? _position;
  String _search = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // 1. Cargar negocios inscritos
    final businesses = <Business>[];
    for (final id in widget.user.businessIds) {
      final r = await getIt<BusinessRepository>().getBusiness(id);
      r.fold((_) {}, (b) => businesses.add(b));
    }

    // 2. Saldos del cliente en cada tienda
    final members = <String, Membership>{};
    for (final b in businesses) {
      final m = await getIt<LoyaltyRepository>()
          .watchMembership(b.id, widget.user.uid)
          .first;
      if (m != null) members[b.id] = m;
    }

    // 3. Posición GPS
    Position? pos;
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.whileInUse ||
          perm == LocationPermission.always) {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 10),
          ),
        );
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _businesses = businesses;
        _members = members;
        _position = pos;
        _loading = false;
      });
    }
  }

  List<Business> get _filtered {
    if (_search.isEmpty) return _businesses;
    final q = _search.toLowerCase();
    return _businesses
        .where((b) =>
            b.name.toLowerCase().contains(q) ||
            b.description.toLowerCase().contains(q))
        .toList();
  }

  double? _distanceTo(Business b) {
    if (_position == null || !b.hasLocation) return null;
    return Geolocator.distanceBetween(
      _position!.latitude,
      _position!.longitude,
      b.latitude!,
      b.longitude!,
    );
  }

  List<Business> get _nearby {
    return _filtered.where((b) {
      final d = _distanceTo(b);
      return d != null && d <= 2000;
    }).toList()
      ..sort((a, b) => (_distanceTo(a) ?? 0).compareTo(_distanceTo(b) ?? 0));
  }

  List<Business> get _rest {
    final nearbyIds = _nearby.map((b) => b.id).toSet();
    return _filtered.where((b) => !nearbyIds.contains(b.id)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final wide = context.isWide;

    // En escritorio las tiendas van en cuadrícula; en celular, en lista
    List<Widget> tilesFor(List<Business> list) {
      final tiles = list
          .map((b) => _BusinessTile(
                business: b,
                member: _members[b.id],
                distance: _distanceTo(b),
              ))
          .toList();
      if (!wide) return tiles;
      // _BusinessTile ya trae su margen inferior
      return [
        ResponsiveWrapGrid(
            minItemWidth: 360, spacing: 16, runSpacing: 0, children: tiles),
      ];
    }

    final body = Column(
      children: [
        // ── Header ──
        Container(
          color: Colors.white,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 14),
              child: Row(
                children: [
                  const Text(
                    'Mis tiendas',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.push('/client/scan-business'),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add_rounded,
                          color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Buscador ──
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          alignment: Alignment.centerLeft,
          child: Container(
            height: 44,
            constraints: BoxConstraints(maxWidth: wide ? 420 : double.infinity),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              style:
                  const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Buscar negocio...',
                hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded,
                    color: AppColors.textMuted, size: 20),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),

        // ── Lista ──
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
                  ? _EmptyState(hasSearch: _search.isNotEmpty)
                  : ListView(
                      padding: wide
                          ? const EdgeInsets.fromLTRB(32, 24, 32, 32)
                          : const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      children: [
                        if (_nearby.isNotEmpty) ...[
                          const _SectionLabel(
                            label: 'CERCA DE TI',
                            icon: Icons.location_on_rounded,
                          ),
                          const SizedBox(height: 10),
                          ...tilesFor(_nearby),
                          const SizedBox(height: 6),
                        ],
                        if (_rest.isNotEmpty) ...[
                          const _SectionLabel(label: 'TODAS'),
                          const SizedBox(height: 10),
                          ...tilesFor(_rest),
                        ],
                      ],
                    ),
        ),
      ],
    );

    if (wide) {
      return ClientWebShell(
        current: ClientSection.stores,
        user: widget.user,
        child: body,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        elevation: 4,
        shape: const CircleBorder(),
        onPressed: () => context.push(
          '/client/qr',
          extra: {'userId': widget.user.uid, 'userName': widget.user.name},
        ),
        child: const Icon(
          Icons.qr_code_scanner_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _BottomBar(
        activeTab: 1,
        onInicio: () => context.go('/client/home'),
        onPromos: () => context.push(
          '/client/promotions',
          extra: widget.user.businessIds,
        ),
        onPerfil: () {},
      ),
      body: body,
    );
  }
}

// ──────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData? icon;

  const _SectionLabel({required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: AppColors.primary),
          const SizedBox(width: 4),
        ],
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
class _BusinessTile extends StatelessWidget {
  final Business business;
  final Membership? member;
  final double? distance;

  const _BusinessTile({
    required this.business,
    required this.member,
    this.distance,
  });

  static const _gradients = [
    LinearGradient(
      colors: [Color(0xFF5B21B6), Color(0xFF7C3AED)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF5B21B6), Color(0xFF9B6BFF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF0F0F0E), Color(0xFF2A2A27)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF4C1D95), Color(0xFF7C3AED)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF881337), Color(0xFFD1343A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF15131C), Color(0xFF7C3AED)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ];

  static const _defaultIcons = [
    Icons.storefront_rounded,
    Icons.local_cafe_rounded,
    Icons.local_pizza_rounded,
    Icons.restaurant_rounded,
    Icons.shopping_bag_rounded,
    Icons.spa_rounded,
  ];

  int get _idx => business.name.codeUnitAt(0) % _gradients.length;
  LinearGradient get _gradient => _gradients[_idx];
  IconData get _icon {
    final t =
        '${business.name.toLowerCase()} ${business.description.toLowerCase()}';
    if (t.contains('café') || t.contains('coffee') || t.contains('cafet')) {
      return Icons.local_cafe_rounded;
    }
    if (t.contains('pizza')) return Icons.local_pizza_rounded;
    if (t.contains('jug') || t.contains('frut')) return Icons.local_bar_rounded;
    if (t.contains('rest') || t.contains('comid')) {
      return Icons.restaurant_rounded;
    }
    if (t.contains('ropa') || t.contains('moda')) {
      return Icons.shopping_bag_rounded;
    }
    return _defaultIcons[_idx];
  }

  String get _category {
    final t =
        '${business.name.toLowerCase()} ${business.description.toLowerCase()}';
    if (t.contains('café') || t.contains('coffee') || t.contains('cafet')) {
      return 'Cafetería';
    }
    if (t.contains('pizza')) return 'Pizzería';
    if (t.contains('jug') || t.contains('frut')) return 'Juguería';
    if (t.contains('rest') || t.contains('comid')) return 'Restaurante';
    if (t.contains('ropa') || t.contains('moda')) return 'Moda';
    if (business.description.isNotEmpty) return business.description;
    return 'Negocio';
  }

  String _formatDist(double m) {
    if (m < 1000) return '${m.round()} m';
    return '${(m / 1000).toStringAsFixed(1)} km';
  }

  String _formatPts(int pts) {
    if (pts >= 1000) {
      return '${pts ~/ 1000},${(pts % 1000).toString().padLeft(3, '0')}';
    }
    return '$pts';
  }

  /// Saldo principal del tile según los programas de la tienda.
  (String, String) get _mainBalance {
    final p = business.programs;
    final m = member;
    if (p.pointsEnabled) return (_formatPts(m?.points ?? 0), 'PUNTOS');
    if (p.stampsEnabled) {
      return ('${m?.stamps ?? 0}/${p.stampsRequired}', 'SELLOS');
    }
    if (p.cashbackEnabled) {
      return (formatSoles(m?.cashbackCents ?? 0), 'CASHBACK');
    }
    return ('—', '');
  }

  @override
  Widget build(BuildContext context) {
    final p = business.programs;
    final (mainValue, mainLabel) = _mainBalance;
    final stamps = member?.stamps ?? 0;
    final stampRewards = member?.stampRewards ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.cardLg),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 20,
            offset: Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.cardLg),
        child: Material(
          color: Colors.white,
          child: InkWell(
            onTap: () => context
                .push('/client/store', extra: {'businessId': business.id}),
            child: Column(
              children: [
                // ── Header ──
                Stack(
                  children: [
                    if (business.bannerBase64 != null)
                      Positioned.fill(
                        child: Image.memory(
                          base64Decode(business.bannerBase64!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                      decoration: BoxDecoration(
                        gradient: business.bannerBase64 != null
                            ? LinearGradient(
                                colors: [
                                  Colors.black.withValues(alpha: 0.55),
                                  Colors.black.withValues(alpha: 0.35),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : _gradient,
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: business.logoBase64 != null
                                    ? Image.memory(
                                        base64Decode(business.logoBase64!),
                                        fit: BoxFit.cover,
                                      )
                                    : Icon(_icon,
                                        color: Colors.white, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      business.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      distance != null
                                          ? '$_category · ${_formatDist(distance!)}'
                                          : _category,
                                      style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.75),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    mainValue,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -1,
                                      height: 1,
                                    ),
                                  ),
                                  Text(
                                    mainLabel,
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.65),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          // Progreso de la tarjeta de sellos
                          if (p.stampsEnabled) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    stampRewards > 0
                                        ? '🎁 Tienes un regalo por reclamar'
                                        : 'Faltan ${p.stampsRequired - stamps} '
                                            'visitas para: ${p.stampReward}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.85),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: stamps / p.stampsRequired,
                                minHeight: 6,
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.2),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                // ── Footer: cashback real + entrar a la tienda ──
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      if (p.cashbackEnabled) ...[
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.amberTint,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.monetization_on_outlined,
                              color: AppColors.amberText, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Cashback',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              formatSoles(member?.cashbackCents ?? 0),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.amberText,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ] else
                        Text(
                          member == null
                              ? 'Toca para ver la tienda'
                              : '${member!.visits} compras registradas',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                      const Spacer(),
                      const Text(
                        'Ver tienda',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: AppColors.primary),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool hasSearch;
  const _EmptyState({required this.hasSearch});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.greenTint,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.storefront_rounded,
                  color: AppColors.primary, size: 38),
            ),
            const SizedBox(height: 20),
            Text(
              hasSearch ? 'Sin resultados' : 'No tienes tiendas inscritas',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasSearch
                  ? 'Intenta con otro nombre'
                  : 'Toca el botón + para unirte a tu primera tienda',
              style:
                  const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final int activeTab;
  final VoidCallback onInicio;
  final VoidCallback onPromos;
  final VoidCallback onPerfil;

  const _BottomBar({
    required this.activeTab,
    required this.onInicio,
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
              icon: Icons.home_rounded,
              label: 'Inicio',
              active: activeTab == 0,
              onTap: onInicio,
            ),
            _NavItem(
              icon: Icons.storefront_rounded,
              label: 'Tiendas',
              active: activeTab == 1,
              onTap: () {},
            ),
            const SizedBox(width: 56),
            _NavItem(
              icon: Icons.local_offer_rounded,
              label: 'Promos',
              active: activeTab == 3,
              onTap: onPromos,
            ),
            _NavItem(
              icon: Icons.person_rounded,
              label: 'Perfil',
              active: activeTab == 4,
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
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
