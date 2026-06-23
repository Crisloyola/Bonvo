import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:bonvo/config/themes/app_theme.dart';
import 'package:bonvo/features/auth/domain/entities/auth_user.dart';
import 'package:bonvo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bonvo/features/auth/presentation/bloc/auth_state.dart';
import 'package:bonvo/features/business/domain/entities/business.dart';
import 'package:bonvo/features/business/domain/repositories/business_repository.dart';
import 'package:bonvo/features/points/domain/entities/transaction.dart';
import 'package:bonvo/features/points/domain/repositories/points_repository.dart';
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
  Map<String, int> _pointsByBusiness = {};
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

    // 2. Calcular puntos por negocio desde transacciones
    final txResult = await getIt<PointsRepository>()
        .getUserTransactions(widget.user.uid);
    final Map<String, int> pointsByBiz = {};
    txResult.fold((_) {}, (txs) {
      for (final tx in txs) {
        final delta =
            tx.type == TransactionType.earn ? tx.points : -tx.points;
        pointsByBiz[tx.businessId] =
            (pointsByBiz[tx.businessId] ?? 0) + delta;
      }
    });

    // 3. Posición GPS
    Position? pos;
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.whileInUse ||
          perm == LocationPermission.always) {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
          ),
        );
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _businesses = businesses;
        _pointsByBusiness = pointsByBiz;
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
      ..sort((a, b) =>
          (_distanceTo(a) ?? 0).compareTo(_distanceTo(b) ?? 0));
  }

  List<Business> get _rest {
    final nearbyIds = _nearby.map((b) => b.id).toSet();
    return _filtered.where((b) => !nearbyIds.contains(b.id)).toList();
  }

  @override
  Widget build(BuildContext context) {
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
      body: Column(
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
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Buscar negocio...',
                  hintStyle: TextStyle(
                      color: AppColors.textMuted, fontSize: 14),
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
                        padding:
                            const EdgeInsets.fromLTRB(20, 16, 20, 24),
                        children: [
                          if (_nearby.isNotEmpty) ...[
                            const _SectionLabel(
                              label: 'CERCA DE TI',
                              icon: Icons.location_on_rounded,
                            ),
                            const SizedBox(height: 10),
                            ..._nearby.map((b) => _BusinessTile(
                                  business: b,
                                  points:
                                      _pointsByBusiness[b.id] ?? 0,
                                  distance: _distanceTo(b),
                                )),
                            const SizedBox(height: 6),
                          ],
                          if (_rest.isNotEmpty) ...[
                            const _SectionLabel(label: 'TODAS'),
                            const SizedBox(height: 10),
                            ..._rest.map((b) => _BusinessTile(
                                  business: b,
                                  points:
                                      _pointsByBusiness[b.id] ?? 0,
                                  distance: _distanceTo(b),
                                )),
                          ],
                        ],
                      ),
          ),
        ],
      ),
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
  final int points;
  final double? distance;

  const _BusinessTile({
    required this.business,
    required this.points,
    this.distance,
  });

  static const _colors = [
    Color(0xFFF59E0B),
    AppColors.primary,
    Color(0xFFDC2626),
    Color(0xFF0284C7),
    Color(0xFF7C3AED),
    Color(0xFF0D9488),
  ];
  static const _bgColors = [
    Color(0xFFFEF3C7),
    AppColors.greenTint,
    Color(0xFFFEE2E2),
    Color(0xFFE0F2FE),
    Color(0xFFEDE9FE),
    Color(0xFFCCFBF1),
  ];
  static const _defaultIcons = [
    Icons.local_cafe_rounded,
    Icons.storefront_rounded,
    Icons.local_pizza_rounded,
    Icons.restaurant_rounded,
    Icons.shopping_bag_rounded,
    Icons.spa_rounded,
  ];

  int get _colorIdx =>
      business.name.codeUnitAt(0) % _colors.length;

  Color get _color => _colors[_colorIdx];
  Color get _bgColor => _bgColors[_colorIdx];

  IconData get _icon {
    final t =
        '${business.name.toLowerCase()} ${business.description.toLowerCase()}';
    if (t.contains('café') ||
        t.contains('coffee') ||
        t.contains('cafet')) {
      return Icons.local_cafe_rounded;
    }
    if (t.contains('pizza')) { return Icons.local_pizza_rounded; }
    if (t.contains('jug') ||
        t.contains('frut') ||
        t.contains('natur')) {
      return Icons.local_bar_rounded;
    }
    if (t.contains('rest') || t.contains('comid')) {
      return Icons.restaurant_rounded;
    }
    if (t.contains('ropa') || t.contains('moda')) {
      return Icons.shopping_bag_rounded;
    }
    return _defaultIcons[_colorIdx];
  }

  String get _category {
    final t =
        '${business.name.toLowerCase()} ${business.description.toLowerCase()}';
    if (t.contains('café') ||
        t.contains('coffee') ||
        t.contains('cafet')) {
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
    if (m < 1000) return 'A ${m.round()} m';
    return 'A ${(m / 1000).toStringAsFixed(1)} km';
  }

  String _formatPts(int pts) {
    if (pts >= 1000) {
      return '${pts ~/ 1000},${(pts % 1000).toString().padLeft(3, '0')}';
    }
    return '$pts';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          // Avatar con ícono de categoría
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _bgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_icon, color: _color, size: 26),
          ),

          const SizedBox(width: 12),

          // Nombre + distancia + categoría
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  business.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      distance != null
                          ? Icons.location_on_rounded
                          : Icons.store_rounded,
                      size: 12,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 3),
                    if (distance != null) ...[
                      Text(
                        _formatDist(distance!),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Text(
                        ' · ',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                    Flexible(
                      child: Text(
                        _category,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Puntos por negocio
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatPts(points),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: -0.5,
                ),
              ),
              const Text(
                'PUNTOS',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 0.5,
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
              hasSearch
                  ? 'Sin resultados'
                  : 'No tienes tiendas inscritas',
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
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
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
