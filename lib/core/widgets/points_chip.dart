import 'package:flutter/material.dart';
import 'package:bonvo/config/themes/app_theme.dart';

class PointsChip extends StatelessWidget {
  final int points;
  final bool isNegative;
  final double fontSize;

  const PointsChip({
    super.key,
    required this.points,
    this.isNegative = false,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    final color = isNegative ? AppColors.amberText : AppColors.primary;
    final bgColor = isNegative ? AppColors.amberTint : AppColors.greenTint;
    final prefix = isNegative ? '−' : '+';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: color, size: fontSize),
          const SizedBox(width: 4),
          Text(
            '$prefix$points pts',
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}
