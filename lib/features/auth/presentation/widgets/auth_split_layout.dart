import 'package:flutter/material.dart';
import 'package:bonvo/config/themes/app_theme.dart';
import 'package:bonvo/core/widgets/brand_logo.dart';

/// Diseño de escritorio para login y registro: marca a la izquierda,
/// formulario centrado a la derecha.
class AuthSplitLayout extends StatelessWidget {
  final Widget child;
  const AuthSplitLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Row(
        children: [
          const Expanded(child: AuthBrandPanel()),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(48),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
/// Panel de marca a la izquierda de login/registro en escritorio.
class AuthBrandPanel extends StatelessWidget {
  const AuthBrandPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      // Fondo oscuro como el Hero de Creatrix, con un brillo morado
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.6, -0.4),
          radius: 1.3,
          colors: [Color(0xFF2E1A5C), Color(0xFF15131C), Color(0xFF0B0A10)],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      padding: const EdgeInsets.all(56),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CreatrixLogo(
            height: 30,
            textColor: Colors.white,
            markColor: AppColors.primaryLight,
          ),
          const Spacer(),
          const Text(
            'Fideliza a tus clientes\ncon puntos y promociones',
            style: TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Cada compra suma. Tus clientes vuelven.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 16,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 40),
          const _Benefit(
              icon: AppIcons.star, text: 'Puntos y cashback en cada compra'),
          const _Benefit(
              icon: AppIcons.gift,
              text: 'Promociones exclusivas de tus tiendas'),
          const _Benefit(
              icon: Icons.qr_code_2, text: 'Tarjeta de fidelidad en un QR'),
          const Spacer(),
          Text(
            '© Creatrix',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Benefit({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
