import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bonvo/config/themes/app_theme.dart';
import 'package:bonvo/core/utils/responsive.dart';
import 'package:bonvo/features/business/presentation/widgets/business_web_shell.dart';
import 'package:bonvo/features/promotions/domain/entities/promotion.dart';
import 'package:bonvo/features/promotions/domain/repositories/promotions_repository.dart';
import 'package:bonvo/injection/injection.dart';

class PromotionsAdminPage extends StatefulWidget {
  final String businessId;
  final String businessName;

  const PromotionsAdminPage({
    super.key,
    required this.businessId,
    required this.businessName,
  });

  @override
  State<PromotionsAdminPage> createState() => _PromotionsAdminPageState();
}

class _PromotionsAdminPageState extends State<PromotionsAdminPage> {
  List<Promotion> _promotions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await getIt<PromotionsRepository>()
        .getBusinessPromotions(widget.businessId);
    result.fold(
      (_) {},
      (list) => setState(() => _promotions = list),
    );
    setState(() => _loading = false);
  }

  Widget _itemFor(Promotion p) {
    return Dismissible(
      key: Key(p.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius:
              BorderRadius.circular(AppRadius.card),
        ),
        child: const Icon(AppIcons.delete,
            color: Colors.white),
      ),
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: const Text('Eliminar promoción'),
          content: Text(
              '¿Eliminar "${p.title}"? No se puede deshacer.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.error),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar'),
            ),
          ],
        ),
      ),
      onDismissed: (_) async {
        final repo = getIt<PromotionsRepository>();
        await repo.togglePromotion(
            widget.businessId, p.id, false);
        await repo.deletePromotion(
            widget.businessId, p.id);
        _load();
      },
      child: _PromoAdminCard(
        promo: p,
        businessId: widget.businessId,
        onToggle: _load,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = context.isWide;
    final page = Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await context.push<bool>(
            '/business/create-promotion',
            extra: {
              'businessId': widget.businessId,
              'businessName': widget.businessName,
            },
          );
          if (created == true) _load();
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(AppIcons.plus, color: Colors.white),
        label: const Text('Nueva',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.primaryDeep,
            title: const Text('Promociones'),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration:
                    const BoxDecoration(gradient: AppColors.gradient),
              ),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_promotions.isEmpty)
            SliverFillRemaining(
              child: Center(
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
                      'Sin promociones aún',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Crea una para que tus clientes\nla vean en la app',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else if (wide)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(32, 28, 32, 100),
              sliver: SliverToBoxAdapter(
                // _PromoAdminCard ya trae su margen inferior
                child: ResponsiveWrapGrid(
                  minItemWidth: 380,
                  runSpacing: 0,
                  children: _promotions.map(_itemFor).toList(),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _itemFor(_promotions[i]),
                  childCount: _promotions.length,
                ),
              ),
            ),
        ],
      ),
    );

    if (!wide) return page;
    return BusinessWebShell(
      current: BusinessSection.promotions,
      businessId: widget.businessId,
      businessName: widget.businessName,
      child: page,
    );
  }
}

class _PromoAdminCard extends StatelessWidget {
  final Promotion promo;
  final String businessId;
  final VoidCallback onToggle;

  const _PromoAdminCard({
    required this.promo,
    required this.businessId,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor =
        promo.isFree ? AppColors.primary : AppColors.amberText;
    final iconBg = promo.isFree ? AppColors.greenTint : AppColors.amberTint;
    final iconData =
        promo.isFree ? AppIcons.gift : AppIcons.star;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: promo.active ? AppColors.surface : const Color(0xFFF3F3EE),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
            color: promo.active ? AppColors.border : const Color(0xFFDCDCD6)),
        boxShadow: promo.active ? AppShadows.card : [],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: promo.active ? iconBg : const Color(0xFFF3F3EE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(iconData,
                  color: promo.active ? iconColor : AppColors.textMuted,
                  size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    promo.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: promo.active
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                    ),
                  ),
                  if (promo.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(promo.description,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    promo.isFree
                        ? 'Promoción gratuita'
                        : 'Canjeable por ${promo.pointsCost} pts',
                    style: TextStyle(
                      color: promo.isFree
                          ? AppColors.primary
                          : AppColors.amberText,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: promo.active,
              activeThumbColor: AppColors.primary,
              onChanged: (v) async {
                await getIt<PromotionsRepository>()
                    .togglePromotion(businessId, promo.id, v);
                onToggle();
              },
            ),
          ],
        ),
      ),
    );
  }
}
