import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bonvo/config/themes/app_theme.dart';
import 'package:bonvo/core/utils/responsive.dart';
import 'package:bonvo/core/widgets/profile_sheets.dart';
import 'package:bonvo/features/business/domain/entities/business.dart';
import 'package:bonvo/features/business/domain/repositories/business_repository.dart';
import 'package:bonvo/features/business/presentation/widgets/business_web_shell.dart';
import 'package:bonvo/features/business/presentation/widgets/member_sheet.dart';
import 'package:bonvo/features/loyalty/data/loyalty_repository.dart';
import 'package:bonvo/features/loyalty/domain/loyalty.dart';
import 'package:bonvo/injection/injection.dart';

class ClientListPage extends StatefulWidget {
  final String businessId;
  final String businessName;

  const ClientListPage({
    super.key,
    required this.businessId,
    this.businessName = '',
  });

  @override
  State<ClientListPage> createState() => _ClientListPageState();
}

class _ClientListPageState extends State<ClientListPage> {
  List<ClientSummary> _clients = [];
  bool _loading = true;
  String _search = '';
  Business? _business;
  Map<String, Membership> _members = {};
  StreamSubscription<List<Membership>>? _membersSub;

  @override
  void initState() {
    super.initState();
    _load();
    getIt<BusinessRepository>().getBusiness(widget.businessId).then((r) {
      if (mounted) r.fold((_) {}, (b) => setState(() => _business = b));
    });
    // Saldos por cliente en esta tienda, en vivo
    _membersSub = getIt<LoyaltyRepository>()
        .watchMembers(widget.businessId)
        .listen((list) =>
            setState(() => _members = {for (final m in list) m.userId: m}));
  }

  @override
  void dispose() {
    _membersSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result =
        await getIt<BusinessRepository>().getBusinessClients(widget.businessId);
    result.fold((_) {}, (list) => setState(() => _clients = list));
    setState(() => _loading = false);
  }

  List<ClientSummary> get _filtered {
    if (_search.isEmpty) return _clients;
    final q = _search.toLowerCase();
    return _clients.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  static const _avatarColors = [
    Color(0xFF9B6BFF),
    Color(0xFF2A2A27),
    Color(0xFF7C3AED),
    Color(0xFFE5484D),
    Color(0xFF9B6BFF),
  ];

  static String _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  static String _lastVisit(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return 'hoy';
    if (diff.inDays == 1) return 'ayer';
    if (diff.inDays < 7) return 'hace ${diff.inDays} días';
    if (diff.inDays < 14) return 'hace 1 sem';
    if (diff.inDays < 30) {
      return 'hace ${(diff.inDays / 7).floor()} sem';
    }
    final months = (diff.inDays / 30).floor();
    return months == 1 ? 'hace 1 mes' : 'hace $months meses';
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final wide = context.isWide;

    _ClientTile tileFor(ClientSummary c) => _ClientTile(
          name: c.name,
          initials: _initials(c.name),
          lastVisitLabel: _lastVisit(c.lastVisit),
          balances: _business == null
              ? ''
              : memberBalances(_business!.programs, _members[c.userId]),
          color: _avatarColors[c.name.hashCode.abs() % _avatarColors.length],
          photoBase64: c.photoBase64,
          onTap: _business == null
              ? null
              : () => showMemberSheet(
                    context,
                    business: _business!,
                    userId: c.userId,
                    userName: c.name,
                  ),
        );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Header ──
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Clientes',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                if (_clients.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.greenTint,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_clients.length} activos',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // ── Buscador ──
        Padding(
          padding: wide
              ? const EdgeInsets.fromLTRB(20, 0, 20, 8)
              : const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(maxWidth: wide ? 420 : double.infinity),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  prefixIcon: const Icon(AppIcons.search,
                      size: 20, color: AppColors.textMuted),
                  hintText: 'Buscar cliente...',
                  fillColor: AppColors.background,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ),

        // ── Lista (cuadrícula en escritorio) ──
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
                  ? _EmptyState(searching: _search.isNotEmpty)
                  : wide
                      ? SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                          child: ResponsiveWrapGrid(
                            minItemWidth: 320,
                            children: filtered.map(tileFor).toList(),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) => tileFor(filtered[i]),
                        ),
        ),
      ],
    );

    if (wide) {
      return BusinessWebShell(
        current: BusinessSection.clients,
        businessId: widget.businessId,
        businessName: widget.businessName,
        child: ColoredBox(color: Colors.white, child: body),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        elevation: 4,
        shape: const CircleBorder(),
        onPressed: () => context.push('/business/scanner'),
        child: const Icon(AppIcons.scanner, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _BottomBar(
        onInicio: () => context.go('/business/home'),
        onPromos: () => context.push('/business/promotions', extra: {
          'businessId': widget.businessId,
          'businessName': widget.businessName,
        }),
        onPerfil: () => showBusinessProfileSheet(
          context,
          businessId: widget.businessId,
          businessName: widget.businessName,
        ),
      ),
      body: body,
    );
  }
}

// ──────────────────────────────────────────────────────────────
class _ClientTile extends StatelessWidget {
  final String name;
  final String initials;
  final String lastVisitLabel;
  final String balances;
  final Color color;
  final String? photoBase64;
  final VoidCallback? onTap;

  const _ClientTile({
    required this.name,
    required this.initials,
    required this.lastVisitLabel,
    required this.balances,
    required this.color,
    this.photoBase64,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final photoBytes = photoBase64 != null ? base64Decode(photoBase64!) : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            children: [
              // Avatar circular
              CircleAvatar(
                radius: 22,
                backgroundColor: color,
                backgroundImage:
                    photoBytes != null ? MemoryImage(photoBytes) : null,
                child: photoBytes == null
                    ? Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      )
                    : null,
              ),

              const SizedBox(width: 12),

              // Nombre + última visita
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Última visita: $lastVisitLabel',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (balances.isNotEmpty)
                      Text(
                        balances,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),

              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool searching;
  const _EmptyState({required this.searching});

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
              color: AppColors.greenTint,
              shape: BoxShape.circle,
            ),
            child: Icon(
              searching ? AppIcons.searchOff : AppIcons.clients,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            searching ? 'Sin resultados' : 'Aún no tienes clientes',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searching
                ? 'Prueba con otro nombre'
                : 'Comienza acreditando puntos\npara que aparezcan aquí',
            textAlign: TextAlign.center,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final VoidCallback onInicio;
  final VoidCallback onPromos;
  final VoidCallback onPerfil;

  const _BottomBar({
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
              icon: AppIcons.dashboard,
              label: 'Inicio',
              onTap: onInicio,
            ),
            _NavItem(
              icon: AppIcons.clients,
              label: 'Clientes',
              active: true,
              onTap: () {},
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
                  fontSize: 10, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
