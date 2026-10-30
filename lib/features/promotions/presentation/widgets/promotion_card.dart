import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:bonvo/config/themes/app_theme.dart';
import 'package:bonvo/features/promotions/domain/entities/promotion.dart';

/// Tarjeta única de promoción/premio: imagen, título, descripción y costo
/// en puntos. Se usa en el panel del negocio, en la vista previa al crearla
/// y en todas las pantallas del cliente.
class PromotionCard extends StatelessWidget {
  final Promotion promo;

  /// Muestra el nombre de la tienda (útil cuando se listan varias tiendas).
  final bool showBusiness;

  /// Botón o controles al pie (Canjear, interruptor de activa, etc.).
  final Widget? footer;

  /// Se ve apagada (p. ej. promoción desactivada por el negocio).
  final bool dimmed;

  const PromotionCard({
    super.key,
    required this.promo,
    this.showBusiness = false,
    this.footer,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
        boxShadow: dimmed ? const [] : AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Imagen + costo ──
          AspectRatio(
            aspectRatio: 16 / 10,
            child: Stack(
              fit: StackFit.expand,
              children: [
                promo.imageBase64 != null
                    ? Image.memory(
                        base64Decode(promo.imageBase64!),
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      )
                    : Container(
                        color: AppColors.greenTint,
                        child: const Icon(Icons.card_giftcard_rounded,
                            color: AppColors.primary, size: 44),
                      ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: _CostBadge(points: promo.pointsCost),
                ),
              ],
            ),
          ),

          // ── Texto ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showBusiness && promo.businessName.isNotEmpty) ...[
                  Text(
                    promo.businessName.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  promo.title.isEmpty ? 'Sin título' : promo.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                if (promo.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    promo.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
                if (footer != null) ...[
                  const SizedBox(height: 12),
                  footer!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
    return dimmed ? Opacity(opacity: 0.55, child: card) : card;
  }
}

class _CostBadge extends StatelessWidget {
  final int points;
  const _CostBadge({required this.points});

  @override
  Widget build(BuildContext context) {
    final free = points == 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: free ? AppColors.primary : AppColors.textPrimary,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(free ? Icons.local_offer_rounded : AppIcons.star,
              color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            free ? 'Gratis' : '${_fmt(points)} pts',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(int v) => v >= 1000
      ? '${v ~/ 1000},${(v % 1000).toString().padLeft(3, '0')}'
      : '$v';
}
