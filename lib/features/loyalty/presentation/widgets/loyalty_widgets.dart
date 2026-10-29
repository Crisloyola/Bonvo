import 'package:flutter/material.dart';
import 'package:bonvo/config/themes/app_theme.dart';
import 'package:bonvo/features/loyalty/domain/loyalty.dart';

/// Lista de los programas que la tienda tiene activos, en lenguaje simple.
class ProgramList extends StatelessWidget {
  final LoyaltyPrograms programs;
  const ProgramList({super.key, required this.programs});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      if (programs.stampsEnabled)
        _ProgramRow(
          icon: Icons.verified_outlined,
          title: 'Tarjeta de sellos',
          subtitle: programs.stampReward.isEmpty
              ? '${programs.stampsRequired} visitas para tu regalo'
              : '${programs.stampsRequired} visitas → ${programs.stampReward}',
        ),
      if (programs.cashbackEnabled)
        _ProgramRow(
          icon: AppIcons.coins,
          title: 'Cashback',
          subtitle:
              'Recibes ${_pct(programs.cashbackPercent)} de cada compra como saldo',
        ),
      if (programs.pointsEnabled)
        _ProgramRow(
          icon: AppIcons.star,
          title: 'Puntos',
          subtitle:
              '${programs.pointsPerSol} pt por cada S/ 1 · canjéalos por regalos',
        ),
    ];
    if (rows.isEmpty) {
      return const Text(
        'Esta tienda aún no configuró su programa.',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
      );
    }
    return Column(children: rows);
  }
}

String _pct(double v) =>
    '${v == v.roundToDouble() ? v.toInt() : v.toStringAsFixed(1)}%';

/// "2%" o "2.5%"
String formatPercent(double v) => _pct(v);

class _ProgramRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _ProgramRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.greenTint,
              borderRadius: BorderRadius.circular(AppRadius.icon),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.textPrimary)),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de sellos: una casilla por visita, la última es el regalo.
class StampCard extends StatelessWidget {
  final int stamps;
  final int required;
  final String reward;
  final int rewardsAvailable;

  const StampCard({
    super.key,
    required this.stamps,
    required this.required,
    required this.reward,
    this.rewardsAvailable = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF15131C), Color(0xFF0B0A10)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.cardLg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_outlined,
                  color: AppColors.lilac, size: 18),
              const SizedBox(width: 8),
              const Text('TARJETA DE SELLOS',
                  style: TextStyle(
                      color: AppColors.lilac,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1)),
              const Spacer(),
              Text('$stamps / $required',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15)),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (var i = 0; i < required; i++)
                _Stamp(
                  filled: i < stamps,
                  isGift: i == required - 1,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            reward.isEmpty
                ? 'Completa la tarjeta y recibe tu regalo'
                : 'Al completarla: $reward',
            style: const TextStyle(color: AppColors.lilacLight, fontSize: 13),
          ),
          if (rewardsAvailable > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.chip),
              ),
              child: Text(
                rewardsAvailable == 1
                    ? '🎁 Tienes 1 regalo por reclamar'
                    : '🎁 Tienes $rewardsAvailable regalos por reclamar',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stamp extends StatelessWidget {
  final bool filled;
  final bool isGift;
  const _Stamp({required this.filled, required this.isGift});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? AppColors.primary : Colors.white.withValues(alpha: 0.06),
        border: Border.all(
          color: filled
              ? AppColors.primaryLight
              : Colors.white.withValues(alpha: 0.18),
          width: 1.5,
        ),
      ),
      child: Icon(
        isGift
            ? Icons.card_giftcard_rounded
            : (filled ? Icons.check_rounded : null),
        color: filled ? Colors.white : AppColors.lilac,
        size: 20,
      ),
    );
  }
}

/// Etiqueta de estado de una solicitud.
class RequestStatusChip extends StatelessWidget {
  final RequestStatus status;
  const RequestStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, fg, bg) = switch (status) {
      RequestStatus.pending => (
          'Pendiente',
          AppColors.textPrimary,
          AppColors.amberTint
        ),
      RequestStatus.approved => (
          'Aprobada',
          AppColors.primary,
          AppColors.greenTint
        ),
      RequestStatus.rejected => (
          'Rechazada',
          AppColors.error,
          const Color(0xFFFDECEC)
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(label,
          style: TextStyle(
              color: fg, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

/// Texto corto de lo que pide la solicitud ("Compra S/ 100.00", "Canje: ...").
String describeRequest(LoyaltyRequest r) => switch (r.type) {
      RequestType.purchase => r.amountCents > 0
          ? 'Compra de ${formatSoles(r.amountCents)}'
          : 'Visita',
      RequestType.reward => 'Canje: ${r.rewardTitle} (${r.rewardPoints} pts)',
      RequestType.stampReward => 'Regalo de sellos: ${r.rewardTitle}',
    };

/// Lo que ganó con una solicitud aprobada ("+100 pts · +S/ 2.00 · +1 sello").
String describeEarned(LoyaltyRequest r) {
  if (r.type != RequestType.purchase) return '';
  return [
    if (r.earnedPoints > 0) '+${r.earnedPoints} pts',
    if (r.earnedCashbackCents > 0)
      '+${formatSoles(r.earnedCashbackCents)} cashback',
    if (r.earnedStamps > 0) '+${r.earnedStamps} sello',
  ].join(' · ');
}
