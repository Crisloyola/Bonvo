import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bonvo/config/themes/app_theme.dart';
import 'package:bonvo/features/auth/domain/entities/auth_user.dart';
import 'package:bonvo/features/business/domain/entities/business.dart';
import 'package:bonvo/features/business/domain/repositories/business_repository.dart';
import 'package:bonvo/features/loyalty/data/loyalty_repository.dart';
import 'package:bonvo/features/loyalty/domain/loyalty.dart';
import 'package:bonvo/injection/injection.dart';

/// "Billetera" del cliente: una tarjeta por cada tienda en la que está
/// inscrito, con los saldos de ESA tienda. En celular se desliza de lado;
/// en escritorio se apilan.
class StoreCardsWallet extends StatefulWidget {
  final AuthUser user;
  final bool wide;
  const StoreCardsWallet({super.key, required this.user, required this.wide});

  @override
  State<StoreCardsWallet> createState() => _StoreCardsWalletState();
}

class _StoreCardsWalletState extends State<StoreCardsWallet> {
  List<Business>? _businesses;
  final Map<String, Membership> _members = {};
  final List<StreamSubscription> _subs = [];
  final _pageCtrl = PageController(viewportFraction: 0.9);
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(StoreCardsWallet old) {
    super.didUpdateWidget(old);
    // Se unió (o salió) de una tienda: aparece su tarjeta
    if (old.user.businessIds.join() != widget.user.businessIds.join()) _load();
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    final list = <Business>[];
    for (final id in widget.user.businessIds) {
      final r = await getIt<BusinessRepository>().getBusiness(id);
      r.fold((_) {}, list.add);
    }
    if (!mounted) return;
    setState(() => _businesses = list);
    // Saldos en vivo: al aprobar una compra la tarjeta se actualiza sola
    for (final b in list) {
      _subs.add(getIt<LoyaltyRepository>()
          .watchMembership(b.id, widget.user.uid)
          .listen((m) {
        if (!mounted) return;
        setState(() {
          if (m == null) {
            _members.remove(b.id);
          } else {
            _members[b.id] = m;
          }
        });
      }));
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _businesses;
    if (list == null) return const _CardFrame(child: _Loading());
    if (list.isEmpty) return const _EmptyWallet();

    Widget cardAt(int i) => StoreLoyaltyCard(
          business: list[i],
          member: _members[list[i].id],
          style: i,
        );

    if (widget.wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < list.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            cardAt(i),
          ],
        ],
      );
    }

    if (list.length == 1) return cardAt(0);

    return Column(
      children: [
        SizedBox(
          height: _CardFrame.height,
          child: PageView.builder(
            controller: _pageCtrl,
            padEnds: false,
            itemCount: list.length,
            onPageChanged: (p) => setState(() => _page = p),
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: cardAt(i),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < list.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _page ? 18 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: i == _page ? AppColors.primary : AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Tarjeta de fidelidad de UNA tienda.
class StoreLoyaltyCard extends StatelessWidget {
  final Business business;
  final Membership? member;

  /// Índice para variar el color entre tarjetas.
  final int style;

  const StoreLoyaltyCard({
    super.key,
    required this.business,
    required this.member,
    this.style = 0,
  });

  static const _gradients = [
    AppColors.gradient,
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF2A2A27), Color(0xFF0F0F0E)],
    ),
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF5B21B6), Color(0xFF15131C)],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final p = business.programs;
    final m = member;
    final points = m?.points ?? 0;
    final cashback = m?.cashbackCents ?? 0;
    final stamps = m?.stamps ?? 0;

    // Saldo principal: puntos > cashback > sellos (según lo que tenga activo)
    final (String mainValue, String mainLabel) = p.pointsEnabled
        ? ('$points', 'puntos')
        : p.cashbackEnabled
            ? (formatSoles(cashback), 'de cashback')
            : p.stampsEnabled
                ? ('$stamps/${p.stampsRequired}', 'sellos')
                : ('—', '');

    return _CardFrame(
      gradient: _gradients[style % _gradients.length],
      background: business.bannerBase64,
      onTap: () =>
          context.push('/client/store', extra: {'businessId': business.id}),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tienda
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: business.logoBase64 != null
                    ? Image.memory(base64Decode(business.logoBase64!),
                        fit: BoxFit.cover, gaplessPlayback: true)
                    : const Icon(AppIcons.store, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(business.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15)),
                    Text('Tarjeta de fidelidad',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 11)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.8)),
            ],
          ),
          const Spacer(),
          // Saldo principal
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(mainValue,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.2,
                      height: 1)),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(mainLabel,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Los demás programas
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (p.pointsEnabled && p.cashbackEnabled)
                _Chip(
                    icon: AppIcons.coins,
                    text: '${formatSoles(cashback)} cashback'),
              if (p.stampsEnabled && (p.pointsEnabled || p.cashbackEnabled))
                _StampDots(done: stamps, total: p.stampsRequired),
              if ((m?.stampRewards ?? 0) > 0)
                const _Chip(
                    icon: Icons.card_giftcard_rounded,
                    text: 'Regalo por reclamar'),
              if (m == null)
                const _Chip(icon: Icons.hourglass_empty, text: 'Sin compras aún'),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardFrame extends StatelessWidget {
  static const double height = 196;

  final Widget child;
  final Gradient gradient;
  final String? background;
  final VoidCallback? onTap;

  const _CardFrame({
    required this.child,
    this.gradient = AppColors.gradient,
    this.background,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppRadius.cardLg),
        boxShadow: AppShadows.button,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // El banner de la tienda, tenue, como fondo de la tarjeta
              if (background != null)
                Opacity(
                  opacity: 0.18,
                  child: Image.memory(base64Decode(background!),
                      fit: BoxFit.cover, gaplessPlayback: true),
                ),
              Padding(padding: const EdgeInsets.all(18), child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Chip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 5),
          Text(text,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Mini tarjeta de sellos: un punto por visita.
class _StampDots extends StatelessWidget {
  final int done;
  final int total;
  const _StampDots({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < total.clamp(1, 12); i++)
            Container(
              width: 9,
              height: 9,
              margin: const EdgeInsets.only(right: 3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < done
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.25),
              ),
            ),
          const SizedBox(width: 3),
          Text('$done/$total',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const Center(
      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2));
}

class _EmptyWallet extends StatelessWidget {
  const _EmptyWallet();

  @override
  Widget build(BuildContext context) {
    return _CardFrame(
      onTap: () => context.push('/client/scan-business'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.wallet_rounded, color: Colors.white, size: 30),
          const Spacer(),
          const Text('Aún no tienes tarjetas',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            'Escanea el QR de una tienda y se creará tu tarjeta con sus '
            'puntos, sellos y cashback.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}
