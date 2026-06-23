import 'package:flutter/material.dart';
import 'package:bonvo/config/themes/app_theme.dart';
import 'package:bonvo/core/widgets/points_chip.dart';

class TransactionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final int points;
  final bool isEarned;
  final String? amountLabel;

  const TransactionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.points,
    required this.isEarned,
    this.amountLabel,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isEarned ? AppColors.primary : AppColors.amberText;
    final iconBg = isEarned ? AppColors.greenTint : AppColors.amberTint;
    final iconData =
        isEarned ? Icons.trending_up_rounded : Icons.card_giftcard_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(AppRadius.icon),
            ),
            child: Icon(iconData, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              PointsChip(points: points, isNegative: !isEarned),
              if (amountLabel != null) ...[
                const SizedBox(height: 3),
                Text(
                  amountLabel!,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
