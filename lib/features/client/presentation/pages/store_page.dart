import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:bonvo/config/themes/app_theme.dart';
import 'package:bonvo/core/services/fcm_service.dart';
import 'package:bonvo/core/utils/responsive.dart';
import 'package:bonvo/features/auth/domain/entities/auth_user.dart';
import 'package:bonvo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bonvo/features/auth/presentation/bloc/auth_event.dart';
import 'package:bonvo/features/auth/presentation/bloc/auth_state.dart';
import 'package:bonvo/features/business/domain/entities/business.dart';
import 'package:bonvo/features/business/domain/repositories/business_repository.dart';
import 'package:bonvo/features/client/presentation/widgets/client_web_shell.dart';
import 'package:bonvo/features/loyalty/data/loyalty_repository.dart';
import 'package:bonvo/features/loyalty/domain/loyalty.dart';
import 'package:bonvo/features/loyalty/presentation/request_status_notifier.dart';
import 'package:bonvo/features/loyalty/presentation/widgets/loyalty_widgets.dart';
import 'package:bonvo/features/points/domain/usecases/enroll_in_business.dart';
import 'package:bonvo/features/promotions/domain/entities/promotion.dart';
import 'package:bonvo/features/promotions/domain/repositories/promotions_repository.dart';
import 'package:bonvo/features/promotions/presentation/widgets/promotion_card.dart';
import 'package:bonvo/injection/injection.dart';

/// Tienda vista por el cliente: se llega escaneando su QR o desde
/// "Mis tiendas". Si no está inscrito, puede unirse; si lo está, ve sus
/// saldos, registra compras, canjea regalos y sigue sus solicitudes.
class StorePage extends StatefulWidget {
  final String businessId;
  const StorePage({super.key, required this.businessId});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  final _repo = getIt<LoyaltyRepository>();
  Business? _business;
  List<Promotion> _promos = [];
  String? _error;
  bool _enrolling = false;

  // Se crean una sola vez para no re-suscribirse en cada rebuild
  String? _streamsUid;
  late Stream<Membership?> _memberStream;
  late Stream<List<LoyaltyRequest>> _requestsStream;

  void _ensureStreams(String uid) {
    if (_streamsUid == uid) return;
    _streamsUid = uid;
    _memberStream =
        _repo.watchMembership(widget.businessId, uid).asBroadcastStream();
    _requestsStream =
        _repo.watchUserRequests(widget.businessId, uid).asBroadcastStream();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result =
        await getIt<BusinessRepository>().getBusiness(widget.businessId);
    final promos = await getIt<PromotionsRepository>()
        .getBusinessPromotions(widget.businessId);
    if (!mounted) return;
    setState(() {
      result.fold(
        (_) => _error = 'No encontramos esta tienda.',
        (b) => _business = b,
      );
      _promos =
          promos.fold((_) => [], (l) => l.where((p) => p.active).toList());
    });
  }

  Future<void> _enroll(AuthUser user) async {
    setState(() => _enrolling = true);
    final result = await getIt<EnrollInBusiness>()(EnrollParams(
      userId: user.uid,
      businessId: widget.businessId,
      userName: user.name,
    ));
    if (!mounted) return;
    setState(() => _enrolling = false);
    result.fold(
      (f) => _snack(f.message, error: true),
      (_) {
        getIt<FcmService>().subscribeToBusinessTopic(widget.businessId);
        context.read<AuthBloc>().add(const AuthUserRefreshRequested());
      },
    );
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.error : AppColors.textPrimary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> _registerPurchase(AuthUser user, Business b) async {
    final options = b.programs.enabledPrograms;
    var amountCents = 0;
    LoyaltyProgram program;
    if (options.length == 1 && options.first == LoyaltyProgram.stamps) {
      // Solo tarjeta de sellos: es una visita, no hace falta preguntar nada
      program = LoyaltyProgram.stamps;
    } else {
      final choice = await showDialog<(int, LoyaltyProgram)>(
        context: context,
        builder: (_) => _PurchaseDialog(programs: b.programs),
      );
      if (choice == null) return;
      (amountCents, program) = choice;
    }
    try {
      await _repo.requestPurchase(
        businessId: b.id,
        businessName: b.name,
        userId: user.uid,
        userName: user.name,
        amountCents: amountCents,
        program: program,
      );
      _snack('Solicitud enviada. La tienda debe aprobarla.');
    } catch (e) {
      _snack('No se pudo enviar: $e', error: true);
    }
  }

  Future<void> _redeemReward(AuthUser user, Business b, Promotion p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Canjear regalo',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('¿Pedir "${p.title}" por ${p.pointsCost} pts?\n\n'
            'Los puntos se descuentan cuando la tienda te entregue el regalo.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Pedir canje'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _repo.requestReward(
        businessId: b.id,
        businessName: b.name,
        userId: user.uid,
        userName: user.name,
        rewardId: p.id,
        rewardTitle: p.title,
        rewardPoints: p.pointsCost,
      );
      _snack('Canje solicitado. Acércate a la tienda para recibirlo.');
    } catch (e) {
      _snack('No se pudo pedir el canje: $e', error: true);
    }
  }

