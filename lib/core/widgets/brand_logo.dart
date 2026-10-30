import 'package:flutter/material.dart';
import 'package:bonvo/config/themes/app_theme.dart';

/// Isotipo de Creatrix: flecha morada (➤). Recreado a partir del logo;
/// reemplazar por el archivo original cuando esté disponible.
class CreatrixMark extends StatelessWidget {
  final double size;
  final Color color;
  const CreatrixMark({
    super.key,
    this.size = 24,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: _ArrowPainter(color),
      );
}

class _ArrowPainter extends CustomPainter {
  final Color color;
  const _ArrowPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 24;
    // Flecha con muesca atrás, en una caja de 24 × 24
    final path = Path()
      ..moveTo(3 * s, 3 * s)
      ..lineTo(22 * s, 12 * s)
      ..lineTo(3 * s, 21 * s)
      ..lineTo(7.5 * s, 12 * s)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_ArrowPainter old) => old.color != color;
}

/// Logo completo: isotipo + "creatrix".
class CreatrixLogo extends StatelessWidget {
  final double height;
  final Color textColor;
  final Color markColor;

  const CreatrixLogo({
    super.key,
    this.height = 28,
    this.textColor = AppColors.textPrimary,
    this.markColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CreatrixMark(size: height, color: markColor),
        SizedBox(width: height * 0.3),
        Text(
          'creatrix',
          style: TextStyle(
            color: textColor,
            fontSize: height * 0.95,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.04 * height,
            height: 1,
          ),
        ),
      ],
    );
  }
}

/// Ícono de app: cuadrado negro redondeado con la flecha morada.
class CreatrixAppIcon extends StatelessWidget {
  final double size;
  const CreatrixAppIcon({super.key, this.size = 62});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.textPrimary,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      alignment: Alignment.center,
      child: CreatrixMark(size: size * 0.55, color: AppColors.primaryLight),
    );
  }
}
