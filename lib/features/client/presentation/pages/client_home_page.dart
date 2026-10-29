import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:bonvo/config/themes/app_theme.dart';
import 'package:bonvo/core/services/fcm_service.dart';
import 'package:bonvo/core/services/notification_service.dart';
import 'package:bonvo/core/services/proximity_service.dart';
import 'package:bonvo/core/services/storage_service.dart';
import 'package:bonvo/core/utils/responsive.dart';
import 'package:bonvo/features/auth/domain/entities/auth_user.dart';
import 'package:bonvo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bonvo/features/auth/presentation/bloc/auth_event.dart';
import 'package:bonvo/features/auth/presentation/bloc/auth_state.dart';
import 'package:bonvo/features/business/domain/entities/business.dart';
import 'package:bonvo/features/business/domain/repositories/business_repository.dart';
import 'package:bonvo/features/client/presentation/widgets/client_web_shell.dart';
import 'package:bonvo/features/client/presentation/widgets/loyalty_card_widget.dart';
import 'package:bonvo/features/loyalty/data/loyalty_repository.dart';
import 'package:bonvo/features/promotions/domain/entities/promotion.dart';
import 'package:bonvo/features/promotions/domain/repositories/promotions_repository.dart';
import 'package:bonvo/injection/injection.dart';

class ClientHomePage extends StatefulWidget {
  const ClientHomePage({super.key});

  @override
  State<ClientHomePage> createState() => _ClientHomePageState();
}

class _ClientHomePageState extends State<ClientHomePage> {
  final ProximityService _proximity = ProximityService();
  bool _proximityStarted = false;
  bool _fcmStarted = false;
  bool _notifStarted = false;
  final List<StreamSubscription> _announcementSubs = [];
  final Map<String, DateTime> _listeningSince = {};
  final Map<String, String?> _businessLogos = {};
  final Map<String, String> _businessNames = {};

  Future<void> _startFcmIfNeeded(String uid) async {
    if (_fcmStarted || uid.isEmpty) return;
    _fcmStarted = true;
    await getIt<FcmService>().init(uid);
  }

  Future<void> _initNotifIfNeeded(List<String> businessIds) async {
    getIt<NotificationService>().setBusinessIds(businessIds);
    if (_notifStarted) return;
    _notifStarted = true;
    await getIt<NotificationService>().init();
  }

  Future<void> _fetchBusinessMeta(String businessId) async {
    if (_businessLogos.containsKey(businessId)) return;
    final result = await getIt<BusinessRepository>().getBusiness(businessId);
    result.fold(
      (_) {
        _businessLogos[businessId] = null;
        _businessNames[businessId] = '';
      },
      (b) {
        _businessLogos[businessId] = b.logoBase64;
        _businessNames[businessId] = b.name;
      },
    );
  }