  Future<void> _claimStampReward(AuthUser user, Business b) async {
    try {
      await _repo.requestStampReward(
        businessId: b.id,
        businessName: b.name,
        userId: user.uid,
        userName: user.name,
        rewardTitle: b.programs.stampReward.isEmpty
            ? 'Regalo de la tarjeta'
            : b.programs.stampReward,
      );
      _snack('Pediste tu regalo. La tienda lo confirmará al entregarlo.');
    } catch (e) {
      _snack('No se pudo pedir el regalo: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;
        if (user == null) return const SizedBox.shrink();
        getIt<RequestStatusNotifier>().start(user.uid, user.businessIds);
        final wide = context.isWide;

        Widget body;
        if (_error != null) {
          body = Center(child: Text(_error!));
        } else if (_business == null) {
          body = const Center(child: CircularProgressIndicator());
        } else {
          body = _buildContent(user, _business!, wide);
        }

        if (wide) {
          return ClientWebShell(
            current: ClientSection.stores,
            user: user,
            child: body,
          );
        }
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(_business?.name ?? 'Tienda'),
            leading: IconButton(
              icon: const Icon(AppIcons.back),
              onPressed: () => context.canPop()
                  ? context.pop()
                  : context.go('/client/tiendas'),
            ),
          ),
          body: body,
        );
      },
    );
  }

  Widget _buildContent(AuthUser user, Business b, bool wide) {
    _ensureStreams(user.uid);
    return StreamBuilder<Membership?>(
      stream: _memberStream,
      builder: (context, memberSnap) {
        if (memberSnap.connectionState == ConnectionState.waiting &&
            !memberSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final member = memberSnap.data;

        return StreamBuilder<List<LoyaltyRequest>>(
          stream: _requestsStream,
          builder: (context, reqSnap) {
            final requests = reqSnap.data ?? const <LoyaltyRequest>[];
            final children = member == null
                ? _joinSection(user, b)
                : _memberSections(user, b, member, requests, wide);
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  wide ? 32 : 16, wide ? 28 : 16, wide ? 32 : 16, 32),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _StoreHeader(business: b),
                      const SizedBox(height: 16),
                      ...children,
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _joinSection(AuthUser user, Business b) => [
        _Section(
          title: 'Lo que ganas en esta tienda',
          child: ProgramList(programs: b.programs),
        ),
        const SizedBox(height: 20),
        _enrolling
            ? const Center(child: CircularProgressIndicator())
            : FilledButton.icon(
                onPressed: () => _enroll(user),
                icon: const Icon(Icons.card_membership),
                label: const Text('Unirme a esta tienda'),
              ),
      ];

  List<Widget> _memberSections(AuthUser user, Business b, Membership m,
      List<LoyaltyRequest> requests, bool wide) {
    final p = b.programs;
    final pending = requests.where((r) => r.isPending).toList();
    final pendingPurchase = pending.any((r) => r.type == RequestType.purchase);
    final pendingStampReward =
        pending.any((r) => r.type == RequestType.stampReward);
    // Puntos apartados por canjes pendientes
    final reserved = pending
        .where((r) => r.type == RequestType.reward)
        .fold<int>(0, (a, r) => a + r.rewardPoints);
    final available = m.points - reserved;
    final rewards = _promos.where((x) => x.pointsCost > 0).toList();
    final offers = _promos.where((x) => x.pointsCost == 0).toList();

    final balances = <Widget>[
      if (p.pointsEnabled)
        _BalanceTile(
          icon: AppIcons.star,
          label: reserved > 0 ? 'Puntos ($reserved apartados)' : 'Puntos',
          value: '$available',
        ),
      if (p.cashbackEnabled)
        _BalanceTile(
          icon: AppIcons.coins,
          label: 'Saldo cashback',
          value: formatSoles(m.cashbackCents),
        ),
    ];

    return [
      // ── Saldos ──
      if (balances.isNotEmpty) ...[
        Row(
          children: [
            for (var i = 0; i < balances.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(child: balances[i]),
            ],
          ],
        ),
        const SizedBox(height: 12),
      ],
      if (p.stampsEnabled) ...[
        StampCard(
          stamps: m.stamps,
          required: p.stampsRequired,
          reward: p.stampReward,
          rewardsAvailable: m.stampRewards,
        ),
        if (m.stampRewards > 0) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed:
                pendingStampReward ? null : () => _claimStampReward(user, b),
            icon: const Icon(Icons.card_giftcard_rounded),
            label: Text(pendingStampReward
                ? 'Regalo pedido · espera la confirmación'
                : 'Reclamar mi regalo'),
          ),
        ],
        const SizedBox(height: 12),
      ],

      // ── Registrar compra ──
      if (p.anyEnabled) ...[
        FilledButton.icon(
          onPressed: pendingPurchase ? null : () => _registerPurchase(user, b),
          icon: const Icon(Icons.receipt_long_rounded),
          label: Text(pendingPurchase
              ? 'Tienes una solicitud pendiente'
              : (p.needsAmount
                  ? 'Registrar mi compra'
                  : 'Registrar mi visita')),
        ),
        const SizedBox(height: 6),
        Text(
          pendingPurchase
              ? 'La tienda debe aprobar tu solicitud anterior.'
              : 'La tienda verá tu solicitud y la aprobará.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 20),
      ] else
        const _Section(
          title: 'Programa',
          child: Text('Esta tienda aún no configuró su programa.',
              style: TextStyle(color: AppColors.textSecondary)),
        ),

      // ── Regalos por puntos ──
      if (p.pointsEnabled && rewards.isNotEmpty) ...[
        const _Title('Regalos por puntos'),
        const SizedBox(height: 10),
        ResponsiveWrapGrid(
          minItemWidth: 260,
          children: [
            for (final r in rewards)
              _RewardCard(
                promo: r,
                canRedeem: available >= r.pointsCost &&
                    !pending.any((x) => x.rewardId == r.id),
                pendingThis: pending.any((x) => x.rewardId == r.id),
                missing: r.pointsCost - available,
                onRedeem: () => _redeemReward(user, b, r),
              ),
          ],
        ),
        const SizedBox(height: 20),
      ],

      // ── Promociones informativas ──
      if (offers.isNotEmpty) ...[
        const _Title('Promociones'),
        const SizedBox(height: 10),
        ResponsiveWrapGrid(
          minItemWidth: 260,
          children: [for (final o in offers) PromotionCard(promo: o)],
        ),
        const SizedBox(height: 20),
      ],

      // ── Mis solicitudes ──
      const _Title('Mis solicitudes'),
      const SizedBox(height: 10),
      if (requests.isEmpty)
        const Text('Aún no registraste compras en esta tienda.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13))
      else
        for (final r in requests.take(10)) _RequestTile(request: r),
    ];
  }
}

// ──────────────────────────────────────────────────────────────
/// Registrar compra: el cliente elige a qué programa sumarla
/// (sello, cashback o puntos) y escribe el monto.
class _PurchaseDialog extends StatefulWidget {
  final LoyaltyPrograms programs;
  const _PurchaseDialog({required this.programs});

  @override
  State<_PurchaseDialog> createState() => _PurchaseDialogState();
}

class _PurchaseDialogState extends State<_PurchaseDialog> {
  final _ctrl = TextEditingController();
  int _cents = 0;
  LoyaltyProgram? _program;

  @override
  void initState() {
    super.initState();
    final options = widget.programs.enabledPrograms;
    // Con una sola opción no hay nada que elegir
    if (options.length == 1) _program = options.first;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    final value = double.tryParse(v.replaceAll(',', '.')) ?? 0;
    setState(() => _cents = (value * 100).round());
  }

  // El sello no depende del monto; puntos y cashback sí
  bool get _amountRequired => _program != LoyaltyProgram.stamps;

  bool get _canSend => _program != null && (!_amountRequired || _cents > 0);

  static IconData _icon(LoyaltyProgram p) => switch (p) {
        LoyaltyProgram.stamps => Icons.verified_outlined,
        LoyaltyProgram.cashback => AppIcons.coins,
        LoyaltyProgram.points => AppIcons.star,
      };

  @override
  Widget build(BuildContext context) {
    final p = widget.programs;
    final options = p.enabledPrograms;
    final preview =
        _program == null ? '' : p.earnFor(_cents, only: _program).describe();

    return AlertDialog(
      title: const Text('Registrar compra',
          style: TextStyle(fontWeight: FontWeight.w800)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (options.length > 1) ...[
              const Text('¿Qué quieres sumar con esta compra?',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 10),
              for (final o in options)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ProgramOption(
                    icon: _icon(o),
                    title: o.label,
                    subtitle: p.describeProgram(o),
                    selected: _program == o,
                    onTap: () => setState(() => _program = o),
                  ),
                ),
              const SizedBox(height: 8),
            ],
            Text(
              _amountRequired
                  ? '¿Cuánto pagaste?'
                  : '¿Cuánto pagaste? (opcional)',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _ctrl,
              autofocus: options.length == 1,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              onChanged: _onChanged,
              decoration: const InputDecoration(
                prefixText: 'S/ ',
                hintText: '0.00',
              ),
            ),
            if (preview.isNotEmpty && _canSend) ...[
              const SizedBox(height: 12),
              Text('Si la tienda aprueba: $preview',
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w700)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: _canSend
              ? () => Navigator.pop(context, (_cents, _program!))
              : null,
          child: const Text('Enviar'),
        ),
      ],
    );
  }
}

class _ProgramOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ProgramOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.greenTint : AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.button),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.amberTint,
                  borderRadius: BorderRadius.circular(AppRadius.icon),
                ),
                child: Icon(icon,
                    size: 20,
                    color: selected ? Colors.white : AppColors.textSecondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary)),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected ? AppColors.primary : AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoreHeader extends StatelessWidget {
  final Business business;
  const _StoreHeader({required this.business});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppColors.gradient,
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: business.logoBase64 != null
                ? Image.memory(base64Decode(business.logoBase64!),
                    fit: BoxFit.cover)
                : const Icon(AppIcons.store, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(business.name,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
                if (business.description.isNotEmpty)
                  Text(business.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _BalanceTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.gradient,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.button,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5)),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
        ],
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  final Promotion promo;
  final bool canRedeem;
  final bool pendingThis;
  final int missing;
  final VoidCallback onRedeem;

  const _RewardCard({
    required this.promo,
    required this.canRedeem,
    required this.pendingThis,
    required this.missing,
    required this.onRedeem,
  });

  @override
  Widget build(BuildContext context) {
    return PromotionCard(
      promo: promo,
      footer: SizedBox(
        height: 40,
        child: FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 40),
            padding: EdgeInsets.zero,
            textStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          onPressed: canRedeem ? onRedeem : null,
          child: Text(pendingThis
              ? 'Pedido · espera la entrega'
              : canRedeem
                  ? 'Canjear'
                  : 'Te faltan $missing pts'),
        ),
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  final LoyaltyRequest request;
  const _RequestTile({required this.request});

  @override
  Widget build(BuildContext context) {
    final earned =
        request.status == RequestStatus.approved ? describeEarned(request) : '';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(describeRequest(request),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                Text(
                  [
                    _date(request.createdAt),
                    if (earned.isNotEmpty) earned,
                  ].join(' · '),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          RequestStatusChip(status: request.status),
        ],
      ),
    );
  }

  static String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _Title extends StatelessWidget {
  final String text;
  const _Title(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          letterSpacing: -0.4));
}