  void _listenAnnouncements(List<String> businessIds) {
    for (final bId in businessIds) {
      if (_listeningSince.containsKey(bId)) continue;
      _listeningSince[bId] = DateTime.now();
      _fetchBusinessMeta(bId);
      final sub = FirebaseFirestore.instance
          .collection('businesses')
          .doc(bId)
          .collection('announcements')
          .orderBy('sentAt', descending: true)
          .limit(1)
          .snapshots()
          .listen((snap) {
        if (snap.docs.isEmpty) return;
        final doc = snap.docs.first;
        final sentAt =
            (doc.data()['sentAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
        if (sentAt.isBefore(_listeningSince[bId]!)) return;
        final title =
            doc.data()['title'] as String? ?? 'Aviso de tu tienda';
        final body = doc.data()['body'] as String? ?? '';
        getIt<NotificationService>().show(NotifItem(
          title: title,
          body: body,
          businessId: bId,
          businessName: _businessNames[bId] ?? '',
          logoBase64: _businessLogos[bId],
          at: DateTime.now(),
        ));
      });
      _announcementSubs.add(sub);
    }
  }

  Future<void> _startProximityIfNeeded(List<String> businessIds) async {
    // La alerta de cercanía no está disponible en web
    if (kIsWeb || _proximityStarted || businessIds.isEmpty) return;
    _proximityStarted = true;
    await _proximity.init();
    final businesses = <Business>[];
    for (final id in businessIds) {
      final result = await getIt<BusinessRepository>().getBusiness(id);
      result.fold((_) {}, (b) {
        if (b.hasLocation) businesses.add(b);
      });
    }
    if (businesses.isNotEmpty) _proximity.startMonitoring(businesses);
  }

  @override
  void dispose() {
    _proximity.stopMonitoring();
    for (final s in _announcementSubs) {
      s.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;
        if (user == null) return const SizedBox.shrink();

        _startFcmIfNeeded(user.uid);
        _initNotifIfNeeded(user.businessIds);
        _startProximityIfNeeded(user.businessIds);
        _listenAnnouncements(user.businessIds);

        final wide = context.isWide;
        final qrExtra = {'userId': user.uid, 'userName': user.name};

        // Tarjeta de fidelización
        final card = StreamBuilder<int>(
          stream: getIt<LoyaltyRepository>()
              .watchTotalPoints(user.uid, user.businessIds),
          initialData: 0,
          builder: (context, snap) {
            return LoyaltyCardWidget(
              userId: user.uid,
              userName: user.name,
              points: snap.data ?? 0,
              onTapQr: () => context.push('/client/qr', extra: qrExtra),
            );
          },
        );

        // ── 3 Accesos rápidos ──
        final quickActions = Row(
          children: [
            Expanded(
              child: _QuickAction(
                icon: Icons.qr_code_scanner_rounded,
                label: 'Escanear',
                color: AppColors.primary,
                bgColor: AppColors.greenTint,
                onTap: () => context.push('/client/scan-business'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickAction(
                icon: Icons.card_giftcard_rounded,
                label: 'Promos',
                color: AppColors.amberText,
                bgColor: AppColors.amberTint,
                onTap: () => context.push(
                  '/client/promotions',
                  extra: user.businessIds,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickAction(
                icon: Icons.storefront_rounded,
                label: 'Mis tiendas',
                color: const Color(0xFF5B21B6),
                bgColor: const Color(0xFFEDE5FF),
                onTap: () => context.push('/client/tiendas'),
              ),
            ),
          ],
        );

        // ── Para ti ──
        final forYou = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Para ti',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push(
                    '/client/promotions',
                    extra: user.businessIds,
                  ),
                  child: const Text(
                    'Ver todo',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (user.businessIds.isEmpty)
              _JoinBanner()
            else
              _PromosPreview(businessIds: user.businessIds),
          ],
        );

        if (wide) {
          // Escritorio: tarjeta y accesos a la izquierda, "Para ti" a la derecha
          return ClientWebShell(
            current: ClientSection.home,
            user: user,
            child: Column(
              children: [
                _Header(user: user),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  card,
                                  const SizedBox(height: 20),
                                  quickActions,
                                ],
                              ),
                            ),
                            const SizedBox(width: 32),
                            Expanded(flex: 6, child: forYou),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppColors.primary,
            elevation: 4,
            shape: const CircleBorder(),
            onPressed: () => context.push('/client/scan-business'),
            child: const Icon(
              Icons.qr_code_scanner_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: _BottomBar(
            onTiendas: () => context.push('/client/tiendas'),
            onPromos: () => context.push(
              '/client/promotions',
              extra: user.businessIds,
            ),
            onPerfil: () => _showProfileSheet(context),
          ),
          body: Column(
            children: [
              // ── Header blanco ──
              _Header(user: user),

              // ── Contenido scrollable ──
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      card,
                      const SizedBox(height: 20),
                      quickActions,
                      const SizedBox(height: 28),
                      forYou,
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

  void _showProfileSheet(BuildContext ctx) {
    showModalBottomSheet<void>(
      context: ctx,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.history_rounded,
                  color: AppColors.primary),
              title: const Text('Historial de puntos'),
              onTap: () {
                Navigator.pop(ctx);
                final authState = ctx.read<AuthBloc>().state;
                if (authState is AuthAuthenticated) {
                  ctx.push('/client/history',
                      extra: {'userId': authState.user.uid});
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout_rounded,
                  color: AppColors.error),
              title: const Text('Cerrar sesión',
                  style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(ctx);
                _proximity.stopMonitoring();
                ctx.read<AuthBloc>().add(const AuthLogoutRequested());
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
class _Header extends StatefulWidget {
  final AuthUser user;
  const _Header({required this.user});

  @override
  State<_Header> createState() => _HeaderState();
}

class _HeaderState extends State<_Header> {
  bool _uploading = false;

  Future<void> _changePhoto() async {
    setState(() => _uploading = true);
    try {
      final base64 = await getIt<StorageService>().pickProfilePhoto();
      if (base64 != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.user.uid)
            .update({'photoBase64': base64});
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Color get _avatarColor {
    final colors = [
      const Color(0xFF2A2A27),
      const Color(0xFF5B21B6),
      const Color(0xFF7C3AED),
      AppColors.primary,
      const Color(0xFFE5484D),
    ];
    final idx = widget.user.name.isNotEmpty
        ? widget.user.name.codeUnitAt(0) % colors.length
        : 0;
    return colors[idx];
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.user.name.isNotEmpty
        ? widget.user.name.trim()[0].toUpperCase()
        : '?';
    final firstName = widget.user.name.split(' ').first;

    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 16, 14),
          child: Row(
            children: [
              // Avatar
              GestureDetector(
                onTap: _uploading ? null : _changePhoto,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _avatarColor,
                    shape: BoxShape.circle,
                  ),
                  child: _uploading
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : ClipOval(
                          child: widget.user.photoBase64 != null
                              ? Image.memory(
                                  base64Decode(widget.user.photoBase64!),
                                  fit: BoxFit.cover,
                                )
                              : Center(
                                  child: Text(
                                    initial,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                        ),
                ),
              ),

              const SizedBox(width: 12),

              // Saludo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hola,',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.2,
                      ),
                    ),
                    Text(
                      firstName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.4,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),

              // Campana con badge
              ValueListenableBuilder<int>(
                valueListenable:
                    getIt<NotificationService>().unreadCount,
                builder: (context, notifCount, _) {
                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: AppColors.textPrimary,
                          size: 26,
                        ),
                        onPressed: () => _openNotifSheet(context),
                      ),
                      if (notifCount > 0)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            constraints: const BoxConstraints(
                                minWidth: 16, minHeight: 16),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              notifCount > 99 ? '99+' : '$notifCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openNotifSheet(BuildContext context) {
    final svc = getIt<NotificationService>();
    svc.clearCount();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NotifSheet(items: List.of(svc.items)),
    );
  }
}

// ──────────────────────────────────────────────────────────────
class _NotifSheet extends StatelessWidget {
  final List<NotifItem> items;
  const _NotifSheet({required this.items});

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'Ahora';
    if (d.inMinutes < 60) return 'Hace ${d.inMinutes} min';
    if (d.inHours < 24) return 'Hace ${d.inHours} h';
    if (d.inDays == 1) return 'Ayer';
    return 'Hace ${d.inDays} días';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text('Notificaciones',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                  const Spacer(),
                  if (items.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/client/promotions',
                            extra: getIt<NotificationService>().businessIds);
                      },
                      child: const Text('Ver promos',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: items.isEmpty
                  ? const Center(
                      child: Text('Sin notificaciones',
                          style: TextStyle(color: AppColors.textSecondary)),
                    )
                  : ListView.separated(
                      controller: ctrl,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final n = items[i];
                        final logoBytes = n.logoBase64 != null
                            ? base64Decode(n.logoBase64!)
                            : null;
                        return ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 6),
                          leading: CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.greenTint,
                            backgroundImage: logoBytes != null
                                ? MemoryImage(logoBytes)
                                : null,
                            child: logoBytes == null
                                ? const Icon(Icons.storefront_rounded,
                                    color: AppColors.primary, size: 20)
                                : null,
                          ),
                          title: Text(n.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppColors.textPrimary)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (n.body.isNotEmpty)
                                Text(n.body,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary)),
                              Text(_timeAgo(n.at),
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted)),
                            ],
                          ),
                          onTap: () {
                            Navigator.pop(ctx);
                            ctx.push('/client/promotions',
                                extra: getIt<NotificationService>()
                                    .businessIds);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
class _PromosPreview extends StatefulWidget {
  final List<String> businessIds;
  const _PromosPreview({required this.businessIds});

  @override
  State<_PromosPreview> createState() => _PromosPreviewState();
}

class _PromosPreviewState extends State<_PromosPreview> {
  late final Future<List<Promotion>> _future;

  @override
  void initState() {
    super.initState();
    _future = getIt<PromotionsRepository>()
        .getClientPromotions(widget.businessIds)
        .then((either) => either.fold((_) => [], (list) => list));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Promotion>>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final promos = snap.data!.where((p) => p.active).toList();
        if (promos.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              children: [
                Icon(Icons.local_offer_outlined,
                    color: AppColors.textMuted, size: 22),
                SizedBox(width: 12),
                Text(
                  'No hay promociones activas',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }
        return Column(
          children: promos
              .take(3)
              .map((p) => _PromoCard(promo: p))
              .toList(),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────
class _PromoCard extends StatelessWidget {
  final Promotion promo;
  const _PromoCard({required this.promo});

  static const _iconColors = [
    Color(0xFF2A2A27),
    AppColors.primary,
    Color(0xFF7C3AED),
    Color(0xFF5B21B6),
  ];
  static const _bgColors = [
    Color(0xFFECECEC),
    AppColors.greenTint,
    Color(0xFFEDE5FF),
    Color(0xFFEDE5FF),
  ];
  static const _icons = [
    Icons.local_cafe_rounded,
    Icons.card_giftcard_rounded,
    Icons.local_offer_rounded,
    Icons.restaurant_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final idx = promo.title.codeUnitAt(0) % _iconColors.length;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          // Ícono
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _bgColors[idx],
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_icons[idx], color: _iconColors[idx], size: 24),
          ),

          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  promo.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  promo.businessName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Badge pts
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.amberTint,
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            child: Text(
              '${promo.pointsCost} pts',
              style: const TextStyle(
                color: AppColors.amberText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
class _JoinBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/client/scan-business'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppColors.gradientAccent,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: [
            BoxShadow(
              color: AppColors.amber.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.store_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Únete a una tienda',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Escanea el QR para acumular puntos',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final VoidCallback onTiendas;
  final VoidCallback onPromos;
  final VoidCallback onPerfil;

  const _BottomBar({
    required this.onTiendas,
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
              active: true,
              onTap: () {},
            ),
            _NavItem(
              icon: Icons.storefront_rounded,
              label: 'Tiendas',
              onTap: onTiendas,
            ),
            const SizedBox(width: 56), // hueco para el FAB
            _NavItem(
              icon: Icons.local_offer_rounded,
              label: 'Promos',
              onTap: onPromos,
            ),
            _NavItem(
              icon: Icons.person_rounded,
              label: 'Perfil',
              onTap: onPerfil,
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
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
